# http_test

基于 [resty-cli](https://github.com/openresty/resty-cli) 的 http 测试框架

## 快速开始

1. 启动http服务

   ```shell
   git clone http://gitlab.intsig.net/wenyanguang/http_test.git
   cd http_test/
   openresty -c conf/nginx.conf -p `pwd`
   ```

2. 你可以访问 http://127.0.0.1:8080/ 来查看接口信息

3. http接口测试

   ```shell
   cd test/
   resty customers_test.lua
   ```

   你可以试着修改 `customers_test.lua` 测试脚本, 然后再次运行测试

## resty.http_test

目前提供有以下接口, 文档待补充, 使用示例见  `customers_test.lua`

- put, get, post, delete

- response_have_status  

- response_validate_schema
- response_to_json
- assert_eq, assert_ne, assert_true, assert_false

