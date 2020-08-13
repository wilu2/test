require("http_test")

local openapi = [=[
  {
    "openapi": "3.0.3",
    "info": {
      "title": "会员管理系统",
      "version": "0.0.1"
    },
    "paths": {
      "/customers": {
        "get": {
          "responses": {
            "200": {
              "description": "OK",
              "content": {
                "text/plain": {
                  "schema": {
                    "type": "integer",
                    "enum": [
                      1
                    ]
                  }
                },
                "application/json": {
                  "schema": {
                    "type": "integer",
                    "enum": [
                      2
                    ]
                  }
                }
              }
            },
            "400": {
              "description": "OK",
              "content": {
                "text/plain": {
                  "schema": {
                    "type": "integer",
                    "enum": [
                      3
                    ]
                  }
                }
              }
            }
          }
        },
        "put": {
          "responses": {
            "200": {
              "description": "OK",
              "content": {
                "text/plain": {
                  "schema": {
                    "type": "integer",
                    "enum": [
                      4
                    ]
                  }
                }
              }
            }
          }
        }
      },
      "/customers/{id}": {
        "get": {
          "parameters": [
            {
              "in": "path",
              "name": "id",
              "required": true,
              "schema": {
                "type": "integer"
              }
            }
          ],
          "responses": {
            "200": {
              "description": "OK",
              "content": {
                "text/plain": {
                  "schema": {
                    "type": "integer",
                    "enum": [
                      5
                    ]
                  }
                }
              }
            }
          }
        }
      },
      "/customers/{id}/purchase/{type}": {
        "get": {
          "parameters": [
            {
              "in": "path",
              "name": "id",
              "required": true,
              "schema": {
                "type": "integer"
              }
            },
            {
              "in": "path",
              "name": "type",
              "required": true,
              "schema": {
                "type": "string"
              }
            }
          ],
          "responses": {
            "200": {
              "description": "OK",
              "content": {
                "text/plain": {
                  "schema": {
                    "type": "integer",
                    "enum": [
                      6
                    ]
                  }
                }
              }
            }
          }
        }
      }
    }
  }
]=]

-- mock response
local function res(url, method, status, content, body)
  return {
    url = url,
    method = method,
    res = { 
      status = status, 
      body = body,
      headers = {
        ["Content-Type"] = content,
      }
    }
  }
end

-- GET /customers 200 text/plain 1
-- GET /customers 200 application/json 2
-- GET /customers 400 text/plain 3
-- PUT /customers 200 text/plain 4

-- GET /customers/123 200 text/plain 5

-- GET /customers/123/purchase/eat 200 text/plain 6
-- GET /customers/123/purchase/123 200 text/plain 6
-- GET /customers/123/purchase/3.14eat 200 text/plain 6

-- GET /customers/bad 200 text/plain falied

test("t1", function()
  assert.is.validated_against_openapi(res("/customers", "GET", 200, "text/plain", "1"), openapi)
end)

test("t2", function()
  assert.is.validated_against_openapi(res("/customers", "GET", 200, "application/json", "2"), openapi)
end)

test("t3", function()
  assert.is.validated_against_openapi(res("/customers", "GET", 400, "text/plain", "3"), openapi)
end)

test("t4", function()
  assert.is.validated_against_openapi(res("/customers", "PUT", 200, "text/plain", "4"), openapi)
end)

test("t5", function()
  assert.is.validated_against_openapi(res("/customers/123", "GET", 200, "text/plain", "5"), openapi)
end)

test("t6", function()
  assert.is.validated_against_openapi(res("/customers/123/purchase/eat", "GET", 200, "text/plain", "6"), openapi)
  assert.is.validated_against_openapi(res("/customers/123/purchase/123", "GET", 200, "text/plain", "6"), openapi)
  assert.is.validated_against_openapi(res("/customers/123/purchase/3.14eat", "GET", 200, "text/plain", "6"), openapi)
end)

test("no schema matched", function()
  assert.is_not.validated_against_openapi(res("/customers/eat", "GET", 200, "text/plain", "5"), openapi)
end)