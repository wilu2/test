
local subrequest = function()
  local res = ngx.location.capture("/subrequest")
  return res
end

return subrequest
