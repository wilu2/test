local cjson = require("cjson.safe")
local httptest = require("resty.http_test")

local ht = httptest.new({ unit_name = "customer", host = "127.0.0.1", port = 8080})

local info1 = {
  name = "winn",
  phone = "17566668888"
}

local info2 = {
  name = "winn",
  phone = "17588886666"
}

local generated_id

function ht:init() 
  --self:init_schema_from_openapi_file("./openapi.json")
   self:init_schema_from_openapi_url("/openapi.json")
end

function ht:test_001_customers_list()
  self:get("/customers")
  self:response_have_status(200)
  self:response_validate_schema("getAllCustomer")
end

function ht:test_002_add_customer_post_invalid_body()
  self:post("/customers")
  self:response_have_status(406)
end

function ht:test_003_add_customer()
  self:post("/customers",{body = cjson.encode(info1)})
  self:response_have_status(200)
  self:response_validate_schema("addCustomer")
  local json = self:response_to_json()
  generated_id = json.id
end

function ht:test_004_get_customer()
  self:get("/customers/" .. generated_id)
  self:response_have_status(200)
  self:response_validate_schema("getCustomer")
  local json = self:response_to_json()
  self:assert_eq(info1.name, json.name)
  self:assert_eq(info1.phone, json.phone)
end

function ht:test_005_update_non_existend_customer()
  self:put("/customers/" .. generated_id + 1, {body = cjson.encode(info2)})
  self:response_have_status(404)
end

function ht:test_006_update_customer_post_invalied_bod()
  self:put("/customers/" .. generated_id)
  self:response_have_status(406)
end

function ht:test_007_update_customer()
  self:put("/customers/" .. generated_id, {body = cjson.encode(info2)})
  self:response_have_status(200)
  self:get("/customers/" .. generated_id)
  self:response_have_status(200)
  self:response_validate_schema("getCustomer")
  local json = self:response_to_json()
  self:assert_eq(info2.name, json.name)
  self:assert_eq(info2.phone, json.phone)
end

function ht:test_008_delete_customer()
  self:delete("/customers/" .. generated_id)
  self:response_have_status(200)
  self:get("/customers/" .. generated_id)
  self:response_have_status(404)
end

-- function ht:test_009_failed_test_example()
--   self:post("/customers",{body = cjson.encode(info1)})
--   self:response_have_status(200)
--   self:response_validate_schema("addCustomer")

--   -- failed test
--   self:response_validate_schema("getAllCustomer")
-- end

ht:run()
