FROM harbor.intsig.net/base/openresty:1.15.8.2-ubuntu18.04

RUN luarocks install busted && \
    luarocks install lua-resty-http
ADD busted /usr/local/openresty/luajit/bin/busted
RUN chmod +x /usr/local/openresty/luajit/bin/busted
ENTRYPOINT []

