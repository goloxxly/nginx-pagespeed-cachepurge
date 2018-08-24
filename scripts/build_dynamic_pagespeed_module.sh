#!/bin/bash

echo -e "\n[+] Obtaining current nginx version.."
NGINX_VERSION=$(nginx -v 2>&1 | awk -F/ '{print $2}' | awk -F " " '{print $1}')
echo "Your Nginx verion is $NGINX_VERSION"

echo -e "\n[+] Dowloading the sources.."
cd
wget -q http://nginx.org/download/nginx-$NGINX_VERSION.tar.gz
tar zxf nginx-$NGINX_VERSION.tar.gz
rm nginx-$NGINX_VERSION.tar.gz

echo -e "\n[+] Getting latest version of Nginx Pagespeed Module.."
NPS_VERSION=$(curl --insecure -sS https://www.modpagespeed.com/doc/release_notes | grep release_ | head -1 | sed -e "s/^.*release_\([0-9\.]*\)-beta.*/\1/" | awk -F " " '{print $3}' | awk -F "-" '{print $1}')
echo "The latest module version is : $NPS_VERSION"

echo -e "\n[+] Downloading.. the latest verion nps"
#wget https://github.com/apache/incubator-pagespeed-ngx/archive/latest-stable.zip
wget -q https://github.com/apache/incubator-pagespeed-ngx/archive/v${NPS_VERSION}-stable.zip
unzip -q v${NPS_VERSION}-stable.zip
rm v${NPS_VERSION}-stable.zip

cd incubator-pagespeed-ngx-${NPS_VERSION}-stable/
psol_url=https://dl.google.com/dl/page-speed/psol/${NPS_VERSION}.tar.gz
[ -e scripts/format_binary_url.sh ] && psol_url=$(scripts/format_binary_url.sh PSOL_BINARY_URL)
echo "Downloading psol from url1: $psol_url"
wget -q ${psol_url}
tar -xzf $(basename ${psol_url})  # extracts to psol/
rm -r $(basename ${psol_url})

echo -e "\n[+] Compiling the PageSpeed Dynamic Module"
cd ~/nginx-$NGINX_VERSION
./configure --add-dynamic-module=../incubator-pagespeed-ngx-${NPS_VERSION}-stable --with-compat
make modules && echo -e "\n[+] Done creating module"

cp objs/ngx_pagespeed.so /
