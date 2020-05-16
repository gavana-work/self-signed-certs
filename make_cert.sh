#!/bin/bash

#PURPOSE
#########
#used to make a server's cert

#
#INIT
########
subjectAltNames=()

#INPUT
#########
CAHOME=/opt/self-signed-certs/ca
CERT_DURATION=14600
SERVERNAME=hostnamehere
ALTNAME1=hostnamehere
subjectAltNames+=( "$SERVERNAME" "$ALTNAME1" )

#MAIN
#########

#Prepare the directories and files
mkdir $CAHOME/root/issued-servers/$SERVERNAME
mkdir $CAHOME/root/issued-servers/$SERVERNAME/csr
mkdir $CAHOME/root/issued-servers/$SERVERNAME/certs
mkdir $CAHOME/root/issued-servers/$SERVERNAME/private

#prepare the ca intermediate open-ssl file
tee $CAHOME/root/conf/$SERVERNAME-openssl.conf > /dev/null <<'EOF'
[req]
default_bits = 2048
default_md = sha256
distinguished_name = dn
prompt = no

[ dn ]
C=US
ST=CA
L=SD
O=Company
OU=GAV
emailAddress=not_needed
CN = @@SERVERNAME@@
EOF

sed -i "s+@@SERVERNAME@@+$SERVERNAME+g" $CAHOME/root/conf/$SERVERNAME-openssl.conf

tee $CAHOME/root/conf/$SERVERNAME-v3.ext > /dev/null <<'EOF'
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[ alt_names ]
EOF

i=1
for name in "${subjectAltNames[@]}"
do
	echo "DNS.${i} = ${name}" >> $CAHOME/root/conf/$SERVERNAME-v3.ext
	i=$((i+1))
done

#make the cert in the root dir
cd $CAHOME/root

#Create the cryptographic pair
echo ""
echo ""
echo "creating CERT for $SERVERNAME"

#convert key from pkcs10(rsa) to pkcs8(private)
openssl genrsa -aes256 -out $CAHOME/root/issued-servers/$SERVERNAME/private/app.rsakey.pem 4096
openssl pkey -in $CAHOME/root/issued-servers/$SERVERNAME/private/app.rsakey.pem -out $CAHOME/root/issued-servers/$SERVERNAME/private/app.privatekey.pem

openssl req -config $CAHOME/root/conf/$SERVERNAME-openssl.conf \
      -key $CAHOME/root/issued-servers/$SERVERNAME/private/app.rsakey.pem \
      -new -sha256 -out $CAHOME/root/issued-servers/$SERVERNAME/csr/app.csr.pem

openssl x509 -req -CA $CAHOME/root/intermediate/certs/intermediate.cert.pem \
      -CAkey $CAHOME/root/intermediate/private/intermediate.privatekey.pem \
      -extfile $CAHOME/root/conf/$SERVERNAME-v3.ext -days $CERT_DURATION -sha256 \
      -in $CAHOME/root/issued-servers/$SERVERNAME/csr/app.csr.pem \
      -out $CAHOME/root/issued-servers/$SERVERNAME/certs/app.cert.pem

#openssl req -config $CAHOME/root/conf/$SERVERNAME-openssl.conf \
#      -key $CAHOME/root/issued-servers/$SERVERNAME/private/app.rsakey.pem \
#      -new -sha256 -out $CAHOME/root/issued-servers/$SERVERNAME/csr/app.csr.pem

#openssl ca -config $CAHOME/root/conf/intermediate-openssl.conf \
#	  -extensions server_cert -days $CERT_DURATION -notext -md sha256 \
#      -in $CAHOME/root/issued-servers/$SERVERNAME/csr/app.csr.pem \
#      -out $CAHOME/root/issued-servers/$SERVERNAME/certs/app.cert.pem

echo ""
echo ""
echo "<<to view - app.cert.pem>>"
echo "openssl x509 -noout -text -in $CAHOME/root/issued-servers/$SERVERNAME/certs/app.cert.pem"
#openssl x509 -noout -text -in $CAHOME/root/issued-servers/$SERVERNAME/certs/app.cert.pem

#Check the link between root and intermediate
echo ""
echo ""
echo "<<app.cert.pem status>>"
openssl verify -CAfile $CAHOME/root/certs/ca-chain.cert.pem \
      $CAHOME/root/issued-servers/$SERVERNAME/certs/app.cert.pem

#add the private key to the cert to make a pem key cert combo
cat $CAHOME/root/issued-servers/$SERVERNAME/private/app.privatekey.pem \
   $CAHOME/root/issued-servers/$SERVERNAME/certs/app.cert.pem > $CAHOME/root/issued-servers/$SERVERNAME/certs/fullcert.pem

#make a pkcs12 cert from app.cert.pem
echo ""
echo ""
echo "<<converting app.cert.pem to app.cert.pkcs12"
openssl pkcs12 -export -inkey $CAHOME/root/issued-servers/$SERVERNAME/private/app.rsakey.pem -in $CAHOME/root/issued-servers/$SERVERNAME/certs/app.cert.pem -out $CAHOME/root/issued-servers/$SERVERNAME/certs/app.cert.pkcs12

#view the pkcs12 cert
echo ""
echo ""
echo "<<to view - app.cert.pkcs12>>"
echo "openssl pkcs12 –in $CAHOME/root/issued-servers/$SERVERNAME/certs/app.cert.pkcs12 -nodes –info"
#openssl pkcs12 –in $CAHOME/root/issued-servers/$SERVERNAME/certs/app.cert.pkcs12 -nodes –info

#import the pkcs12 cert to a keystore
echo ""
echo ""
echo "<<importing root, intermediate and app.cert.pkcs12 certs to app.cert.jks>>"
keytool -import -alias taproot -keystore $CAHOME/root/issued-servers/$SERVERNAME/certs/app.cert.jks -file $CAHOME/root/certs/root.cert.pem 
keytool -import -alias tapintermediate  -keystore $CAHOME/root/issued-servers/$SERVERNAME/certs/app.cert.jks -file $CAHOME/root/intermediate/certs/intermediate.cert.pem
keytool -importkeystore -srckeystore $CAHOME/root/issued-servers/$SERVERNAME/certs/app.cert.pkcs12 -srcstoretype PKCS12 -destkeystore $CAHOME/root/issued-servers/$SERVERNAME/certs/app.cert.jks

echo ""
echo ""
echo "<<to view - app.cert.jks>>"
echo "keytool -list -v -keystore $CAHOME/root/issued-servers/$SERVERNAME/certs/app.cert.jks" 
#keytool -list -v -keystore $CAHOME/root/issued-servers/$SERVERNAME/certs/app.cert.jks

echo ""
echo ""
cd $CAHOME/root/issued-servers/$SERVERNAME/certs
ls -ltr

#combine keystores
#keytool -importkeystore -srckeystore cacerts -destkeystore keystore.jks -srcstorepass changeit -deststorepass password
