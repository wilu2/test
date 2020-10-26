# nginx

启动一个临时的nginx实例

[TOC]

## Synopsis

```lua
local nginx = require("nginx")

local n, err = nginx.new([[
  location /say {
    content_by_lua_block {
      ngx.print("hello world")
    }
  }
]])
finally(function() n:stop() end)
local req = http_test.new({host = "127.0.0.1", port = 80})
local resp = req:get("/say")
assert.has.response_status(resp, 200)
assert.is_same("hello world", resp:body())
```

## Functions

### new

**syntax**: `instance, err = nginx.new(options)`

新建一个nginx临时实例，默认监听`80`端口。

`options`可以是字符串。当`options`是字符串时，该内容放于nginx配置文件`server`块内，例如：

```lua
  it("starts a stopable nginx instance with server config", function()
    local n, err = nginx.new([[
      location /say {
        content_by_lua_block {
          ngx.print("hello world")
        }
      }
    ]])
    finally(function() n:stop() end)
    local req = http_test.new({host = "127.0.0.1", port = 80})
    local resp = req:get("/say")
    assert.has.response_status(resp, 200)
    assert.is_same("hello world", resp:body())
  end)
```

`options`可以是`table`，里面是3个可选的参数：

- `main_config`
- `http_config`
- `server_config`

例如：

```lua
  it("starts a stopable nginx instance with http config", function()
    local n, err = nginx.new({
      main_config = [[
        env PATH; -- enable environment PATH
      ]], 
      http_config = [[
        client_max_body_size 8; -- limit request body size to 8 bytes
      ]], 
      server_config = [[
        listen 81;
        location /say {
          content_by_lua_block {
            ngx.print(os.getenv("PATH"))
          }
        }
      ]]
    })
    finally(function() n:stop() end)
        
    local req = http_test.new({host = "127.0.0.1", port = 81})
        
    local resp = req:get("/say", {body = "hello"})
    assert.has.response_status(resp, 200)
    assert.is_same(os.getenv("PATH"), resp:body())

    local resp = req:get("/say", {body = "0123456789abcdef"})
    assert.has.response_status(resp, 413)
  end)
```

### stop

**syntax**: `ok, err = nginx:stop()`

关闭一个nginx实例。不关的话会一直占用端口。

```lua
local n = nginx.new([[
    location /say {
      content_by_lua_block {
        ngx.print("hello world")
      }
    }
  ]])
n:stop()  -- release 80 port
```

`stop`会关闭和回收与该nginx实例相关的一切资源，因此nginx实例关闭之后，`access_log`和`error_log`都不可访问。

### access_log

**syntax**: `str = nginx:access_log()`

返回`access.log`的内容。

### error_log

**syntax**: `str = nginx:error_log()`

返回`error.log`的内容。

```lua
  it("deal with error log", function()
    local n, err = nginx.new([[
      location /say {
        content_by_lua_block {
          ngx.log(ngx.ERR, "oops")
        }
      }
    ]])
    finally(function() n:stop() end)
        
    local req = http_test.new({host = "127.0.0.1", port = 80})
        
    local resp = req:get("/say")
    assert.has.response_status(resp, 200)
    assert.is_truthy(string.find(n:error_log(), "oops"))
  end)
```

