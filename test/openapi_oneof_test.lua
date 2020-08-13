require("http_test")

local openapi = [=[
openapi: 3.0.3
info:
  title: oneof
  version: 0.0.1
  
paths:
  /oneof_test:
    get:
      summary:  oneOf test
      responses:
        '200':
          description: OK
          content:
            text/plain:
              schema:
                oneOf:
                  - $ref: '#/components/schemas/rectangle'
                  - $ref: '#/components/schemas/sector'
components:
  schemas:
    rectangle:
      type: array
      items:
        type: object
        properties:
          property:
            type: string
            enum: 
              - width
              - height
          value:
            type: integer
    sector:
      type: array
      items:
        type: object
        properties:
          property:
            type: string
            enum:
              - radius
              - angle
          value:
            type: integer
]=]

local rectangle = [=[
[
    { "property": "width", "value": 100 },
    { "property": "height", "value": 80 }
]
]=]

local sector = [=[
[
    { "property": "radius", "value": 100 },
    { "property": "angle", "value": 80 }
]
]=]

local invalid_shape = [=[
[
    { "property": "width", "value": 100 },
    { "property": "angle", "value": 80 }
]
]=]

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

test("oneof_test", function()
  assert.is.validated_against_openapi(res("/oneof_test", "GET", 200, "text/plain", rectangle), openapi)
  assert.is.validated_against_openapi(res("/oneof_test", "GET", 200, "text/plain", sector), openapi)
  assert.is_not.validated_against_openapi(res("/oneof_test", "GET", 200, "text/plain", invalid_shape), openapi)
end)