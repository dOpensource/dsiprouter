
# Install dependencies

apt -y install openssl coreutils

TMP_CERT_DIR=/tmp/stir-shaken-ca
DSIP_CERT_DIR=/etc/dsiprouter/certs/stirshaken

# Generate Root Certificate Private Key
mkdir $TMP_CERT_DIR
cd $TMP_CERT_DIR
openssl ecparam -noout -name prime256v1 -genkey -out ca-key.pem


# Generate Public Key
openssl req -x509 -new -nodes -key ca-key.pem -sha256 -days 1825 -out ca-cert.pem


#Generate EC Private Key
openssl ecparam -noout -name prime256v1 -genkey -out sp-key.pem

#Generate an openssl.conf file which includes a hex-encoded TNAuthList extension
cat >TNAuthList.conf << EOF
asn1=SEQUENCE:tn_auth_list
[tn_auth_list]
field1=EXP:0,IA5:1001
EOF

openssl asn1parse -genconf TNAuthList.conf -out TNAuthList.der

cat >openssl.conf << EOF
[ req ]
distinguished_name = req_distinguished_name
req_extensions = v3_req
[ req_distinguished_name ]
commonName = "SHAKEN"
[ v3_req ]
EOF

od -An -t x1 -w TNAuthList.der | sed -e 's/ /:/g' -e 's/^/1.3.6.1.5.5.7.1.26=DER/' >>openssl.conf


# Generate a Certificate Signing Request, which includes our required TNAuthorizationList
openssl req -new -nodes -key sp-key.pem -keyform PEM \
    -subj '/C=US/ST=VA/L=Somewhere/O=AcmeTelecom, Inc./OU=VOIP/CN=SHAKEN' \
    -sha256 -config openssl.conf \
    -out sp-csr.pem


# On the CA side, generate the certificate (User-CSR + CA-cert + CA-key => User-cert)
openssl x509 -req -in sp-csr.pem -CA ../stir-shaken-ca/ca-cert.pem -CAkey ../stir-shaken-ca/ca-key.pem -CAcreateserial \
  -days 825 -sha256 -extfile openssl.conf -extensions v3_req -out sp-cert.pem

#  verify that the SP certificate contains the TNAuthList extension
openssl x509 -in sp-cert.pem -text -noout

# Copy Key and Certificate to /opt/dsiprouter
cp $TMP_CERT_DIR/sp-cert.pem $DSIP_CERT_DIR
cp $TMP_CERT_DIR/sp-key.pem  $DSIP_CERT_DIR

#Change the ownership of the certificates and key
chown -R dsiprouter:kamailio $DSIP_CERT_DIR

#Change permissions
chmod -R 755 $DSIP_CERT_DIR
