# kubeadmを使った冗長化されたKubernetes Cluster の作成 

kubeadmを使って、Control Planeを冗長化する構成を作成する。  
etcdについてはControl Planeにて稼働させる構成。  

## Server Resource  
下記スペックのサーバーを用意する。

- OS: CentOS Linux release 7.9.2009
- cpu: 8core
- mem: 16GB
- disk: 120GB

7台用意し、用途は下記となる

| 用途 | 台数 |
|:--|:--|
| Control Plane | 3 |
| Worker node | 3 | 
| HAProxy | 1 | 


# 構築手順 

## 全体像  
1. OSの構成
2. 事前準備系の処理
3. HAProxyのインストールと構成
4. Dockerのインストールと初期設定
5. kubeadm/kubelet/kubectlのインストール
6. kubeadmの実行  
7. nodeの追加 
8. kubectlの構成 
9. CNIの構成

## 手順

### OSの構成  
**全台で実施**
すべてのサーバーをetc/hostsに登録する。また、LBでうけるホストも登録する。IPアドレスはHAproxyとするサーバーIPアドレス  

サンプルはHostsファイル参照  

### haproxy install
Control Planeを冗長構成とするためにLBを構成する。LBはHAPproxyを利用する  
名前解決は etc/hosts で行うためDNSは不要

**haproxyとして構成するサーバーだけで実施**
```
yum install haproxy -y
cp /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg.org
```

/etc/haproxy/haproxy.cfg を編集する。サンプルは haproxy.cfg を参照  
更新後サービスをrestart
```
systemctl restart haproxy
```

### Dockerのインストール
**HAProxy以外のサーバーすべてで実施**
コピペして実行。
```
swapoff -a
sed -i '/swap/s/^/#/' /etc/fstab

systemctl stop firewalld && systemctl disable firewalld

setenforce 0
sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

sudo yum install -y yum-utils device-mapper-persistent-data lvm2
sudo yum-config-manager --add-repo \
  https://download.docker.com/linux/centos/docker-ce.repo
sudo yum update -y && sudo yum install -y \
  containerd.io-1.2.13 \
  docker-ce-19.03.11 \
  docker-ce-cli-19.03.11
sudo mkdir /etc/docker
cat <<EOF | sudo tee /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ]
}
EOF
sudo mkdir -p /etc/systemd/system/docker.service.d
sudo systemctl daemon-reload
sudo systemctl restart docker
systemctl enable docker
docker --version

modprobe br_netfilter

cat <<EOF >  /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system
```

### kubeadm/kubelet/kubectlのインストール
**HAProxy以外のサーバーすべてで実施**

```
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kube*
EOF

yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
systemctl enable --now kubelet
```

### kubeadmの実行
**Control Planeにする1台だけで実行**
Kubeadmの構成上、まずは1台のControl Planeを作成し、そこに対してNodeを追加していく形になる。  

#### CNIの確認  
今回はCalicoを利用する。  
Calicoで定義されているPodネットワークを確認する。変更する場合は calico.yaml を編集する。  
- default: 192.168.0.0/16

```
yum install wget -y
wget https://docs.projectcalico.org/manifests/calico.yaml

less calico.yaml
```

#### kubeadm-config.yamlの作成  
Kubeadmを実行する際のConfigを作成する。  
Kubernetesバージョンを指定する場合は "kubernetesVersion"を指定する。 
Calico.yamlで確認したPodネットワークを変更する場合は "podSubnet" を変更する  

```
cat <<EOF > ~/kubeadm-config.yaml
apiVersion: kubeadm.k8s.io/v1beta2
kind: ClusterConfiguration
kubernetesVersion: stable
controlPlaneEndpoint: "k8s.ks-pic.local:6443"
networking:
  podSubnet: 192.168.0.0/16
EOF
```

#### kuberadmの実行  

```
kubeadm init --config=kubeadm-config.yaml --upload-certs | tee kubeadm-init.out
```

### nodeの追加  
**残りのKubernetesノード5台で実施**

Kubeadmの実行結果上にクラスターにJoinするためのコマンドが記載されているので、そのコマンドを実行する。
Control Plane用とWorker用に分かれているので注意。  
下記はサンプルなので、必ず出力されたものを利用すること。  

```sample
You can now join any number of the control-plane node running the following command on each as root:
## Control Plane用

  kubeadm join k8s1.ks-pic.local:6443 --token tcs9ll.znjvevf0rncbmbuy \
    --discovery-token-ca-cert-hash sha256:e3ee2ed372f52fe4c59bd17544a6f27e8f9737186be7bd896aba56b13b41928f \
    --control-plane --certificate-key 9b8ec7fe9d1522835c853a2ff857348936db62cb7d4ee5a5159552f808b5b4b8

Please note that the certificate-key gives access to cluster sensitive data, keep it secret!
As a safeguard, uploaded-certs will be deleted in two hours; If necessary, you can use
"kubeadm init phase upload-certs --upload-certs" to reload certs afterward.

Then you can join any number of worker nodes by running the following on each as root:
## Worker用 

kubeadm join k8s1.ks-pic.local:6443 --token tcs9ll.znjvevf0rncbmbuy \
    --discovery-token-ca-cert-hash sha256:e3ee2ed372f52fe4c59bd17544a6f27e8f9737186be7bd896aba56b13b41928f
```


## kubectlの構成  
kubectlを実行する際にConfigを読み込ませるにはいくつかの方法があります。  
- ~/.kube/config に値を設定する 
- $KUBECONFIG にConfigを読み込ませる  
- kubectl実行時にkubeconfigを指定して実行する  

**1クラスターだけであれば .kube/configに指定するで問題ないかと思います。**   

kubeadmが完了した際にconfigの指定方法も記載があるので実行する

```
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

*$KUBECONFIGで使う方法*
`export KUBECONFIG=/etc/kubernetes/admin.conf`


## CNIの構成
Calico.yamlをkubectlから読み込ませる。  

```
kubectl apply -f calico.yaml
```

## Statusの確認  

`kubectl get node` を実行し、ノードのステータスが正常であることを確認する

```
# kubectl get node
NAME             STATUS   ROLES                  AGE    VERSION
ks-kubeadm-001   Ready    control-plane,master   115m   v1.20.1
ks-kubeadm-002   Ready    control-plane,master   114m   v1.20.1
ks-kubeadm-003   Ready    control-plane,master   114m   v1.20.1
ks-kubeadm-004   Ready    <none>                 112m   v1.20.1
ks-kubeadm-005   Ready    <none>                 112m   v1.20.1
ks-kubeadm-006   Ready    <none>                 112m   v1.20.1
```

