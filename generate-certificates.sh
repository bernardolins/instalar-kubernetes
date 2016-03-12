#!/bin/bash
set -e

#### Config
cat << EOF > $output/$token/openssl.cnf
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
openssl genrsa -out $output/$token/ca-key.pem 2048
openssl req -x509 -new -nodes -key $output/$token/ca-key.pem -days 10000 -out $output/$token/ca.pem -subj "/CN=kube-ca"

openssl genrsa -out $output/$token/apiserver-key.pem 2048
openssl req -new -key $output/$token/apiserver-key.pem -out $output/$token/apiserver.csr -subj "/CN=kube-apiserver" -config $output/$token/openssl.cnf
openssl x509 -req -in $output/$token/apiserver.csr -CA $output/$token/ca.pem -CAkey $output/$token/ca-key.pem -CAcreateserial -out $output/$token/apiserver.pem -days 365 -extensions v3_req -extfile $output/$token/openssl.cnf

openssl genrsa -out $output/$token/admin-key.pem 2048
openssl req -new -key $output/$token/admin-key.pem -out $output/$token/admin.csr -subj "/CN=kube-admin"
openssl x509 -req -in $output/$token/admin.csr -CA $output/$token/ca.pem -CAkey $output/$token/ca-key.pem -CAcreateserial -out $output/$token/admin.pem -days 365

rm -rf $output/$token/openssl.cnf
rm -rf $output/$token/*.csr
rm -rf $output/$token/*.srl

#### Generate workers certificates
for (( i=0; i<${#worker_ip_array[@]}; i++ )); do

mkdir -p $output/$token/worker/${worker_hostname_array[$i]}/ssl

#### Worker config
cat << EOF > $output/$token/worker/${worker_hostname_array[$i]}/ssl/${worker_hostname_array[$i]}-openssl.cnf
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

openssl genrsa -out $output/$token/worker/${worker_hostname_array[$i]}/ssl/worker-key.pem 2048

WORKER_IP=${worker_ip_array[$i]} openssl req -new -key $output/$token/worker/${worker_hostname_array[$i]}/ssl/worker-key.pem -out $output/$token/worker/${worker_hostname_array[$i]}/ssl/worker.csr -subj "/CN=${worker_hostname_array[$i]}" -config $output/$token/worker/${worker_hostname_array[$i]}/ssl/${worker_hostname_array[$i]}-openssl.cnf

WORKER_IP=${worker_ip_array[$i]} openssl x509 -req -in $output/$token/worker/${worker_hostname_array[$i]}/ssl/worker.csr -CA $output/$token/ca.pem -CAkey $output/$token/ca-key.pem -CAcreateserial -out $output/$token/worker/${worker_hostname_array[$i]}/ssl/worker.pem -days 365 -extensions v3_req -extfile $output/$token/worker/${worker_hostname_array[$i]}/ssl/${worker_hostname_array[$i]}-openssl.cnf

cp $output/$token/ca.pem $output/$token/worker/${worker_hostname_array[$i]}/ssl
rm -f $output/$token/worker/${worker_hostname_array[$i]}/ssl/${worker_hostname_array[$i]}-openssl.cnf
rm -f $output/$token/worker/${worker_hostname_array[$i]}/ssl/*.csr

done

#### Copy master certificates to correct place
mkdir -p $output/$token/master/$masterhostname/ssl
cp $output/$token/ca.pem $output/$token/apiserver-key.pem $output/$token/apiserver.pem $output/$token/master/$masterhostname/ssl
