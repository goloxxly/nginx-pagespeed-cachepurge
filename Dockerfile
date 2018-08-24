FROM debian:stretch

RUN echo "deb http://ftp.debian.org/debian stretch-backports main" >> /etc/apt/sources.list \
    && echo "deb-src http://ftp.debian.org/debian stretch-backports main" >> /etc/apt/sources.list \
    && apt-get update \
    && apt-get  -t stretch-backports install -y nginx-extras \
    && apt-get install -y unzip gcc make libpcre3-dev zlib1g-dev wget curl build-essential libpcre3 libcurl4-openssl-dev libjansson-dev uuid-dev \
    && nginx -v

ADD scripts/build_dynamic_pagespeed_module.sh build_dynamic_pagespeed_module.sh
RUN chmod +x build_dynamic_pagespeed_module.sh \
    && ./build_dynamic_pagespeed_module.sh



FROM debian:stretch

RUN echo "deb http://ftp.debian.org/debian stretch-backports main" >> /etc/apt/sources.list \
    && apt-get update \
    && apt-get install -y curl less \
    && apt-get  -t stretch-backports install -y nginx-extras

COPY --from=0 /ngx_pagespeed.so /usr/lib/nginx/ngx_pagespeed.so

ADD config/ngx_pagespeed.conf /etc/nginx/modules-available/ngx_pagespeed.conf
RUN ln -s /etc/nginx/module-available/ngx_pagespeed.conf /etc/nginx/modules-enabled/ngx_pagespeed.conf

RUN ln -sf /dev/stderr /var/log/nginx/error.log

CMD ["nginx", "-g", "daemon off;"]
