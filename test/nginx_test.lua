local nginx = require("nginx")
local http_test = require("http_test")

describe("nginx", function()
  it("starts a stopable nginx instance", function()
    local n, err = nginx.new()
    finally(function() n:stop() end)
    local req = http_test.new({host = "127.0.0.1", port = 80})
    assert.has.response_status(req:get("/"), 404)
  end)

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

  it("starts a stopable nginx instance with http config", function()
    local n, err = nginx.new({
      main_config = [[
        env PATH;
      ]], 
      http_config = [[
        client_max_body_size 8;
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

  it("deal with error log", function()
    local n, err = nginx.new([[
      location /say {
        content_by_lua_block {
          ngx.log(ngx.ERR, "oops")
          ngx.print("hello world")
        }
      }

      location /speak {
        content_by_lua_block {
          ngx.log(ngx.ERR, "ouch!")
        }
      }
    ]])
    finally(function() n:stop() end)
    local req = http_test.new({host = "127.0.0.1", port = 80})
    local resp = req:get("/say")
    assert.has.response_status(resp, 200)
    assert.is_same("hello world", resp:body())
    assert.is_truthy(string.find(n:error_log(), "oops"))

    local resp = req:get("/speak")
    assert.has.response_status(resp, 200)
    assert.is_truthy(string.find(n:error_log(), "ouch!"))
  end)
end)