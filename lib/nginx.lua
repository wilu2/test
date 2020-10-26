local uuid = require 'resty.jit-uuid'
local shell = require "resty.shell"

uuid.seed()

local _M = {}

local stop = function(self)
  local ok, stdout, stderr, reason, status = shell.run("nginx -s stop -p " .. self.prefix)
  if not ok then
    return false, stderr
  end
  ok, stdout, stderr, reason, status = shell.run("rm -rf " .. self.prefix)
  if not ok then
    return false, stderr
  end
  return true
end

local error_log = function(self)
  local path = self.prefix .. "/logs/error.log"
  local f = io.open(path, "rb")
  local ret = f:read("*all")
  f:close()
  return ret
end

local access_log = function(self)
  local path = self.prefix .. "/logs/access.log"
  local f = io.open(path, "rb")
  local ret = f:read("*all")
  f:close()
  return ret
end

_M.new = function(options)
  local prefix = "/tmp/nginx/" .. uuid()
  ngx.log(ngx.DEBUG, "prefix: ", prefix)
  local ok, stdout, stderr, reason, status = shell.run("mkdir -p " .. prefix)
  if not ok then
    return nil, stderr
  end
  ok, stdout, stderr, reason, status = shell.run("mkdir -p " .. prefix .. "/conf")
  if not ok then
    return nil, stderr
  end
  local config_path = prefix .. "/conf/nginx.conf"
  ok, stdout, stderr, reason, status = shell.run("mkdir -p " .. prefix .. "/logs")
  if not ok then
    return nil, stderr
  end

  local config_template = [[
# main config
%s

events {
  worker_connections  1024;
}

http {

  # http config
  %s

  server {
    # server config
    %s
  }
}
  ]]

  if type(options) == "nil" then
    options = {}
  elseif type(options) == "string" then
    options = {
      server_config = options
    }
  end

  local config = string.format(
    config_template, 
    options.main_config or "", 
    options.http_config or "", 
    options.server_config or ""
  )

  local f = io.open(config_path, "wb")
  ngx.log(ngx.DEBUG, "nginx.conf: \n", config)
  f:write(config)
  f:close()

  ok, stdout, stderr, reason, status = shell.run("nginx -t -p " .. prefix)
  if not ok then
    return nil, stderr
  end

  ok, stdout, stderr, reason, status = shell.run("nginx -p " .. prefix, nil, 1000)
  if not ok and reason ~= "failed to read stdout: timeout" then
    return nil, stderr
  end

  return {
    prefix = prefix, 
    stop = stop, 
    error_log = error_log, 
    access_log = access_log, 
  }

end

return _M