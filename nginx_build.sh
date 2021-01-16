#!/usr/bin/bash
# Build NGINX to suit server code
# need older module / new modules applied
# need packages below for build Debian

apt-get install libpcre3 libpcre3-dev

export BUILD_DIR=/tmp/nginx-build

# Script
echo "=== Custom NGINX ==="
echo "=> Build folder: $BUILD_DIR"
echo "0) Cleaning folder"
rm -rfv $BUILD_DIR
mkdir $BUILD_DIR
echo "1) Fetching dependencies"
cd $BUILD_DIR
git clone git://github.com/yaoweibin/ngx_http_substitutions_filter_module.git mod_filter
echo "=> nginx"
wget -O nginx.tar.gz https://nginx.org/download/nginx-1.19.6.tar.gz
tar -xvf nginx.tar.gz
mv nginx-1.19.6 nginx-src
rm -fv nginx.tar.gz

echo "=> Push Stream module"
wget -O push-stream.zip https://github.com/wandenberg/nginx-push-stream-module/archive/master.zip
unzip push-stream.zip
mv nginx-push-stream-module-master push-stream
rm push-stream.zip

echo "=> Mod Zip"
wget -O mod_zip.zip https://github.com/evanmiller/mod_zip/archive/master.zip
unzip mod_zip.zip
mv mod_zip-master mod_zip
rm mod_zip.zip

echo "=> Mode HearsMoreNginxModule"
wget -O mod_headers.zip https://github.com/openresty/headers-more-nginx-module/archive/master.zip
unzip mod_headers.zip
mv headers-more-nginx-module-master mod_headers
rm mod_headers.zip

echo "=> OpenSSL"
wget https://www.openssl.org/source/openssl-1.1.1i.tar.gz
tar -xvf openssl-1.1.1i.tar.gz
rm -fv openssl-1.1.1i.tar.gz

echo "2) Configure"
cd $BUILD_DIR/nginx-src
./configure --prefix=/etc/nginx \
    --sbin-path=/usr/sbin/nginx --conf-path=/etc/nginx/nginx.conf \
    --error-log-path=/var/log/nginx/error.log --http-log-path=/var/log/nginx/access.log \
    --pid-path=/var/run/nginx.pid --lock-path=/var/run/nginx.lock \
    --http-client-body-temp-path=/var/cache/nginx/client_temp \
    --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
    --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
    --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
    --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
    --user=nginx --group=nginx \
    --with-openssl=$BUILD_DIR/openssl-1.1.1i \
    --with-openssl-opt=enable-tls1_3 \
    --with-http_ssl_module \
    --with-http_realip_module \
    --with-http_addition_module \
    --with-http_sub_module \
    --with-http_dav_module \
    --with-http_flv_module \
    --with-http_mp4_module \
    --with-http_gunzip_module \
    --with-http_gzip_static_module \
    --with-http_random_index_module \
    --with-http_secure_link_module \
    --with-http_stub_status_module \
    --with-http_auth_request_module \
    --with-http_v2_module \
    --with-mail \
    --with-mail_ssl_module \
    --with-file-aio \
    --with-ipv6 \
    --add-module=$BUILD_DIR/push-stream \
    --add-module=$BUILD_DIR/mod_zip \
    --add-module=$BUILD_DIR/mod_headers \
    --add-module=$BUILD_DIR/mod_filter \
    --with-cc-opt='-O2 -g -pipe -Wall -Wp,-D_FORTIFY_SOURCE=2 -fexceptions -fstack-protector-strong --param=ssp-buffer-size=4 -grecord-gcc-switches -m64 -mtune=generic'

echo "3) Compile"
make -j8

echo "4) Install"
# sudo make install
