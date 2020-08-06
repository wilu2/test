require("http_test")

local openapi = [=[
paths:
  /ref_test:
    get:
      summary: ref_test
      responses:
        '404':
          $ref: '#/components/responses/NotFound'
        '406':
          $ref: '#/components/responses/Unauthorized'
components:
  responses:
    NotFound:
      description: The specified resource was not found
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/Unauthorized'
    Unauthorized:
      description: Unauthorized
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/NotFound'
  schemas:
    # Schema for error response body
    Unauthorized:
      type: integer
      enmu: [404]
    NotFound:
      type: integer
      enmu: [406]
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

test("resuing_responses_ref_test", function()
  assert.is_validated_against_openapi(res("/ref_test", "GET", 404, "application/json", "404"), openapi)
  assert.is_validated_against_openapi(res("/ref_test", "GET", 406, "application/json", "406"), openapi)
end)
