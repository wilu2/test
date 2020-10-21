local mockserver = require("mockserver")
print("ip1 = ",os.getenv("MOCKSERVER_IP"))
print("ip2 = ",os.getenv("MOCKSERVER_IP2"))
local http_test = require("http_test")
local request1 = http_test.new({host = os.getenv("MOCKSERVER_IP"),port = 1080})
local request2 = http_test.new({host = os.getenv("MOCKSERVER_IP2"),port = 1081})

local mock1 = mockserver.new({host = os.getenv("MOCKSERVER_IP"),port = 1080})
local mock2 = mockserver.new({host = os.getenv("MOCKSERVER_IP2"),port = 1081})

test("create expectation in mock1", function()
  local resp_st = "Response body (string)\n"
  local req_st = "/some/path"
  local resp, id = mock1:create(req_st,resp_st)
  assert.has_response(resp)
  assert.has_response_status(resp, 201)
  assert(id == 1)
end)

test("check expectation in mock1", function()
  local response = request1:post("/some/path")
  assert.has_response(response)
  assert.has_response_status(response, 200) 
end)

test("check expectation in mock2 (there should be no expectation)", function()
  local response = request2:post("/some/path")
  assert.has_response(response)
  assert.has_response_status(response, 404) 
end)

test("create expectation in mock2", function()
  local resp_st = "Response body (string)\n"
  local req_st = "/some/path"
  local resp, id = mock2:create(req_st,resp_st)
  assert.has_response(resp)
  assert.has_response_status(resp, 201)
  -- the id in mockserver2 should be 1, since id in each mockserver is separately counted
  assert(id == 1)
end)

test("check expectation in mock2 (there should be expectation)", function()
  local response = request2:post("/some/path")
  assert.has_response(response)
  assert.has_response_status(response, 200) 
end)

test("reset all expectation in mock1", function()
  local response = mock1:reset()
  assert.has_response(response)
  assert.has_response_status(response, 200) 
end)

test("check expectation in mock2 (there should be expectation)", function()
  local response = request2:post("/some/path")
  assert.has_response(response)
  assert.has_response_status(response, 200) 
end)

test("create expectation in mock1 for clear test", function()
  local resp_st = "Temporary response body (string)\n"
  local req_st = "/some/path/tmp"
  local resp, id = mock1:create(req_st,resp_st)
  assert.has_response(resp)
  assert.has_response_status(resp, 201)
  assert(id == 1)
end)

test("clear expectation in mock1",function()
  -- first check whether the path works
  local resp1 = request1:get("/some/path/tmp",{header = {accept = "application/json"}})
  assert.has_response(resp1)
  assert.has_response_status(resp1, 200) 
  -- then clear the path by id
  local resp2 = mock1:clear({id = 1})
  assert.has_response(resp2)
  assert.has_response_status(resp2, 200) 
  -- then check whether the path works now
  local resp3 = request1:get("/some/path/tmp",{header = {accept = "application/json"}})
  assert.has_response(resp3)
  assert.has_response_status(resp3, 404) 
end)

mock1:reset()
mock2:reset()
