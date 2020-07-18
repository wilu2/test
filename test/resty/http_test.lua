local setmetatable = setmetatable
local ngx = ngx
local table = table
local str_fmt = string.format
local unpack = unpack
local type = type
local pairs = pairs
local pcall = pcall

local jsonschema = require("jsonschema.jsonschema")
local cjson = require("cjson.safe")
local http = require("resty.http")

local _M = {
    _VERSION = '0.02',
}
_M._INNER = {}

local mt = { __index = _M }

function _M.new(opts)
    opts = opts or {}
    local unit_name = opts.unit_name
    local write_log = (nil == opts.write_log) and true or opts.write_log
    local header = opts.header
    local host = opts.host
    local port = opts.port or 80
    return setmetatable({ 
        header = header ,
        host = host,
        port = port,
        start_time = ngx.now(), 
        unit_name = unit_name,
        write_log = write_log, 
        _test_inits = opts.test_inits,  
        processing = nil, 
        count = 0,
        count_fail = 0, 
        count_succ = 0,                 
        mock_func = {} 
    }, mt)
end

local function generate_validator_from_openapi_json(self, openapi)
    local validators = {}
    for api, methods in pairs(openapi.paths) do
        for method, define in pairs(methods) do
            for code, response in pairs(define.responses) do
                if response.content and response.content["application/json"] ~= nil then
                    local schema = {components = openapi.components}
                    for k, v in pairs(response.content["application/json"].schema) do
                        schema[k] = v
                    end
                    local validator = jsonschema.generate_validator(schema)
                    local id = table.concat({define.operationId, "__", code})
                    validators[id] = validator
                    local msg = table.concat({"add validator for response ", id})
                    self:log_finish_succ(msg)
                end
            end
        end
    end
    return validators
end

function _M.init_schema_from_openapi_url(self, url)
    local request_url
    if string.sub(url, 1, 1) == "/" then
        request_url = table.concat({"http://", self.host, ":", self.port,  url})
    else
        request_url = url
    end
    local httpc = http.new()

    local json_body
    local res, err = httpc:request_uri(request_url)
    if err then
        local msg = table.concat({"init_schema_from_openapi_url> ", "get ", request_url, " failed: ", err});
        self:exit(msg)
    else
        json_body, err = cjson.decode(res.body)
        if not json_body then
            local msg = table.concat({"init_schema_from_openapi_url> not a json response: ", res.body})
            self:exit(msg)
        end
    end
    self._INNER.validators =  generate_validator_from_openapi_json(self, json_body)
end

function _M.init_schema_from_openapi_file(self, file_path)
    local f = io.open(file_path, "rb")
    local openapi_str = f:read("*all")
    f:close()

    if openapi_str == nil then 
        local msg = table.concat({"init_schema_from_openapi_file> load ", file_path, " failed"})
        self:exit(msg)
    end

    local json_body, err = cjson.decode(openapi_str)
    if not json_body then
        local msg = table.concat({"init_schema_from_openapi_file> not a json file: ", res.body})
        self:exit(msg)
    end

    self._INNER.validators =  generate_validator_from_openapi_json(self, json_body)

end

function _M._log(self, color, ...)
    local logs = { ... }
    local color_d = { black = 30, green = 32, red = 31, yellow = 33, blue = 34, purple = 35,
                      dark_green = 36, white = 37 }

    if color_d[color] then
        local function format_color(cur_color)
            return "\x1b[" .. cur_color .. "m"
        end
        ngx.print(format_color(color_d[color])
                .. table.concat(logs, " ") .. '\x1b[m')
    else
        ngx.print(...)
    end

    ngx.flush()
end

function _M._log_standard_head(self)
    if not self.write_log then
        return
    end

    local fun_format
    if nil == self.processing then
        fun_format = str_fmt("[%s] ", self.unit_name)
    else
        fun_format = str_fmt("  \\_[%s] ", self.processing)
    end

    self:_log("default", str_fmt("%0.3f", ngx.now() - self.start_time),
            " ")
    self:_log("green", fun_format)
end

function _M.log(self, ...)
    if not self.write_log then
        return
    end

    local log = { ... }
    table.insert(log, "\n")

    self:_log_standard_head()
    if self.processing then
        table.insert(log, 1, "↓")
    end
    self:_log("default", unpack(log))
end

function _M.log_finish_fail(self, ...)
    if not self.write_log then
        return
    end

    local log = { ... }
    table.insert(log, "\n")

    self:_log_standard_head(self)
    self:_log("red", "fail", unpack(log))
end

function _M.exit(self, msg)
    self:log_finish_fail(msg)
    ngx.exit(1)
end

function _M.log_finish_succ(self, ...)
    if not self.write_log then
        return
    end

    local log = { ... }
    table.insert(log, "\n")
    self:_log_standard_head(self)
    self:_log("green", unpack(log))

end

function _M._init_test_units(self)
    if self._test_inits then
        return self._test_inits
    end

    local test_inits = {}
    for k, v in pairs(self) do
        if k:lower():sub(1, 4) == "test" and type(v) == "function" then
            table.insert(test_inits, k)
        end
    end

    table.sort(test_inits)
    self._test_inits = test_inits
    return self._test_inits
end

function _M.run(self, loop_count)
    if self.unit_name then
        self:log_finish_succ("unit test start")
    end

    self:_init_test_units()

    loop_count = loop_count or 1

    self.time_start = ngx.now()

    for _ = 1, loop_count do
        if self.init then
            self:init()
        end

        for _, k in pairs(self._test_inits) do
            self.processing = k
            local _, err = pcall(self[k], self)
            if err then
                self:log_finish_fail(err)
                self.count_fail = self.count_fail + 1
            else
                self:log_finish_succ("PASS")
                self.count_succ = self.count_succ + 1
            end
            self.processing = nil
            ngx.flush()
        end

        if self.destroy then
            self:destroy()
        end
    end

    self.time_ended = ngx.now()

    if self.unit_name then
        self:log_finish_succ("unit test complete")
    end
end

function _M.mock_run(self, mock_rules, test_run, ...)

    local idx_tbl = 1
    local idx_name = 2
    local idx_new_func = 3
    local idx_org_func = 4

    --mock
    for _, rule in ipairs(mock_rules) do
        local fun_name = rule[idx_name]
        local org_fun = rule[idx_tbl][fun_name]
        local new_fun = rule[idx_new_func]

        rule[idx_org_func] = org_fun   -- store the org function
        rule[idx_tbl][fun_name] = new_fun

        -- store the orgnize function
        self.mock_func[new_fun] = org_fun
    end

    --exec test
    local ok, res, err = pcall(test_run, ...)

    --resume
    for _, rule in ipairs(mock_rules) do
        local fun_name = rule[idx_name]
        local org_fun = rule[idx_org_func]

        rule[idx_tbl][fun_name] = org_fun     -- restore the org function
    end

    if not ok then
        -- pcall fail, the error msg stored in "res"
        error(res)
    end

    return res, err
end

-- assert function added by yangguang_wen@intsig.net
function _M.assert_true(self, condition)
    if not condition then
       self:exit("assert_true> failed")
    else
        self:log_finish_succ("assert_true> PASS")
    end
end

function _M.assert_false(self, condition)
    if condition then
        self:exit("assert_false> failed")
     else
         self:log_finish_succ("assert_false> PASS")
     end
end

function _M.assert_eq(self, val1, val2)

    self:_log(val1)
    if type(val1) ~= type(val2) then
        local msg = table.concat({"assert_eq> expect type ",  type(val1), ", but got type ", type(val2)})
        self:exit(msg)
    end

    if val1 ~= val2 then
        local msg = table.concat({"assert_eq> expect ", val1, ", but got ", val2})
        self:exit(msg)
    end
    local msg = table.concat({"assert_eq> expect ", val1, ", got ", val2, ", PASS"})
    self:log_finish_succ(msg)
end

function _M.assert_ne(self, val1, val2)

    if val1 == val2 then
        local msg = table.concat({"assert_ne> not expect ", val1, ", but got ", val2, ", falied"})
        self:exit(msg);
    else 
        local msg = table.concat({"assert_ne> ", val1, " is not equal to ", val2, ", PASS"})
        self:log_finish_succ(msg)
    end
end
-- assert function end

local function request(self, url, opts, method)
    opts = opts or {}
    local request_url = table.concat({"http://", self.host, ":", self.port,  url})
    local httpc = http.new()
    local res, err = httpc:request_uri(request_url,{
        method = method,
        headers = opts.headers,
        body = opts.body
    })
    if err then 
        local msg = table.concat({method, " ", request_url, " failed: ", err});
        self:exit(msg);
    else
        local msg = table.concat({method, " ", request_url, " OK"});
        self:log_finish_succ(msg)
        self._INNER.res = res;
    end
end

function _M.get(self, url, opts)
    request(self, url, opts, "GET")
end

function _M.post(self, url, opts)
    request(self, url, opts, "POST")
end

function _M.put(self, url, opts)
    request(self, url, opts, "PUT")
end

function _M.delete(self, url, opts)
    request(self, url, opts, "DELETE")
end

function _M.response_have_status(self, status_code)
    if self._INNER.res == nil then 
        self:exit("response_have_status> no response")
    end

    if self._INNER.res.status ~= status_code then
        local msg = table.concat( {"response_have_status> expect ", status_code, " but got ", self._INNER.res.status })
        self:exit(msg);
    else
        local msg = table.concat( {"response_have_status> expect ", status_code, " got ", self._INNER.res.status , ", PASS"})
        self:log_finish_succ(msg)
    end
end

function _M.response_validate_schema(self, operationId, status_code)
    if self._INNER.res == nil then 
        self:exit("response_validate_schema> no response")
    end

    if self._INNER.res.body == nil then 
        self:exit("response_validate_schema> no response body")
    end

    local json_body, err = cjson.decode(self._INNER.res.body)
    if not json_body then
        local msg = table.concat({"response_validate_schema> not a json response: ", self._INNER.res.body})
        self:exit(msg)
    end

    status_code = status_code or self._INNER.res.status
    local check = self._INNER.validators[table.concat({operationId, "__", status_code})]
    if check == nil then
        local msg = table.concat({"response_validate_schema> no schema for ",operationId, " ", status_code})
        self:exit(msg);
    end

    local valid, err = check(json_body)
    if valid == false then
        local msg = table.concat({"response_validate_schema> schema check for ", operationId, " ", status_code, " failed: ",err})
        self:exit(msg);
    else 
        local msg = table.concat({"response_validate_schema> schema check for ", operationId, " ", status_code, ", PASS"})
        self:log_finish_succ(msg)
    end
end

function _M.response_to_json(self)
    if self._INNER.res == nil then 
        self:exit("response_to_json> no response")
    end

    if self._INNER.res.body == nil then 
        self:exit("response_to_json> no response body")
    end

    local json_body, err = cjson.decode(self._INNER.res.body)
    if not json_body then
        local msg = table.concat({"response_to_json> not a json response: ", self._INNER.res.body})
        self:exit(msg)
    end

    return json_body
end

return _M