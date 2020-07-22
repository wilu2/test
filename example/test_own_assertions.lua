local say = require "say"

local function has_http_status(state, args)

  if type(args[1]) ~= "table" or #args ~= 2 then
    return false
  end
  local res, status = args[1], args[2]
  if res and res.status == status then
    return true
  end
  return false
end

say:set("assertion.has_http_status.positive", "Expected %s \nto have HTTP status: %s")
say:set("assertion.has_http_status.negative", "Expected %s \nto not have property: %s")
assert:register("assertion", "has_http_status", has_http_status, "assertion.has_http_status.positive", "assertion.has_http_status.negative")

describe("Busted unit testing framework", function()
  local http = require "resty.http"
  local httpc = http.new()
  it("should be easy to extend my own assertion", function()
    local res, err = httpc:request_uri("http://www.intsig.com")
    assert.has.http_status(res, 200)

    local res, err = httpc:request_uri("https://www.intsig.com", {ssl_verify = false})
    assert.not_has.http_status(res, 404)
  end)
end)
