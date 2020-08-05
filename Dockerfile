#FROM openresty/openresty:bionic
FROM harbor.intsig.net/base/openresty:1.15.8.2-ubuntu18.04

RUN luarocks install busted && \
    luarocks install lua-resty-http && \
    luarocks install ljsonschema && \
    luarocks --server=http://rocks.moonscript.org install lyaml
ADD busted /usr/local/openresty/luajit/bin/busted
RUN chmod +x /usr/local/openresty/luajit/bin/busted
ADD lib/http_test.lua /usr/local/openresty/lualib/
ENTRYPOINT []
