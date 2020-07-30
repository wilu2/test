local http_test = require("http_test")
local cjson = require("cjson.safe")
local request = http_test.new({ host = "127.0.0.1", port = 8080 })
local openapi =  request:get("/openapi.json"):to_json()

local customer_info1 = { name="winn", phone="17566668888" }
local customer_info2 = { name="winn", phone="17588886666" }
local customer_id 

test("The status is 406 when post body is invalid #add", function()
  local response =  request:post("/customers")
  assert.has_response(response)
  assert.has_response_status(response, 406)
end)

test("Add customer", function()
  local response = request:post("/customers", {body = cjson.encode(customer_info1)})
  assert.has_response_status(response, 200)
  assert.is_validated_against_openapi(response, openapi)
  -- assert.is_validated_against_schema(response, json_schema)
  customer_id = response:to_json().id
end)

test("Get customer by id", function()
  local response = request:get("/customers/" ..  customer_id)
  assert.has_response_status(response, 200)
  assert.is_validated_against_openapi(response, openapi)
  assert.same(response:to_json(), customer_info1)
end)

test("The status is 404 when get non-existend customer", function()
  local response = request:get("/customers/" ..  customer_id + 1)
  assert.has_response_status(response, 404)
end)

test("Get all customer", function()
  local response = request:get("/customers")
  assert.has_response_status(response, 200)
  assert.is_validated_against_openapi(response, openapi)
end)

test("Update customer", function()
  local response = request:put("/customers/" .. customer_id, {body = cjson.encode(customer_info2)})
  assert.has_response_status(response, 200)

  -- Confirm that the update was successful
  local response = request:get("/customers/" ..  customer_id)
  assert.has_response_status(response, 200)
  assert.same(response:to_json(), customer_info2)
end)

test("The status is 406 when post body is invalid #update", function()
  local response = request:put("/customers/" .. customer_id)
  assert.has_response(response)
  assert.has_response_status(response, 406)
end)

test("The status is 404 when update non-existend customer", function()
  local response = request:put("/customers/" .. customer_id + 100, {body = cjson.encode(customer_info2)})
  assert.has_response(response)
  assert.has_response_status(response, 404)
end)

test("Delete customer", function()
  local response = request:delete("/customers/" .. customer_id)
  assert.has_response_status(response, 200)
  -- Confirm that the delete was successful
  local response = request:get("/customers/" .. customer_id)
  assert.has_response_status(response, 404)
end)