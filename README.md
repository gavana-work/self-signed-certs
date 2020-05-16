# Purpose

This is a pair of scripts for creating a local Certificate of Authority to issue your own SSL certificates.
The only requirement is `openssl`.

# Instructions

### Configure Scripts

Place `make_ca.sh`, `make_cert.sh`, and the empty folder `ca` in a working directory for your self-signed CA to exist.

Edit the input section of `make_ca.sh` with the full path of your `ca` folder for `CAHOME`. The other variables can remain the same. 
For example:
```sh
#INPUT
#########
CAHOME=/opt/self-signed-certs/ca
ROOT_DURATION=22000
INTERMEDIATE_DURATION=21800
SERIAL=123456abcde78910
```
Edit the input section of `make_cert.sh` with the full path of your `ca` folder for `CAHOME`, and your server name in the `SERVERNAME` and `ALTNAME1` variables. `CERT_DURATION` can remain the same. 
If you have the need for more than one subject alternative name just add it to the `subjectAltNames` array.
For example, with only one subject alternative name:
```sh
#INPUT
#########
CAHOME=/opt/self-signed-certs/ca
CERT_DURATION=14600
SERVERNAME=hostnamehere
ALTNAME1=hostnamehere
subjectAltNames+=( "$SERVERNAME" "$ALTNAME1" )
```

### Run the Scripts

No arguments are necessary for the scripts to run.
Just run `make_ca.sh` first and follow the prompts.
Then run`make_cert.sh` and follow the prompts.

### Collect your Certificates

You can find all the certs necessary for the `root` and `intermediate` CA here:
```
ca/root/certs
ca/root/intermediate/certs
```
The cert for your server can be found here. 
For example, if your server name was sandbox: 
```
ca/root/issued-servers/sandbox/certs
```
`fullcert.pem` is the server private key + server cert.
`app.cert.jks` is a java keystore certificate if you need it.