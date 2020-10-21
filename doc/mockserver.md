# Mock server Lua SDK

------

主要功能：将mockserver的核心功能进行了Lua封装，便于mock的直接使用

## Table of contents

- [Synopsis](#Synopsis)
- [Environment](#Environment)
- [Mockserver Lua SDK](#Mockserver Lua SDK)
  - [new](#new)
  - [create](#create)
  - [clear](#clear)
  - [reset](#reset)
  - [verify](#verify)
- [Sample](#Sample)

## Synopsis

```lua
local mockserver = require("mockserver")

local mock1 = mockserver.new("127.0.0.1",1080)

mock1:create("/some/path","Hello World!",nil)
```

[Back to TOC](#Table of contents)

---



## Environment

在本地运行测试时，需要至少一个docker容器运行mockserver：

```shell
docker run -d --rm -p 1080:1080 mockserver/mockserver
```

这里默认将mockserver设为localhost的1080接口，如果需要同时开启多台mockserver，则需同时开启多个container：

```shell
docker run -d --rm -p 1081:1080 mockserver/mockserver
```

在CI/CD运行测试时，需要在`.gitlab-ci.yml` 中添加如下字段，在`mock_test`这一`job`中单独测试，以下为单一mockserver的情况：

```yaml
mock_test:
  stage: test
  services:
    - name: mockserver/mockserver
      alias: mockserver
  script:
    - export MOCKSERVER_IP=$(cat /etc/hosts | awk '{if ($2 == "mockserver") print $1;}')
    - busted -m example/?.lua example/mock_test*.lua
```

以下为多个mockserver并行的情况：

```yaml
mock_test_multi:
  stage: test
  services:
    - name: mockserver/mockserver
      alias: mockserver
      command: ["-logLevel", "INFO", "-serverPort","1080"]
    - name: mockserver/mockserver
      alias: mockserver2
      command: ["-logLevel", "INFO", "-serverPort","1081"]
            
  script:
    - export MOCKSERVER_IP=$(cat /etc/hosts | awk '{if ($2 == "mockserver") print $1;}')
    - export MOCKSERVER_IP2=$(cat /etc/hosts | awk '{if ($2 == "mockserver2") print $1;}')    
    - busted -m example/?.lua example/mock_test*.lua
```

[Back to TOC](#Table of contents)

---



## Mockserver Lua SDK

---

### new

**syntax:** *mock = mockserver.new(host,port)*

建立一个mockserver专用接口，默认为 `host` = "127.0.0.1"; `port` = 1080

需要在最外层进行local申明，方便后续调用，存储了该mockserver所有相关的信息

```lua
mockserver.new(host,port)
```

在CI/CD测试中可以通过传递环境变量来确认`host`：

```lua
mockserver.new(os.getenv("MOCKSERVER_IP"),1080);
```

如果需要多个mockserver同时运行，需要另外声明`mockserver1`, `mockserver2`... 同时需要增开对应的docker mockserver container：

```lua
-- cmd
docker run -d --rm -p 1080:1080 mockserver/mockserver
docker run -d --rm -p 1081:1080 mockserver/mockserver

-- mock_test.lua
mockserver = require("mockserver")

local mock1 = mockserver.new(“127.0.0.1”，1080)
local mock2 = mockserver.new(“127.0.0.1”，1081)
```

[Back to TOC](#Table of contents)

---

### create

**syntax:** *resp, id = mockserver:create(request,response,option)*

用于新建expectation

`request`和`response`支持string格式，`request`的string格式对应path，`response`的string格式对应response的body

```lua
mock1:create("/some/path","Hello World!",nil)
```

`request`和`response`也支持table格式：

```lua
local resp_tab = {
      template = [=[return {
        statusCode: 200, 
        body: JSON.stringify({ 
          msg: "okk"
        })
      };]=],
      templateType = "JAVASCRIPT"
    };
local req_tab = {
      method = "GET",
      path = "some/patth",
      headers = {
          Accept = "application/json"
      }
  };
local mock1:create(req_tab,resp_tab,nil);
```

`option` 默认为`nil`，支持以下三种参数：

- `times`

- `timeToLive`

- `priority`

需要各自传入table类型进行设置

```lua
local opt1 = {times = {remainingTimes = 2, unlimited = false}};

local opt2 = {
        times = {remainingTimes = 2, unlimited = false},
        timeToLive = {timeUnit = "SECONDS", timeToLive = 5, unlimited = false}        
    };

local opt = {
        times = {remainingTimes = 1, unlimited = false},
        priority = 100
    };

mock1:create("/some/path","Hello World!",opt1)
mock1:create("/some/paths","Hello World again!",opt2)
mock1:create("/some/path","Hello World!!!",opt3)
```

返回值为`resp`与`id`， 对应了response与该expectation在当前mockserver下对应的id；response的正常返回status应该为`201`；id用于后期删除时使用

```lua
local resp,id = mock1:create("/some/path","Hello World!",nil)
assert.has_response(resp)
assert.has_response_status(resp, 201)
-- if this expectation is the first one you create
assert(id == 1)
```

[Back to TOC](#Table of contents)

---

### clear

**syntax:** *resp = mockserver:clear({request,id})*

用于删除单个expectation，支持根据request匹配删除，以及根据expectation id匹配删除两种方式；若同时传入两个参数，则默认选择通过request匹配

其中request同样支持string与table两种类型

返回值为对应response，正常返回status为`201`

```lua
mock1:clear({request = "/some/path"})

mock1:clear({id = 3})
```

[Back to TOC](#Table of contents)

---

### reset

**syntax:** *mockserver:reset()*

用于删除所有的expectation

```lua
mock1:reset()
```

[Back to TOC](#Table of contents)

---

### verify

**syntax:** *resp = mockserver:verify(request,option)*

用于verify测试，目前`option`仅支持`times`，即访问次数判断

`request`支持string与table类型，返回值`resp`在accept时返回status`203`，在reject时返回`406`

```lua
local req_st = "/some/pathv";
local opt1 = {times = {atLeast = 2}}
local resp = mock1:verify(req_st,opt1);
```

[Back to TOC](#Table of contents)

---

## Sample

详见 example/test_mock.lua 与example/test_mock_opt.lua

[Back to TOC](#Table of contents)
