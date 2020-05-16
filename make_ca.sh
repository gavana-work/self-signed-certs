#!/bin/bash

#PURPOSE
#########
#used to make a local CA

#INPUT
#########
CAHOME=/opt/self-signed-certs/ca
ROOT_DURATION=22000
INTERMEDIATE_DURATION=21800
SERIAL=123456abcde78910

#MAIN
#########

#Prepare the directories and files	
mkdir $CAHOME
mkdir $CAHOME/root
mkdir $CAHOME/root/certs
mkdir $CAHOME/root/crl
mkdir $CAHOME/root/newcerts
mkdir $CAHOME/root/private

mkdir $CAHOME/root/intermediate
mkdir $CAHOME/root/intermediate/certs
mkdir $CAHOME/root/intermediate/crl
mkdir $CAHOME/root/intermediate/csr
mkdir $CAHOME/root/intermediate/newcerts
mkdir $CAHOME/root/intermediate/private

mkdir $CAHOME/root/conf
mkdir $CAHOME/root/issued-servers

touch $CAHOME/root/index.txt
echo 1000 > $CAHOME/root/serial	

touch $CAHOME/root/intermediate/index.txt
echo $SERIAL > $CAHOME/root/intermediate/certs/intermediate.srl
echo 1000 > $CAHOME/root/intermediate/serial
echo 1000 > $CAHOME/root/intermediate/crlnumber 

#prepare the ca root open-ssl file
tee $CAHOME/root/conf/root-openssl.conf > /dev/null <<'EOF'
[ ca ]
# man ca
default_ca = CA_default

[ CA_default ]
# Directory and file locations.
dir               = @@CAHOME@@/root
certs             = $dir/certs
crl_dir           = $dir/crl
new_certs_dir     = $dir/newcerts
database          = $dir/index.txt
serial            = $dir/serial
RANDFILE          = $dir/private/.rand

# The root key and root certificate.
private_key       = $dir/private/root.key.pem
certificate       = $dir/certs/root.cert.pem

# For certificate revocation lists.
crlnumber         = $dir/crlnumber
crl               = $dir/crl/ca.crl.pem
crl_extensions    = crl_ext
default_crl_days  = 30

# SHA-1 is deprecated, so use SHA-2 instead.
default_md        = sha256

name_opt          = ca_default
cert_opt          = ca_default
default_days      = 375
preserve          = no
policy            = policy_strict

[ policy_strict ]
# The root CA should only sign intermediate certificates that match.
# See the POLICY FORMAT section of man ca
countryName             = match
stateOrProvinceName     = match
organizationName        = match
organizationalUnitName  = optional
commonName              = supplied
emailAddress            = optional

[ policy_loose ]
# Allow the intermediate CA to sign a more diverse range of certificates.
# See the POLICY FORMAT section of the ca man page.
countryName             = optional
stateOrProvinceName     = optional
localityName            = optional
organizationName        = optional
organizationalUnitName  = optional
commonName              = supplied
emailAddress            = optional

[ req ]
# Options for the req tool (man req).
default_bits        = 2048
distinguished_name  = req_distinguished_name
string_mask         = utf8only

# SHA-1 is deprecated, so use SHA-2 instead.
default_md          = sha256

# Extension to add when the -x509 option is used.
x509_extensions     = v3_ca

[ req_distinguished_name ]
# See <https://en.wikipedia.org/wiki/Certificate_signing_request>.
countryName                     = US
stateOrProvinceName             = CA
localityName                    = SD
0.organizationName              = Company
organizationalUnitName          = GAV
commonName                      = Common Name
emailAddress                    = not_needed

# Optionally, specify some defaults.
countryName_default             = US
stateOrProvinceName_default     = CA
localityName_default            = SD
0.organizationName_default      = Company
organizationalUnitName_default  = GAV
emailAddress_default            = not_needed

[ v3_ca ]
# Extensions for a typical CA (man x509v3_config).
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical, CA:true
keyUsage = critical, digitalSignature, cRLSign, keyCertSign

[ v3_intermediate_ca ]
# Extensions for a typical intermediate CA (man x509v3_config).
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical, CA:true, pathlen:0
keyUsage = critical, digitalSignature, cRLSign, keyCertSign

[ usr_cert ]
# Extensions for client certificates (man x509v3_config).
basicConstraints = CA:FALSE
nsCertType = client, email
nsComment = "OpenSSL Generated Client Certificate"
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer
keyUsage = critical, nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = clientAuth, emailProtection

[ server_cert ]
# Extensions for server certificates (man x509v3_config).
basicConstraints = CA:FALSE
nsCertType = server
nsComment = "OpenSSL Generated Server Certificate"
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer:always
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth

[ crl_ext ]
# Extension for CRLs (man x509v3_config).
authorityKeyIdentifier=keyid:always

[ ocsp ]
# Extension for OCSP signing certificates (man ocsp).
basicConstraints = CA:FALSE
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer
keyUsage = critical, digitalSignature
extendedKeyUsage = critical, OCSPSigning
EOF
sed -i "s+@@CAHOME@@+$CAHOME+g" $CAHOME/root/conf/root-openssl.conf

#prepare the ca intermediate open-ssl file
tee $CAHOME/root/conf/intermediate-openssl.conf > /dev/null <<'EOF'

[ ca ]
# man ca
default_ca = CA_default

[ CA_default ]
# Directory and file locations.
dir               = @@CAHOME@@/root/intermediate
certs             = $dir/certs
crl_dir           = $dir/crl
new_certs_dir     = $dir/newcerts
database          = $dir/index.txt
serial            = $dir/serial
RANDFILE          = $dir/private/.rand

# The root key and root certificate.
private_key       = $dir/private/intermediate.key.pem
certificate       = $dir/certs/intermediate.cert.pem

# For certificate revocation lists.
crlnumber         = $dir/crlnumber
crl               = $dir/crl/intermediate.crl.pem
crl_extensions    = crl_ext
default_crl_days  = 30

# SHA-1 is deprecated, so use SHA-2 instead.
default_md        = sha256

name_opt          = ca_default
cert_opt          = ca_default
default_days      = 375
preserve          = no
policy            = policy_loose

[ policy_strict ]
# The root CA should only sign intermediate certificates that match.
# See the POLICY FORMAT section of man ca.
countryName             = match
stateOrProvinceName     = match
organizationName        = match
organizationalUnitName  = optional
commonName              = supplied
emailAddress            = optional

[ policy_loose ]
# Allow the intermediate CA to sign a more diverse range of certificates.
# See the POLICY FORMAT section of the ca man page.
countryName             = optional
stateOrProvinceName     = optional
localityName            = optional
organizationName        = optional
organizationalUnitName  = optional
commonName              = supplied
emailAddress            = optional

[ req ]
# Options for the req tool (man req).
default_bits        = 2048
distinguished_name  = req_distinguished_name
string_mask         = utf8only

# SHA-1 is deprecated, so use SHA-2 instead.
default_md          = sha256

# Extension to add when the -x509 option is used.
x509_extensions     = v3_ca

[ req_distinguished_name ]
# See <https://en.wikipedia.org/wiki/Certificate_signing_request>.
countryName                     = US
stateOrProvinceName             = CA
localityName                    = SD
0.organizationName              = Company
organizationalUnitName          = GAV
commonName                      = Common Name
emailAddress                    = not_needed

# Optionally, specify some defaults.
countryName_default             = US
stateOrProvinceName_default     = CA
localityName_default            = SD
0.organizationName_default      = Company
organizationalUnitName_default  = GAV
emailAddress_default            = not_needed

[ v3_ca ]
# Extensions for a typical CA (man x509v3_config).
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical, CA:true
keyUsage = critical, digitalSignature, cRLSign, keyCertSign

[ v3_intermediate_ca ]
# Extensions for a typical intermediate CA (man x509v3_config).
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical, CA:true, pathlen:0
keyUsage = critical, digitalSignature, cRLSign, keyCertSign

[ usr_cert ]
# Extensions for client certificates (man x509v3_config).
basicConstraints = CA:FALSE
nsCertType = client, email
nsComment = "OpenSSL Generated Client Certificate"
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer
keyUsage = critical, nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = clientAuth, emailProtection

[ server_cert ]
# Extensions for server certificates (man x509v3_config).
basicConstraints = CA:FALSE
nsCertType = server
nsComment = "OpenSSL Generated Server Certificate"
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer:always
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth

[ crl_ext ]
# Extension for CRLs (man x509v3_config).
authorityKeyIdentifier=keyid:always

[ ocsp ]
# Extension for OCSP signing certificates (man ocsp).
basicConstraints = CA:FALSE
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer
keyUsage = critical, digitalSignature
extendedKeyUsage = critical, OCSPSigning
EOF
sed -i "s+@@CAHOME@@+$CAHOME+g" $CAHOME/root/conf/intermediate-openssl.conf

#we need to be in the root dir for the correct files to be written to
cd $CAHOME/root

#Create the ROOT CA cryptographic pair
echo ""
echo ""
echo "creating ROOT"
openssl genrsa -aes256 -out $CAHOME/root/private/root.key.pem 4096
openssl pkey -in $CAHOME/root/private/root.key.pem -out $CAHOME/root/private/root.privatekey.pem


openssl req -config $CAHOME/root/conf/root-openssl.conf \
      -key $CAHOME/root/private/root.key.pem \
      -new -x509 -days $ROOT_DURATION -sha256 -extensions v3_ca \
      -out $CAHOME/root/certs/root.cert.pem

echo ""
echo ""
echo "<<to view - root.cert.pem>>"
echo "#openssl x509 -noout -text -in $CAHOME/root/certs/root.cert.pem"
#openssl x509 -noout -text -in $CAHOME/root/certs/root.cert.pem

#Create the INTERMEDIATE CA cryptographic pair
echo ""
echo ""
echo "creating INTERMEDIATE"

openssl genrsa -aes256 -out $CAHOME/root/intermediate/private/intermediate.key.pem 4096
openssl pkey -in $CAHOME/root/intermediate/private/intermediate.key.pem -out $CAHOME/root/intermediate/private/intermediate.privatekey.pem

openssl req -config $CAHOME/root/conf/intermediate-openssl.conf -new -sha256\
      -key $CAHOME/root/intermediate/private/intermediate.key.pem \
      -out $CAHOME/root/intermediate/csr/intermediate.csr.pem

openssl ca -config $CAHOME/root/conf/root-openssl.conf -extensions v3_intermediate_ca \
      -days $INTERMEDIATE_DURATION -notext -md sha256 \
      -in $CAHOME/root/intermediate/csr/intermediate.csr.pem \
      -out $CAHOME/root/intermediate/certs/intermediate.cert.pem

echo ""
echo ""
echo "<<to view - intermediate.cert.pem>>"
echo "openssl x509 -noout -text -in $CAHOME/root/intermediate/certs/intermediate.cert.pem"
#openssl x509 -noout -text -in $CAHOME/root/intermediate/certs/intermediate.cert.pem

#Check the link between root and intermediate
echo ""
echo ""
echo "<<intermediate cert status>>"
openssl verify -CAfile $CAHOME/root/certs/root.cert.pem \
      $CAHOME/root/intermediate/certs/intermediate.cert.pem

#create a chain to verify certs against
cat $CAHOME/root/intermediate/certs/intermediate.cert.pem \
    $CAHOME/root/certs/root.cert.pem > $CAHOME/root/certs/ca-chain.cert.pem

#create a cacerts keystore file
echo ""
echo ""
echo "<<creating cacerts file>>"
echo "importing root"
keytool -import -alias taproot -keystore $CAHOME/root/cacerts -file $CAHOME/root/certs/root.cert.pem 
echo "importing intermediate"
keytool -import -alias tapintermediate  -keystore $CAHOME/root/cacerts -file $CAHOME/root/intermediate/certs/intermediate.cert.pem

#view the keystore
echo ""
echo ""
echo "<<to view - cacerts>"
echo "keytool -list -v -keystore $CAHOME/root/cacerts"
#keytool -list -v -keystore $CAHOME/root/cacerts 

#convert the root and intermediate certs to pkcs12
echo ""
echo ""
echo "creating pkcs12 root and intermediate certs for browser"
openssl pkcs12 -export -inkey $CAHOME/root/private/root.key.pem -in $CAHOME/root/certs/root.cert.pem -out $CAHOME/root/certs/root.cert.pfx
openssl pkcs12 -export -inkey $CAHOME/root/intermediate/private/intermediate.key.pem -in $CAHOME/root/intermediate/certs/intermediate.cert.pem -out $CAHOME/root/intermediate/certs/intermediate.cert.pfx

echo ""
echo ""
cd $CAHOME/root
ls -ltr