#!/bin/bash
set -e

### === CONFIG ===
# 100 years
DAYS=36500
CERT_DIR="/etc/kubernetes/pki"
CONF_DIR="/etc/kubernetes"
CLUSTER_NAME="kubernetes"
# VIP IP
API_SERVER_ENDPOINT="172.16.139.30:9443"
NODE_NAME=$(hostname)

MASTER_IPS=("172.16.139.31" "172.16.139.32" "172.16.139.33")
MASTER_HOSTS=("openapi-kube-01" "openapi-kube-02" "openapi-kube-03")

mkdir -p "$CERT_DIR/etcd" "$CONF_DIR"

### === CA CERTS ===
echo "[*] Generating CA certs..."
openssl genrsa -out $CERT_DIR/ca.key 4096
openssl req -x509 -new -nodes -key $CERT_DIR/ca.key -subj "/CN=kubernetes-ca" -days $DAYS -out $CERT_DIR/ca.crt

openssl genrsa -out $CERT_DIR/front-proxy-ca.key 4096
openssl req -x509 -new -nodes -key $CERT_DIR/front-proxy-ca.key -subj "/CN=front-proxy-ca" -days $DAYS -out $CERT_DIR/front-proxy-ca.crt

openssl genrsa -out $CERT_DIR/etcd/ca.key 4096
openssl req -x509 -new -nodes -key $CERT_DIR/etcd/ca.key -subj "/CN=etcd-ca" -days $DAYS -out $CERT_DIR/etcd/ca.crt

### === API SERVER CERT ===
echo "[*] Generating API server cert..."
cat > $CERT_DIR/apiserver-openssl.cnf <<EOF
[req]
distinguished_name = req_distinguished_name
[req_distinguished_name]
[v3_ext]
subjectAltName = @alt_names
extendedKeyUsage = serverAuth
keyUsage = digitalSignature, keyEncipherment
[alt_names]
DNS.1 = kubernetes
DNS.2 = kubernetes.default
DNS.3 = kubernetes.default.svc
DNS.4 = kubernetes.default.svc.cluster.local
IP.1 = 10.96.0.1
IP.2 = 127.0.0.1
IP.3 = ${API_SERVER_ENDPOINT%%:*}
EOF

i=4
for ip in "${MASTER_IPS[@]}"; do
  echo "IP.$i = $ip" >> $CERT_DIR/apiserver-openssl.cnf
  ((i++))
done

for host in "${MASTER_HOSTS[@]}"; do
  echo "DNS.$i = $host" >> $CERT_DIR/apiserver-openssl.cnf
  ((i++))
done

openssl genrsa -out $CERT_DIR/apiserver.key 4096
openssl req -new -key $CERT_DIR/apiserver.key -subj "/CN=kube-apiserver" -out $CERT_DIR/apiserver.csr
openssl x509 -req -in $CERT_DIR/apiserver.csr -CA $CERT_DIR/ca.crt -CAkey $CERT_DIR/ca.key \
  -CAcreateserial -out $CERT_DIR/apiserver.crt -days $DAYS -extensions v3_ext -extfile $CERT_DIR/apiserver-openssl.cnf

### === API SERVER ETCD CLIENT ===
echo "[*] Generating apiserver-etcd-client cert..."
openssl genrsa -out $CERT_DIR/apiserver-etcd-client.key 4096
openssl req -new -key $CERT_DIR/apiserver-etcd-client.key -subj "/CN=kube-apiserver-etcd-client" \
  -out $CERT_DIR/apiserver-etcd-client.csr
openssl x509 -req -in $CERT_DIR/apiserver-etcd-client.csr \
  -CA $CERT_DIR/etcd/ca.crt -CAkey $CERT_DIR/etcd/ca.key -CAcreateserial \
  -out $CERT_DIR/apiserver-etcd-client.crt -days $DAYS

### === API SERVER KUBELET CLIENT ===
openssl genrsa -out $CERT_DIR/apiserver-kubelet-client.key 4096
openssl req -new -key $CERT_DIR/apiserver-kubelet-client.key -subj "/CN=kube-apiserver-kubelet-client" -out $CERT_DIR/kubelet-client.csr
openssl x509 -req -in $CERT_DIR/kubelet-client.csr -CA $CERT_DIR/ca.crt -CAkey $CERT_DIR/ca.key \
  -CAcreateserial -out $CERT_DIR/apiserver-kubelet-client.crt -days $DAYS

### === FRONT PROXY CLIENT ===
openssl genrsa -out $CERT_DIR/front-proxy-client.key 4096
openssl req -new -key $CERT_DIR/front-proxy-client.key -subj "/CN=front-proxy-client" -out $CERT_DIR/front.csr
openssl x509 -req -in $CERT_DIR/front.csr -CA $CERT_DIR/front-proxy-ca.crt -CAkey $CERT_DIR/front-proxy-ca.key \
  -CAcreateserial -out $CERT_DIR/front-proxy-client.crt -days $DAYS

### === ETCD CERTS WITH SAN ===
echo "[*] Generating etcd certs..."
cat > $CERT_DIR/etcd/openssl-etcd.cnf <<EOF
[req]
distinguished_name = req_distinguished_name
[req_distinguished_name]
[v3_ext]
subjectAltName = @alt_names
extendedKeyUsage = serverAuth, clientAuth
keyUsage = digitalSignature, keyEncipherment
[alt_names]
DNS.1 = localhost
DNS.2 = ${NODE_NAME}
IP.1 = 127.0.0.1
IP.2 = ::1
EOF

i=3
for ip in "${MASTER_IPS[@]}"; do
  echo "IP.$i = $ip" >> $CERT_DIR/etcd/openssl-etcd.cnf
  ((i++))
done

for name in server peer healthcheck-client; do
  openssl genrsa -out $CERT_DIR/etcd/${name}.key 4096
  openssl req -new -key $CERT_DIR/etcd/${name}.key -subj "/CN=etcd-$name" -out $CERT_DIR/etcd/${name}.csr
  openssl x509 -req -in $CERT_DIR/etcd/${name}.csr \
    -CA $CERT_DIR/etcd/ca.crt -CAkey $CERT_DIR/etcd/ca.key -CAcreateserial \
    -out $CERT_DIR/etcd/${name}.crt -days $DAYS \
    -extensions v3_ext -extfile $CERT_DIR/etcd/openssl-etcd.cnf
done

### === GEN KUBECONFIGS ===
gen_kubeconfig () {
  local NAME=$1
  local CN=$2
  local ORG=$3
  local KEY="$CERT_DIR/$NAME.key"
  local CSR="$CERT_DIR/$NAME.csr"
  local CRT="$CERT_DIR/$NAME.crt"
  local CONF="$CONF_DIR/$NAME.conf"

  echo "[*] Generating kubeconfig: $NAME"
  openssl genrsa -out "$KEY" 4096
  openssl req -new -key "$KEY" -subj "/CN=$CN/O=$ORG" -out "$CSR"
  openssl x509 -req -in "$CSR" -CA "$CERT_DIR/ca.crt" -CAkey "$CERT_DIR/ca.key" \
    -CAcreateserial -out "$CRT" -days $DAYS

  kubectl config set-cluster $CLUSTER_NAME \
    --certificate-authority="$CERT_DIR/ca.crt" \
    --embed-certs=true \
    --server="https://$API_SERVER_ENDPOINT" \
    --kubeconfig="$CONF"

  kubectl config set-credentials "$NAME" \
    --client-certificate="$CRT" \
    --client-key="$KEY" \
    --embed-certs=true \
    --kubeconfig="$CONF"

  kubectl config set-context "$NAME@$CLUSTER_NAME" \
    --cluster=$CLUSTER_NAME \
    --user="$NAME" \
    --kubeconfig="$CONF"

  kubectl config use-context "$NAME@$CLUSTER_NAME" --kubeconfig="$CONF"
}

gen_kubeconfig "admin" "admin" "system:masters"
gen_kubeconfig "controller-manager" "system:kube-controller-manager" "system:kube-controller-manager"
gen_kubeconfig "scheduler" "system:kube-scheduler" "system:kube-scheduler"
gen_kubeconfig "kubelet" "system:node:$NODE_NAME" "system:nodes"

# Copy admin.conf thành super-admin.conf
cp "$CONF_DIR/admin.conf" "$CONF_DIR/super-admin.conf"

echo " All certs and kubeconfigs generated"
