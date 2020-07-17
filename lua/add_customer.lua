local cjson = require("cjson")
local db = require("db")

ngx.req.read_body()
local info = ngx.req.get_body_data()

-- TODO: check info

local id = db:add(info)

ngx.header["Content-Type"] = "application/json"
ngx.say(cjson.encode({id = id}))