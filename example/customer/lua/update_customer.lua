local cjson = require("cjson.safe")
local db = require("db")

ngx.req.read_body()
local info = ngx.req.get_body_data()
local id = ngx.re.match(ngx.var.uri, "[0-9]+")[0]

local origin_info = db:get(id)
if origin_info == nil then
    ngx.status = 404
    return
end

-- TODO: check info
local json, err = cjson.decode(info)
if not json then
    ngx.status = 406
    return
end


db:update(id, {name = json.name, phone = json.phone})