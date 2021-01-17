#!/usr/bin/bash
# Build NGINX to suit server code
# need older module / new modules applied
# need packages below for build Debian
sudo wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/php.list
apt update
apt install -y nginx php7.4 php7.4-common php7.4-cli php7.4-fpm
apt install -y php7.4-mysql php7.4-gd php7.4-json php7.4-curl php7.4-zip php7.4-xml php7.4-mbstring php7.4-pgsql php7.4-bcmath;
apt install -y python3-pip  python-dev python-lxml libminiupnpc-dev miniupnpc
apt install -y build-essential libssl-dev python3-dbus python3-augeas python3-apt ntpdate
apt install -y libxml2-dev libffi-dev libjpeg-dev libpng-dev uuid-dev python-dbus;
apt install -y perl libperl-dev libgd3 libgd-dev libgeoip1 libgeoip-dev geoip-bin libxml2 libxml2-dev libxslt1.1 libxslt1-dev libmaxminddb
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

wget https://ftp.pcre.org/pub/pcre/pcre-8.44.tar.gz && tar xzvf pcre-8.44.tar.gz
wget https://www.zlib.net/zlib-1.2.11.tar.gz && tar xzvf zlib-1.2.11.tar.gz

echo "=> nginx"
wget -O nginx.tar.gz https://nginx.org/download/nginx-1.19.6.tar.gz
tar -xvf nginx.tar.gz
mv nginx-1.19.6 nginx-src
rm -fv nginx.tar.gz

echo "=> Push Stream module"
git clone http://github.com/wandenberg/nginx-push-stream-module.git push-stream
 
echo "=> Mod Zip"
git clone https://github.com/evanmiller/mod_zip.git mod_zip

echo "=> Mode HearsMoreNginxModule"
git clone https://github.com/openresty/headers-more-nginx-module.git mod_headers

echo "=> OpenSSL"
wget https://www.openssl.org/source/openssl-1.1.1i.tar.gz
tar -xvf openssl-1.1.1i.tar.gz
rm -fv openssl-1.1.1i.tar.gz
git clone https://github.com/google/ngx_brotli.git
cd ngx_brotli && git submodule update --init && cd $BUILD_DIR
git clone https://github.com/FRiCKLE/ngx_cache_purge.git ngx_cache
wget https://github.com/maxmind/libmaxminddb/releases/download/1.5.0/libmaxminddb-1.5.0.tar.gz
git clone https://github.com/leev/ngx_http_geoip2_module.git ngx_geoip2
			

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
 --user=nginx \
            --group=nginx \
            --build=Debian \
            --builddir=nginx-1.17.2 \
            --with-select_module \
            --with-poll_module \
            --with-threads \
            --with-file-aio \
            --with-http_ssl_module \
            --with-http_v2_module \
            --with-http_realip_module \
            --with-http_addition_module \
            --with-http_xslt_module=dynamic \
            --with-http_image_filter_module=dynamic \
            --with-http_geoip_module=dynamic \
            --with-http_sub_module \
            --with-http_dav_module \
            --with-http_flv_module \
            --with-http_mp4_module \
            --with-http_gunzip_module \
            --with-http_gzip_static_module \
            --with-http_auth_request_module \
            --with-http_random_index_module \
            --with-http_secure_link_module \
            --with-http_degradation_module \
            --with-http_slice_module \
            --with-http_stub_status_module \
            --with-http_perl_module=dynamic \
            --with-perl_modules_path=/usr/share/perl/5.26.1 \
            --with-perl=/usr/bin/perl \
            --http-log-path=/var/log/nginx/access.log \
            --http-client-body-temp-path=/var/cache/nginx/client_temp \
            --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
            --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
            --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
            --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
            --with-mail=dynamic \
            --with-mail_ssl_module \
            --with-stream=dynamic \
            --with-stream_ssl_module \
            --with-stream_realip_module \
            --with-stream_geoip_module=dynamic \
            --with-stream_ssl_preread_module \
            --with-compat \
            --with-pcre=../pcre-8.44\
            --with-pcre-jit \
            --with-zlib=../zlib-1.2.11 \
            --with-openssl=../openssl-1.1.1i \
            --with-openssl-opt=no-nextprotoneg \
            --with-debug
            --add-module=../push-stream \
            --add-module=../mod_zip \
            --add-module=../mod_headers \
            --add-module=../mod_filter \
            --add-dynamic-module=../ngx_brotli \
            --add-module=../ngx_geoip2 \
            --add-module=../ngx_cache \
            --with-cc-opt='-O2 -g -pipe -Wall -Wp,-D_FORTIFY_SOURCE=2 -fexceptions -fstack-protector-strong --param=ssp-buffer-size=4 -grecord-gcc-switches -m64 -mtune=generic'

echo "3) Compile"
make -j8

echo "4) Install"
# sudo make install
#sudo systemctl enable nginx.service
#sudo systemctl start nginx.service
