#!/bin/bash

if [[ -z $CF_Email || -z $CF_Key ]]; then
    echo "ERROR: Missing Cloudflare authentication info: CF_Email and CF_Key"
    exit 1
fi

/bin/acme --set-default-ca --server letsencrypt

for domain in ${DOMAINS//,/ }; do

    /bin/acme --issue -d "$domain" -d "*.$domain" \
        --dns dns_cf --debug "${DEBUG_LEVEL}"

    /bin/acme --installcert -d "$domain" -d "*.$domain" \
        --fullchain-file "$ACME_CERT_INSTALL_DIR/$domain.acme.pem" \
        --key-file "$ACME_CERT_INSTALL_DIR/$domain.acme.pem.key" \
        --debug "${DEBUG_LEVEL}"

done

/usr/sbin/crond -l 8
echo "Running crond successful."

trap "exit" SIGTERM
sleep infinity &
wait
