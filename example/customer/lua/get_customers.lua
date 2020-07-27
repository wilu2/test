local setmetatable = setmetatable
local cjson = require("cjson")

local db = require("db")

ngx.req.discard_body()

local all = db:all()

setmetatable(all, cjson.empty_array_mt)
ngx.header["Content-Type"] = "application/json"
ngx.print(cjson.encode(all))
