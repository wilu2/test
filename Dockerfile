#FROM openresty/openresty:bionic
FROM harbor.intsig.net/base/openresty:1.17.8.2-ubuntu20.04

RUN luarocks install busted && \
    luarocks install lua-resty-http && \
    luarocks install ljsonschema && \
    luarocks install lua-resty-jit-uuid && \
    luarocks --server=http://rocks.moonscript.org install lyaml
ADD busted /usr/local/openresty/luajit/bin/busted
RUN chmod +x /usr/local/openresty/luajit/bin/busted
ADD lib/http_test.lua /usr/local/openresty/lualib/
ADD lib/nginx.lua /usr/local/openresty/lualib/
ENTRYPOINT []
