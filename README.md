# http_test

基于[busted](http://olivinelabs.com/busted/) 和 [resty-cli](https://github.com/openresty/resty-cli) 的 Lua 测试框架

## 安装

建议使用 docker 安装测试环境

```bash
sudo docker build -t http_test .
sudo cp http_test.sh /usr/local/bin/http_test
sudo chmod +x /usr/local/bin/http_test
```

进行测试

```bash
http_test -p test_ -m "example/?.lua" example
```

### customer_test

代码中附带了一个简单的 [会员管理系统](https://gitlab.intsig.net/tianxuan/mainstone/http_test/-/blob/add_http_assert/example/customer/doc/openapi.json) 以及对应的 [接口测试](https://gitlab.intsig.net/tianxuan/mainstone/http_test/-/blob/add_http_assert/example/customer_test.lua) . 你可以对应这接口文档来阅读测试代码,以便快速理解该测试框架

1. 启动 会员管理系统

   ```bash
   docker run -d --workdir=$(pwd) \
     -p 8080:8080 \
     -v $(pwd):$(pwd) \
     openresty/openresty:bionic \
     openresty -p $(pwd)/example/customer -c conf/nginx.conf -g "daemon off;"
   ```

   > 关闭服务: docker stop $(docker container ls| grep 8080 | awk '{print $1}')

2. 运行接口测试

   ```bash
   http_test example/customer_test.lua
   ```

## 使用

1. [busted 相关测试](https://gitlab.intsig.net/tianxuan/mainstone/http_test/-/wikis/busted-相关测试)
2. [http_test API](https://gitlab.intsig.net/tianxuan/mainstone/http_test/-/wikis/http_test-API)

### Gitlab CI集成

参考 `.gitlab-ci.yaml`