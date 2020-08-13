local cjson = require("cjson")
local http_test = require("http_test")
local request = http_test.new({ host = os.getenv("HTTPBIN_SERIVCE_IP") or "httpbin.org", port = "80"})

test("has_response_status()", function()
  assert.has.response_status(request:get("/status/404"), 404)
  assert.has.response_status(request:put("/status/200"), 200)
  assert.has.response_status(request:delete("/status/500"), 500)
  assert.has.response_status(request:post("/status/333"), 333)
end)

test("headers()", function()
  local freeform = request:get("/response-headers?freeform=header_test"):headers()["freeform"]
  assert.equal(freeform,"header_test")
end)

test("to_json()", function()
  assert.same(request:get("/cookies"):to_json(),{cookies = {}})
end)

test("body()", function()
  local body = request:get("/cookies"):body()
  assert.same(cjson.decode(body),{cookies = {}})
end)