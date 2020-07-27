local say = require "say"

local request_handler = require "location_capture"

describe("Busted unit testing framework", function()
  local origin_ngx_location

  setup(function()
    local origin_ngx_location = ngx.location
    ngx.location.capture = function(uri, options)
      return {status = 999, header = {["Content-Length"] = 4}, body = "fake"}
    end
  end)

  teardown(function()
    ngx.location = origin_ngx_location
  end)

  it("should be easy to extend my own assertion", function()
    local res = request_handler()
    assert.equal(res.status, 999)
  end)
end)
