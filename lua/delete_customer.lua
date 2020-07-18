local db = require("db")
ngx.req.discard_body()

local id = ngx.re.match(ngx.var.uri, "[0-9]+")[0]
db:del(id)