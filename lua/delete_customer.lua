local db = require("db")
ngx.req.discard_body()

local id = string.match(ngx.var.uri, "(%d+)$")
db:del(id)