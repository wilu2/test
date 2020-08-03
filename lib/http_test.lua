local setmetatable = setmetatable
local table = table
local type = type
local pairs = pairs
local say = require "say"
local assert = require("luassert")

local jsonschema = require("jsonschema")
local cjson = require("cjson.safe")
local http = require("resty.http")
local lyaml = require("lyaml")

local _M = {
    _VERSION = '0.02',
}

local __response_meta = {
    to_json = function(self)
        if self.res == nil then 
            return nil, "no response"
        end
    
        if self.res.body == nil then 
            return nil, "no response body"
        end
    
        local json_body, err = cjson.decode(self.res.body)
    
        if not json_body then
            return nil, "not json response"
        end
    
        return json_body
    end,
}

local mt = { __index = _M }

function _M.new(opts)
    opts = opts or {}
    local host = opts.host
    local port = opts.port or 80
    return setmetatable({ host = host, port = port}, mt)
end

-- reqeust function
local function request(self, url, opts, method)
    opts = opts or {}
    local request_url = table.concat({"http://", self.host, ":", self.port,  url})
    local httpc = http.new()
    local res, err = httpc:request_uri(request_url,{
        method = method,
        headers = opts.headers,
        body = opts.body
    })

    return setmetatable({
        res = res, 
        err = err,
        method = method, 
        url = url,   
    }, { __index = __response_meta })

end

function _M.get(self, url, opts)
    return request(self, url, opts, "GET")
end

function _M.post(self, url, opts)
    return request(self, url, opts, "POST")
end

function _M.put(self, url, opts)
    return request(self, url, opts, "PUT")
end

function _M.delete(self, url, opts)
    return request(self, url, opts, "DELETE")
end

-- assert function
local function register_assertion(name, func)
    local positive = table.concat({"assertion", name, "positive"}, ".")
    local negative = table.concat({"assertion", name, "negative"}, ".")
    assert:register("assertion", name, func, positive, negative)
end

local function has_response(state, argv)
    local response = argv[1]
    if response.err then
        state.failure_message = table.concat({
            "\nExpect response is OK",
            "\nBut got error: ", response.err
        })
        return false
    end

    return true
end

local function has_response_status(state, argv)
    if not has_response(state, argv) then
        return false
    end

    local response = argv[1]
    local status_code = argv[2]
    if response.res.status ~= status_code then
        state.failure_message = table.concat({
            "\nExpect status: ", status_code,
            "\nBut got: ", response.res.status
        })
        return false
    end
   
    return true
end

local function is_validated_against_schema(state, argv)
    if not has_response(state, argv) then
        return false
    end

    local response = argv[1]
    local schema = argv[2]

    -- The schema can be a table or a string in json format,
    local validator = jsonschema.generate_validator(schema)
    if not validator then
        state.failure_message = "\nInvalid json schema"
        return false
    end

    local data, err = cjson.decode(response.res.body)
    if err then
        state.failure_message = table.concat({"\nInvalid json: ", err})
        return false
    end

    local valid, err = validator(data)
    if not valid then
        state.failure_message = table.concat({
            "\nJson validation failed: ",err})
        return false
    end
    return true
end

local function generate_validator_from_openapi(openapi, request_url, request_method, response_code, response_content_type)

    request_method = string.lower(request_method)

    if not (openapi and request_url and request_method and response_code and response_content_type) then 
        return nil
    end

    if type(openapi) == 'string' then
        -- it can parse json or yaml. (json is a subset of yaml)
        openapi = lyaml.load(openapi)
    end 

    if type(openapi) ~= 'table' then
        return nil
    end
    
    local validator

    local matched_path = ""

    for path, methods in pairs(openapi.paths) do
        local pattern = path
        for method, define in pairs(methods) do
            if (method == request_method) then
                local m_iter, err = ngx.re.gmatch(path, "{(.*?)}")
                -- {id} -> [0-9]+
                -- {name} -> [a-zA-Z]+
                while true do
                    local m, err = m_iter()
                    if not m then
                        break
                    end

                    local param_type
                    if define.parameters then
                        for _, param in pairs(define.parameters) do
                            if param["in"] == "path" and param["name"] == m[1] then
                                if param.schema then
                                    param_type = param.schema.type
                                end
                            end
                        end
                    end

                    local param_type_pattern
                    if param_type == "integer" or param_type == "number" then
                        param_type_pattern = "[0-9]+"
                    elseif param_type == "string" then
                        param_type_pattern = "[^/]+"
                    end
                    
                    if param_type_pattern then
                        pattern = ngx.re.sub(pattern, m[0], param_type_pattern)
                    end
                end -- end of while
                pattern =  table.concat({"^", pattern, "$"})
                if ngx.re.match(request_url, pattern) ~= nil then
                    for code, response in pairs(define.responses) do
                        if tonumber(code) == response_code then 
                            if response.content and response.content[response_content_type] then
                                local schema = {components = openapi.components}
                                for k, v in pairs(response.content[response_content_type].schema) do
                                    schema[k] = v
                                end
                                matched_path = path
                                -- print(request_url, " matched ", path)
                                validator = jsonschema.generate_validator(schema)
                            end
                        end
                    end
                end

            end  -- end of method == request_method
        end -- end of pairs(methods)
    end -- end of pairs(openapi.paths)

    return validator
end

local function is_validated_against_openapi(state, argv)
    if not has_response(state, argv) then
        return false
    end

    local r = argv[1]
    local openapi = argv[2]

    local content_type = r.res.headers["Content-Type"]
    if content_type == nil then
        state.failure_message = "\nNo Content-Type header in response"
        return false
    end
    
    local validator = generate_validator_from_openapi(openapi, r.url, r.method, r.res.status, content_type)

    if validator == nil then
        state.failure_message = table.concat({
            "\nNo schema for", 
            r.method, r.url, r.res.status, content_type
        }, " ")
        return false
    end

    local data, err = cjson.decode(r.res.body)
    if err then
        state.failure_message = table.concat({"\nInvalid json: ", err})
        return false
    end

    local valid, err = validator(data)
    if not valid then
        state.failure_message = table.concat({
            "\nJson validation failed: ",err})
        return false
    end

    return true
end

register_assertion("has_response", has_response)
register_assertion("has_response_status", has_response_status)
register_assertion("is_validated_against_schema", is_validated_against_schema)
register_assertion("is_validated_against_openapi", is_validated_against_openapi)

return _M
