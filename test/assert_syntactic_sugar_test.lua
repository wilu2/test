local http_test = require("http_test")
local request = http_test.new({ host = os.getenv("HTTPBIN_SERIVCE_IP") or "httpbin.org", port = "80"})

test("Is", function()
    assert.response_status(request:get("/status/404"), 404)

    assert.has.response_status(request:get("/status/404"), 404)
    assert.is.response_status(request:get("/status/404"), 404)
    assert.are.response_status(request:get("/status/404"), 404)
    assert.was.response_status(request:get("/status/404"), 404)

    assert.has_response_status(request:get("/status/404"), 404)
    assert.is_response_status(request:get("/status/404"), 404)
    assert.are_response_status(request:get("/status/404"), 404)
    assert.was_response_status(request:get("/status/404"), 404)
end)

test("Not", function()
    assert.is_not.response_status(request:get("/status/404"), 500)
    assert.are_not.response_status(request:get("/status/404"), 500)
    assert.was_not.response_status(request:get("/status/404"), 500)
    assert.has_no.response_status(request:get("/status/404"), 500)
end)
