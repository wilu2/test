#!/bin/bash
docker run -ti --net=host \
  --entrypoint=/usr/local/openresty/luajit/bin/busted \
  -v $(pwd):$(pwd) \
  --workdir=$(pwd) \
  http_test $*