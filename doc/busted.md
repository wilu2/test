# busted 相关测试

可以使用 [busted](http://olivinelabs.com/busted/) 强大功能和优美的接口，同时使用nginx lua的大部分接口。可以参考example中的例子。

### 基础用法

```lua
describe("Busted unit testing framework", function()
  describe("should be awesome", function()
    -- busted 用法
    it("should be easy to use", function()
      assert.truthy("Yup.")
    end)

    it("should have lots of features", function()
      -- deep check comparisons!
      assert.are.same({ table = "great"}, { table = "great" })

      -- or check by reference!
      assert.are_not.equal({ table = "great"}, { table = "great"})

      assert.truthy("this is a string") -- truthy: not false or nil

      assert.True(1 == 1)
      assert.is_true(1 == 1)

      assert.falsy(nil)
      assert.has_error(function() error("Wat") end, "Wat")
    end)

    it("should provide some shortcuts to common functions", function()
      assert.are.unique({{ thing = 1 }, { thing = 2 }, { thing = 3 }})
    end)
    -- nginx lua api 接口
    it("should work with nginx lua apis", function()
      assert.equal(0, ngx.OK)
      assert.equal(200, ngx.HTTP_OK)
    end)
  end)
end)

```

### 发送http请求

```lua
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
```

### 自定义断言

具体参考[busted文档](http://olivinelabs.com/busted/#asserts)

```lua
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
```

### 截获`ngx.location.capture`

可以方便mock下游http响应。

同时这也是一个做函数单元测试的例子。

```lua
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
```