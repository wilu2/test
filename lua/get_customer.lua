local db = require("db")
ngx.req.discard_body()

local id = string.match(ngx.var.uri, "(%d+)$")
local info = db:get(id)

if info == nil then
    ngx.status = 404
else
    ngx.header["Content-Type"] = "application/json"
    ngx.print(info)
end