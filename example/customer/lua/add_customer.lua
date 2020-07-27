local cjson = require("cjson.safe")
local db = require("db")

ngx.req.read_body()
local info = ngx.req.get_body_data()

-- TODO: check info
local json, err = cjson.decode(info)
if not json then
    ngx.status = 406
    return
end

local id = db:add({name = json.name, phone = json.phone})

ngx.header["Content-Type"] = "application/json"
ngx.print(cjson.encode({id = id}))