local mockserver = require("mockserver")
print("ip = ",os.getenv("MOCKSERVER_IP"))
local http_test = require("http_test")
local request = http_test.new({host = os.getenv("MOCKSERVER_IP"),port = 1080})
local mock1 = mockserver.new({host = os.getenv("MOCKSERVER_IP"),port = 1080})

-- local mock = http_test.new({host = "127.0.0.1", port = 1080})

test("use string as response and request", function()
  local resp_st = "Response body (string)\n"
  local req_st = "/some/path"
  local resp, id = mock1:create(req_st,resp_st)
  assert.has_response(resp)
  assert.has_response_status(resp, 201)
  assert(id == 1)
end)

test("whether the mock server with string resp and req works well", function()
  local resp = request:post("/some/path")
  assert.has_response(resp)
  assert.has_response_status(resp, 200) 
end)

test("reset all expectation", function()
  local resp = mock1:reset()
  assert.has_response(resp)
  assert.has_response_status(resp,200)
end)

test("use table as response", function()
  local resp_tab = {
      template = [=[return {
        statusCode: 205, 
        body: JSON.stringify({ 
          msg: "Response body (table)\n"
        })
      }]=],
      templateType = "JAVASCRIPT"
    }
  local req_st= "/some/path"
  local resp, id = mock1:create(req_st,resp_tab)
  assert.has_response(resp)
  assert.has_response_status(resp, 201)
  -- the mock on path '/some/path' is reset before, hence the id = 1 (otherwise, id = 2)
  assert(id == 1)
end)

test("whether the mock server with table resp works well", function()
  local resp = request:get("/some/path",{header = {accept = "application/json"}})
  assert.has_response(resp)
  assert.has_response_status(resp, 205) 
end)

test("whether we can clear one expectation by id",function()
  -- first check whether the path works
  local resp1 = request:get("/some/path",{header = {accept = "application/json"}})
  assert.has_response(resp1)
  assert.has_response_status(resp1, 205) 
  -- then clear the path by id
  local resp2 = mock1:clear({id = 1})
  assert.has_response(resp2)
  assert.has_response_status(resp2, 200) 
  -- then check whether the path works now
  local resp3 = request:get("/some/path",{header = {accept = "application/json"}})
  assert.has_response(resp3)
  assert.has_response_status(resp3, 404) 
end)

test("whether we can clear one expectation by request table",function()
  -- first create a temporary mock 
  local resp_st = "Temporary response body (table)\n"
  local req_tab = {path = "/some/path/tmp"}
  local resp, id = mock1:create(req_tab,resp_st)
  assert.has_response(resp)
  assert.has_response_status(resp, 201)
  -- check whether it works
  local resp1 = request:get("/some/path/tmp",{header = {accept = "application/json"}})
  assert.has_response(resp1)
  assert.has_response_status(resp1,200)
  -- delete it by request table
  local resp2 = mock1:clear({request = req_tab})
  assert.has_response(resp2)
  assert.has_response_status(resp2,200)
  -- check whether it has been deleted successfully
  local resp3 = request:get("/some/path/tmp",{header = {accept = "application/json"}})
  assert.has_response(resp3)
  assert.has_response_status(resp3,404)
    
end)

test("set a simple expectation prepared for verify", function()
  local resp_st = "Request body (string)\n"
  local req_st = "/some/pathv"
  local resp, id = mock1:create(req_st,resp_st)
  assert.has_response(resp)
  assert.has_response_status(resp, 201)
  assert(id == 1)
end)

test("verify mode", function ()
  local req_st = "/some/pathv"
  local opt1 = {times = {atLeast = 2}}
  local resp1 = mock1:verify(req_st,opt1)
  assert.has_response(resp1)
  assert.has_response_status(resp1,406)
  local resp2 = request:post("/some/pathv")
  assert.has_response(resp2)
  assert.has_response_status(resp2,200)
  local resp3 = mock1:verify(req_st,opt1)
  assert.has_response(resp3)
  assert.has_response_status(resp3,406)
  local resp4 = request:post("/some/pathv")
  assert.has_response(resp4)
  assert.has_response_status(resp4,200)
  local resp5 = mock1:verify(req_st,opt1)
  assert.has_response(resp5)
  assert.has_response_status(resp5,202)
end)

test("reset all expectation", function()
  local resp = mock1:reset()
  assert.has_response(resp)
  assert.has_response_status(resp,200)
end)

