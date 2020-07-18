local core = require "resty.core"
local cjson = require("cjson")

local _M = {
    _VERSION = '0.01'
}

local customers = ngx.shared.customers

local mt = { __index = _M }

function _M.all(self)
    local count = customers:incr("count",0)
    local result = {}
    for i=1, count or 1, 1 do
        local info = customers:get(tostring(i))
        if info ~= nil then
            local json = cjson.decode(info)
            table.insert(result, 
               {
                   id = i,
                   name = json.name,
                   phone = json.phone
               }
            )
        end
    end

    return result;
end

function _M.add(self, info)
    info = info or {}
    local id = customers:incr("count",1)
    if id == nil then
        customers:set("count",1)
        id = 1
    end
    customers:set(tostring(id), cjson.encode({name = info.name, phone = info.phone}))
    return id
end

function _M.get(self, id)
    local info = customers:get(tostring(id))
    if info == nil then
        return nil
    else
        return cjson.decode(info)
    end
end

function _M.update(self, id, info)
    local origin_info = customers:get(tostring(id))
    if origin_info == nil then
        return nil
    else 
        info = info or {}
        customers:set(tostring(id), cjson.encode({name = info.name, phone = info.phone}))
        return true
    end
   
end

function _M.del(self, id)
    local id = tostring(id)
    customers:delete(tostring(id))
end

return _M