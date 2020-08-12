local cjson = require("cjson")
local http_test = require("http_test")
local request = http_test.new({ scheme = "https", host = "httpbin.org", port = "443"})

test("has_response_status()", function()
  assert.has_response_status(request:put("/status/200"), 200)
  assert.has_response_status(request:put("/status/500"), 500)
end)