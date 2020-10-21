local assert = require("luassert")
local setmetatable = setmetatable

local cjson = require("cjson.safe")
local http = require("resty.http")

local mockserver = {}

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

    body = function(self)
        if self.res then 
            return self.res.body
        else
            return nil
        end
    end,

    headers = function(self)
        if self.res then 
            return self.res.headers
        else
            return nil
        end
    end,
}

-- reqeust function
local function request(self, url, opts, method)
    opts = opts or {}
    local request_url = table.concat({self.scheme, "://", self.host, ":", self.port,  url})
    local httpc = http.new()
    local res, err = httpc:request_uri(request_url,{
        method = method,
        headers = opts.headers,
        body = opts.body,
        query = opts.query,
        ssl_verify = false
    })

    return setmetatable({
        res = res, 
        err = err,
        method = method, 
        url = url,   
    }, { __index = __response_meta })

end

local function put(self, url, opts)
    return request(self, url, opts, "PUT")
end

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

register_assertion("response", has_response)
register_assertion("response_status", has_response_status)


function mockserver.new(opts)
    opts = opts or {}
    local scheme = opts.scheme or "http"
    local host = opts.host
    local port = opts.port or (scheme == "https" and 443 or 80)
    
    mockserver.serverNum = (mockserver.serverNum or 0) + 1
    mockserver.requestNum = mockserver.requestNum or {}
    mockserver.requestNum[mockserver.serverNum] = 0
    mockserver.requestsLibrary = mockserver.requestsLibrary or {}
    mockserver.requestsLibrary[mockserver.serverNum] = {} 

    return setmetatable({scheme = scheme, host = host, port = port, id = mockserver.serverNum}, {__index = mockserver})
end

function mockserver.create(self, request, response, opts)
    local bodies = {}
    mockserver.requestNum[self.id] = mockserver.requestNum[self.id] + 1
    -- append request to bodies
    if (type(request) == "string")
    then
        request = {path = request}
    end
    bodies["httpRequest"] = request
    -- record request 
    mockserver.requestsLibrary[self.id][mockserver.requestNum[self.id]]=request
    -- append response to bodies
    if (type(response) == "string")
    then
        response = {body = response}
        bodies["httpResponse"] = response
    else
        bodies["httpResponseTemplate"] = response
    end

    opts = opts or {}
    if (opts.times) then bodies["times"] = opts.times end
    if (opts.timeToLive) then bodies["timeToLive"] = opts.timeToLive end
    if (opts.priority) then bodies["priority"] = opts.priority end

    local resp = put(self,"/mockserver/expectation",{
        body = cjson.encode({bodies})
    })
    return resp, mockserver.requestNum[self.id]
end

function mockserver.reset(self)
    mockserver.requestsLibrary[self.id] = {}
    mockserver.requestNum[self.id] = 0
    return put(self,"/reset", {header = {accept =  "*/*"} })
end

function mockserver.clear(self,opts)
    local request = opts.request
    local id = opts.id
    -- print("request = ", request, ", id = ", id)
    if (request == nil)
    then
        local resp = put(self,"/clear",mockserver.requestsLibrary[self.id][id])
        table.remove((mockserver.requestsLibrary[self.id][id]))
        mockserver.requestNum[self.id] = mockserver.requestNum[self.id] - 1
        return resp
    end
    local resp = put(self,"/clear",request)
    -- search the request matcher in requestsLibrary and remove it
    local tmp = 0
    for key,value in pairs(mockserver.requestsLibrary[self.id]) do
        if (value == request)
        then
            tmp = key
            break
        end
    end
    if (tmp ~= 0)
    then
        table.remove((mockserver.requestsLibrary[self.id][tmp]))
        mockserver.requestNum[self.id] = mockserver.requestNum[self.id] - 1
    end
    return resp
end

function mockserver.verify(self,request,opts)
    if (type(request) == "string")
        then
            local resp = put(self,"/mockserver/verify",{
                body = cjson.encode({
                httpRequest = {path = request},
                times = opts["times"]
                })
            })
            return resp
        else
            local resp = put(self,"/mockserver/verify",{
                body = cjson.encode({
                httpRequest = request,
                times = opts["times"]
                })
            })
            return resp
        end
end

return mockserver 

