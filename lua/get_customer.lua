local db = require("db")
ngx.req.discard_body()

local id = ngx.re.match(ngx.var.uri, "[0-9]+")[0]
local info = db:get(id)

if info == nil then
    ngx.status = 404
else
    ngx.header["Content-Type"] = "application/json"
    ngx.print(info)
end