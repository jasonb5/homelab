#!/bin/bash

cat /etc/letsencrypt/live/angrydonkey.io/privkey.pem /etc/letsencrypt/live/angrydonkey.io/cert.pem \
	| tee /etc/letsencrypt/live/angrydonkey.io/combined.pem

systemctl restart lighttpd
