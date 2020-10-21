local mockserver = require("mockserver")
print("ip = ",os.getenv("MOCKSERVER_IP"))
local http_test = require("http_test")

local request = http_test.new({host = os.getenv("MOCKSERVER_IP"),port = 1080})
local mock1 = mockserver.new({host = os.getenv("MOCKSERVER_IP"),port = 1080})

-- local mock = http_test.new({host = "127.0.0.1", port = 1080})

test("create expectation with opt time", function()
  local resp_st = "Respose body (string)\n"
  local req_st = "/some/path"
  local opt = {times = {remainingTimes = 2, unlimited = false}}
  local resp, id = mock1:create(req_st,resp_st,opt)
  assert.has_response(resp)
  assert.has_response_status(resp, 201)
  assert(id == 1)
end)

test("expetation with opt time = 2", function()
  local resp = request:post("/some/path")
  assert.has_response(resp)
  assert.has_response_status(resp, 200) 
  resp = request:post("/some/path")
  assert.has_response(resp)
  assert.has_response_status(resp, 200) 
  -- first two visits should be valid, and the next one should be banned
  resp = request:post("/some/path")
  assert.has_response(resp)
  assert.has_response_status(resp, 404) 
end)

test("create expectation with opt timeToLive", function()
  local resp_st = "Response body (string)\n"
  local req_st = "/some/paths"
  local opt = {
      times = {remainingTimes = 2, unlimited = false},
      timeToLive = {timeUnit = "SECONDS", timeToLive = 5, unlimited = false}        
  }
  local resp, id = mock1:create(req_st,resp_st,opt)
  assert.has_response(resp)
  assert.has_response_status(resp, 201)
  assert(id == 2)
end)

test("expetation with opt timeToLive = 5s", function()
  -- first check whether the visit is valid before the time limit
  local resp = request:post("/some/paths")
  assert.has_response(resp)
  assert.has_response_status(resp, 200)
  -- sleep 5s to wait for the mock to be invalid
  os.execute("sleep " .. 5)
  resp = request:post("/some/paths")
  assert.has_response(resp)
  assert.has_response_status(resp, 404) 
end)


test("create expectation with low priority", function()
  local resp_tab = {
      template = [=[return {
        statusCode: 200, 
        body: "low priority"
      }]=],
      templateType = "JAVASCRIPT"
    }
  local req_st = "/some/pathp"
  local opt = {
      times = {unlimited = true},
      priority = 10
  }
  local resp, id = mock1:create(req_st,resp_tab,opt)
  assert.has_response(resp)
  assert.has_response_status(resp, 201)
  assert(id == 3)
end)

test("create expectation with high priority", function()
  local resp_tab = {
      template = [=[return {
        statusCode: 205, 
        body: "high priority"
      }]=],
      templateType = "JAVASCRIPT"
    }
  -- the request path is the same as the last one above (with low priority)
  local req_st = "/some/pathp"
  local opt = {
      times = {remainingTimes = 1, unlimited = false},
      priority = 100
  }
  local resp, id = mock1:create(req_st,resp_tab,opt)
  assert.has_response(resp)
  assert.has_response_status(resp, 201)
  assert(id == 4)
end)

test("expetation with priority", function()
  local resp = request:post("/some/pathp")
  assert.has_response(resp)
  assert.has_response_status(resp, 205)
  resp = request:post("/some/pathp")
  assert.has_response(resp)
  assert.has_response_status(resp, 200) 
  resp = request:post("/some/pathp")
  assert.has_response(resp)
  assert.has_response_status(resp, 200) 
end)

mock1:reset()
