# http_test API

### new

`syntax: reqeust = http_test.new(params)`

创建一个 http_test 句柄 

`params` 是一个lua table, 接收一下字段

- `host` 默认请求地址
- `port` 默认请求端口

### get, post, put, delete

`syntax: response = request:get(url, params?)`

发送http请求, `params` 是一个 table, 接收以下字段

- `quary` 查询字符串, 可以是文本或者lua表
- `headers` 请求头表
- `body` 请求体字符串

### to_json()

`syntax: json, err = response:to_json()`

### has_response_status

`syntax: assert.has_response_status(response, code)`

判断 http 响应吗时候等于 code

### is_validated_against_schema

`syntax: assert.is_validated_against_schema(response, json_schema)`

校验 http 相应的 schema, `json_schema` 可以是 lua table 或者是 json 字符串