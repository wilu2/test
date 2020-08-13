# http_test API

## http_test

- **new()**

  `syntax: reqeust = http_test.new(params)`

  创建一个 http_test 句柄 

  `params` 是一个lua table, 接收一下字段

  - `scheme` 请求协议，http 或者 https， 默认为http
  - `host` 请求域名
  - `port` 请求端口

## request

- **get(), post(), put(), delete()**

  `syntax: response = request:get(url, params?)`

  发送http请求, `params` 是一个 table, 接收以下字段

  - `quary` 查询字符串, 可以是文本或者lua表
  - `headers` 请求头表
  - `body` 请求体字符串

## response

- **to_json()**

  `syntax: json, err = response:to_json()`

- **body()**

  `syntax: body = response:body()`

- **headers()**

  `syntax: headers = response:headers()`

  返回http响应头，headers是个lua table。用  `headers["header_name"]`  获取某个header的值

## assert

assert断言，下面的每个函数都需要传入`response` 作为第一个参数

- **response_status()**

  `syntax: assert.response_status(response, code)`

  判断 http 响应码是否等于 code

- **validated_against_schema()**

  `syntax: assert.validated_against_schema(response, json_schema)`

  校验 http 相应的 schema, `json_schema` 可以是 lua table 或者是 json 字符串

- **validated_against_openapi()**

  `syntax: assert.validated_against_openapi(response, openapi)`

  根据 openapi 校验响应格式是否正确。 openapi 可以是 lua table、json字符串、yaml字符串

  关于openapi：

  1. 目前根据实际的请求方法，url路径，响应码，响应 `Conent-Type` 头这几个字段 去openapi中寻找对应的schema，如果openapi中没有对应的schema，断言会失败。
  2. 目前只支持文档内的本地 `$ref ` 引用

### 注意

http_test 相关断言函数 用的是  [luassert library](http://olivinelabs.com/busted/#asserts) 它支持一些语法糖。比如一个断言函数声明为 `xxx()`  那么同时也支持一下函数,

Is函数 它们与 `xxx()` 是等价的

```lua
assert.xxx()
assert.is.xxx()
assert.are.xxx()
assert.has.xxx()
assert.was.xxx()
-- 也可以用 "_" 符号链接
assert.is_xxx()
assert.are_xxx()
assert.has_xxx()
assert.was_xxx()
```

Not 函数，与 is函数相反，是断言不成立的语法糖

```lua
assert.is_not.xxx()
assert.are_not.xxx()
assert.was_not.xxx()
assert.has_no.xxx()
-- 由于 "not" 是 lua 的关键字，所以不支持 "is.not" 类似的语法
```

写测试的时候，可以用适当的语法糖增加测试的可读性，比如：

```lua
assert.has.response_status()
assert.has_no.response_status()

assert.is.validated_against_openapi()
assert.is_not.validated_against_openapi()
```

