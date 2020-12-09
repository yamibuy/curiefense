FROM envoyproxy/envoy:v1.16.2

RUN apt-get update && \
    apt-get -yq --no-install-recommends install jq luarocks libpcre2-dev libgeoip-dev python gcc make unzip && \
	rm -rf /var/lib/apt/lists/*

RUN luarocks install lrexlib-pcre2 && \
    luarocks install lua-cjson && \
    luarocks install lua-resty-string && \
    luarocks install luafilesystem && \
    luarocks install luasocket && \
    luarocks install redis-lua && \
    luarocks install compat53 && \
    luarocks install mmdblua && \
    luarocks install luaipc && \
    luarocks install lua-resty-injection

# Overwrite stripped envoy with full symbol
COPY curieproxy/envoy-1.16.2 /usr/local/bin/envoy

COPY init/start_curiefense.sh /start_curiefense.sh

COPY curieproxy/lua /lua
COPY curieproxy/lua/shared-objects/*.so /usr/local/lib/lua/5.1/

COPY curieproxy/config /bootstrap-config/config
COPY curieproxy/envoy.yaml.* /etc/envoy/

RUN mkdir /config && chmod a+rwxt /config

ENTRYPOINT ["/start_curiefense.sh"]

