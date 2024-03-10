#!/bin/bash

rm /opt/tplink/EAPController/data/keystore/eap.cer
rm /opt/tplink/EAPController/data/keystore/eap.keystore

cp /etc/letsencrypt/live/angrydonkey.io/cert.pem /opt/tplink/EAPController/data/keystore/eap.cer

openssl pkcs12 -export -inkey /etc/letsencrypt/live/angrydonkey.io/privkey.pem \
	-in /etc/letsencrypt/live/angrydonkey.io/cert.pem \
	-certfile /etc/letsencrypt/live/angrydonkey.io/chain.pem \
	-name eap -out omada.p12 -password pass:tplink

keytool -importkeystore -deststorepass tplink \
	-destkeystore /opt/tplink/EAPController/data/keystore/eap.keystore \
	-srckeystore omada.p12 -srcstoretype PKCS12 -srcstorepass tplink

systemctl restart omada
