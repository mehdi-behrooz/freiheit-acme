#!/bin/bash

if [[ -z $CF_Email || -z $CF_Key ]]; then
    echo "ERROR: Missing Cloudflare authentication info: CF_Email and CF_Key"
    exit 1
fi

error=0

buffer=$(mktemp)
exec 3>"$buffer"

/bin/acme --set-default-ca --server letsencrypt

for domain in ${DOMAINS//,/ }; do

    printf '\n%s\n\n' "### Issuing certificates for '$domain':"

    /bin/acme --issue -d "$domain" -d "*.$domain" \
        --dns dns_cf --debug "${DEBUG_LEVEL}"

    case "$?" in
    "0")
        echo "Certificates for '$domain' issued." >&3
        ;;
    "1")
        echo "ERROR issuing certificates for '$domain'." >&3
        error=1
        continue
        ;;
    "2")
        echo "Existing certificates for '$domain' are valid. Skipping." >&3
        ;;
    esac

    printf '\n%s\n\n' "### Installing certificates for '$domain':"

    /bin/acme --installcert -d "$domain" -d "*.$domain" \
        --fullchain-file "$ACME_CERT_INSTALL_DIR/$domain.acme.pem" \
        --key-file "$ACME_CERT_INSTALL_DIR/$domain.acme.pem.key" \
        --debug "${DEBUG_LEVEL}"

    case "$?" in
    "0")
        echo "Certificates for '$domain' installed successfuly." >&3
        ;;
    "1")
        echo "ERROR while installing certificates for '$domain'." >&3
        error=1
        ;;
    esac

done

if [[ $error == "0" ]]; then
    echo "Everything was OK." >&3
else
    echo "Check the logs to see error details." >&3
fi

printf "\nSummary:\n%s\n\n" "$(sed 's/^/    /' <"$buffer")"
rm -r "$buffer"
exec 3>&-

/usr/sbin/crond -l 8
echo "Cron daemon started for future certificates renewals."

trap "exit" SIGTERM
sleep infinity &
wait
