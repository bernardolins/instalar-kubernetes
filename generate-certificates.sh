#!/bin/bash
set -e

#### Config
cat << EOF > $token/openssl.cnf
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names
[alt_names]
DNS.1 = kubernetes
DNS.2 = kubernetes.default
DNS.3 = kubernetes.default.svc
DNS.4 = kubernetes.default.svc.cluster.local
IP.1 = ${K8S_SERVICE_IP}
IP.2 = ${MASTER_HOST}
EOF

#### Root certificates
openssl genrsa -out $token/ca-key.pem 2048
openssl req -x509 -new -nodes -key $token/ca-key.pem -days 10000 -out $token/ca.pem -subj "/CN=kube-ca"

openssl genrsa -out $token/apiserver-key.pem 2048
openssl req -new -key $token/apiserver-key.pem -out $token/apiserver.csr -subj "/CN=kube-apiserver" -config $token/openssl.cnf
openssl x509 -req -in $token/apiserver.csr -CA $token/ca.pem -CAkey $token/ca-key.pem -CAcreateserial -out $token/apiserver.pem -days 365 -extensions v3_req -extfile $token/openssl.cnf

openssl genrsa -out $token/admin-key.pem 2048
openssl req -new -key $token/admin-key.pem -out $token/admin.csr -subj "/CN=kube-admin"
openssl x509 -req -in $token/admin.csr -CA $token/ca.pem -CAkey $token/ca-key.pem -CAcreateserial -out $token/admin.pem -days 365

rm -rf $token/openssl.cnf
rm -rf $token/*.csr
rm -rf $token/*.srl

#### Generate workers certificates
for (( i=0; i<${#worker_ip_array[@]}; i++ )); do

mkdir -p $token/worker/${worker_hostname_array[$i]}/ssl

#### Worker config
cat << EOF > $token/worker/${worker_hostname_array[$i]}/ssl/${worker_hostname_array[$i]}-openssl.cnf
  [req]
  req_extensions = v3_req
  distinguished_name = req_distinguished_name
  [req_distinguished_name]
  [ v3_req ]
  basicConstraints = CA:FALSE
  keyUsage = nonRepudiation, digitalSignature, keyEncipherment
  subjectAltName = @alt_names
  [alt_names]
  IP.1 = ${worker_ip_array[$i]}
EOF

openssl genrsa -out $token/worker/${worker_hostname_array[$i]}/ssl/worker-key.pem 2048

WORKER_IP=${worker_ip_array[$i]} openssl req -new -key $token/worker/${worker_hostname_array[$i]}/ssl/worker-key.pem -out $token/worker/${worker_hostname_array[$i]}/ssl/worker.csr -subj "/CN=${worker_hostname_array[$i]}" -config $token/worker/${worker_hostname_array[$i]}/ssl/${worker_hostname_array[$i]}-openssl.cnf

WORKER_IP=${worker_ip_array[$i]} openssl x509 -req -in $token/worker/${worker_hostname_array[$i]}/ssl/worker.csr -CA $token/ca.pem -CAkey $token/ca-key.pem -CAcreateserial -out $token/worker/${worker_hostname_array[$i]}/ssl/worker.pem -days 365 -extensions v3_req -extfile $token/worker/${worker_hostname_array[$i]}/ssl/${worker_hostname_array[$i]}-openssl.cnf

cp $token/ca.pem $token/worker/${worker_hostname_array[$i]}/ssl
rm -f $token/worker/${worker_hostname_array[$i]}/ssl/${worker_hostname_array[$i]}-openssl.cnf
rm -f $token/worker/${worker_hostname_array[$i]}/ssl/*.csr

done

#### Copy master certificates to correct place
mkdir -p $token/master/$masterhostname/ssl
cp $token/ca.pem $token/apiserver-key.pem $token/apiserver.pem $token/master/$masterhostname/ssl
