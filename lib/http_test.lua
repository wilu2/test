local setmetatable = setmetatable
local table = table
local type = type
local pairs = pairs
local say = require "say"
local assert = require("luassert")

local jsonschema = require("jsonschema")
local cjson = require("cjson.safe")
local http = require("resty.http")

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

    return setmetatable({res = res, err = err}, { __index = __response_meta })

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

register_assertion("has_response", has_response)
register_assertion("has_response_status", has_response_status)
register_assertion("is_validated_against_schema", is_validated_against_schema)

return _M