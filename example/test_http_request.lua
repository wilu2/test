describe("Busted unit testing framework", function()
  local http = require "resty.http"
  local httpc = http.new()
  it("should be easy to make http request", function()
    local res, err = httpc:request_uri("http://www.intsig.com")
    assert.truthy(res)
    assert.equal(res.status, 200)

    local res, err = httpc:request_uri("https://www.intsig.com", {ssl_verify = false})
    assert.truthy(res)
    assert.equal(res.status, 200)
  end)
end)
