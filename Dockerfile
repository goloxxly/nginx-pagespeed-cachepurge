FROM debian:stretch

RUN echo "deb http://ftp.debian.org/debian stretch-backports main" >> /etc/apt/sources.list \
    && echo "deb-src http://ftp.debian.org/debian stretch-backports main" >> /etc/apt/sources.list \
    && apt-get update \
    && apt-get  -t stretch-backports install -y nginx-extras \
    && apt-get -t stretch-backports build-dep -y nginx-extras \
    && apt-get install -y sudo curl


# Please note that the long parameter list after '-a' is from the original build
# param of nginx and needed to make the new module binary compatible with nginx.
# They can be get from nginx by calling 'nginx -V'
#
# It would be nice to make them pulled automatically by this script.
#
# '--with-cc-opt='-DNGX_HTTP_HEADERS'' is also said to be required:
# https://github.com/apache/incubator-pagespeed-ngx/issues/1440#issuecomment-315565106
#
RUN NGINX_VERSION=$(nginx -v 2>&1 | awk -F/ '{print $2}' | awk -F " " '{print $1}') \
    && echo "Your Nginx verion is $NGINX_VERSION" \
    && curl --insecure -f -L -sS https://ngxpagespeed.com/install > ~/psinstall.sh \
    && chmod +x ~/psinstall.sh \
    && ~/psinstall.sh -v latest-stable --dynamic -y -n $NGINX_VERSION -a \
    "--with-cc-opt='-g -O2 -fdebug-prefix-map=/build/nginx-$NGINX_VERSION=. \
    -fstack-protector-strong -Wformat -Werror=format-security -fPIC -Wdate-time \
    -D_FORTIFY_SOURCE=2' --with-ld-opt='-Wl,-z,relro -Wl,-z,now -fPIC' \
    --prefix=/usr/share/^Cinx --conf-path=/etc/nginx/nginx.conf \
    --http-log-path=/var/log/nginx/access.log --error-log-path=/var/log/nginx/error.log \
    --lock-path=/var/lock/nginx.lock --pid-path=/run/nginx.pid \
    --modules-path=/usr/lib/nginx/modules --http-client-body-temp-path=/var/lib/nginx/body \
    --http-fastcgi-temp-path=/var/lib/nginx/fastcgi --http-proxy-temp-path=/var/lib/nginx/proxy \
    --http-scgi-temp-path=/var/lib/nginx/scgi --http-uwsgi-temp-path=/var/lib/nginx/uwsgi --with-pcre-jit \
    --with-http_ssl_module --with-http_stub_status_module --with-http_realip_module \
    --with-http_auth_request_module --with-http_v2_module --with-http_dav_module \
    --with-http_slice_module --with-threads --with-http_addition_module \
    --with-http_flv_module --with-http_geoip_module=dynamic --with-http_gunzip_module \
    --with-http_gzip_static_module --with-http_image_filter_module=dynamic \
    --with-http_mp4_module --with-http_perl_module=dynamic --with-http_random_index_module \
    --with-http_secure_link_module --with-http_sub_module --with-http_xslt_module=dynamic \
    --with-mail=dynamic --with-mail_ssl_module --with-stream=dynamic \
    --with-stream_ssl_module --with-stream_ssl_preread_module \
    --with-cc-opt='-DNGX_HTTP_HEADERS'"



FROM debian:stretch

RUN echo "deb http://ftp.debian.org/debian stretch-backports main" >> /etc/apt/sources.list \
    && echo "deb-src http://ftp.debian.org/debian stretch-backports main" >> /etc/apt/sources.list \
    && apt-get update \
    && apt-get  -t stretch-backports install -y nginx-extras \
    && apt-get install -y curl less \
    && apt-get autoremove -y && rm -rf /var/lib/apt/lists/* /etc/apt/sources.list.d/nginx.list

COPY --from=0 /usr/lib/nginx/modules/ngx_pagespeed.so /usr/lib/nginx/modules/ngx_pagespeed.so

ADD config/ngx_pagespeed.conf /etc/nginx/modules-available/ngx_pagespeed.conf
RUN ln -s /etc/nginx/modules-available/ngx_pagespeed.conf /etc/nginx/modules-enabled/ngx_pagespeed.conf

RUN ln -sf /dev/stderr /var/log/nginx/error.log

CMD ["nginx", "-g", "daemon off;"]
