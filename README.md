# Ansible-Kubernetes

`Ansible-Kubernetes` 是一款基于二进制部署Kubernetes集群、并使用Ansible进行统一配置部署的工具；自行区别OS（Centos/Ubuntu）匹配进行自动部署；

| 组件       | 支持                           |
| ---------- | ------------------------------ |
| Os         | Ubuntu 16.04+, CentOS/RedHat 7 |
| K8s        | v1.9 ~ v1.14                   |
| Etcd       | v3.3.10~v3.3.12                |
| Docker-ce  | 18.06.3                        |
| Network    | flannel v0.11.0                |
| Harbor     | v1.1.2                         |
| Gpu-docker | v1.9 v1.10 for Ubuntu 16.04+   |

- 注：集群软件包下载（包含v1.9.0、v1.10.13、v1.13.5、v1.14.0） https://pan.baidu.com/s/1HzHUH31MGuor2A9wgLOjtw  提取码: 4gcp

  *同时可以自行进行其它版本的下载部署，仅需将目录下二进制更换即可*



# 使用文档

*以下操作均需具有root权限用户进行*

## Ansible安装

- Ubuntu

```
apt-get update
apt-get install -y software-properties-common
apt-add-repository ppa:ansible/ansible	#回车确认
apt-get update
apt-get install -y ansible 		#ansible版本>=2.7.9
```



- Centos

```
yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
yum install -y ansible		#ansible版本>=2.7.9
```



## 下载K8s集群二进制文件

​	*下载地址*: https://pan.baidu.com/s/1HzHUH31MGuor2A9wgLOjtw 提取码: 4gcp 
​	并将下载到的压缩包解压至repo当前目录



## 配置inventory

```
#拷贝inventory文件并定义集群主机分配
cp inventory.example inventory

cat inventory
[etcd]
ETCD_IP ansible_user='SUDO_USER'

[masters]
MASTERS_IP ansible_user='SUDO_USER'

[nodes]
NODES_IP ansible_user='SUDO_USER'

[harbor]
HARBOR_IP ansible_user='SUDO_USER'

[gpu_nodes]
GPU_IP ansible_user='SUDO_USER'
```

- `SUDO_USER` 为执行用户，多节点时填写多个；
- `[etcd]` 配置etcd节点信息，`ETCD_IP` 为etcd节点ip信息;
- `[masters]` 配置master节点信息，`MASTER_IP` 为k8s-master节点ip信息;
- `[nodes]` 配置node节点信息，`NODES_IP` 为k8s-node节点ip信息;
- `[harbor]` 配置harbor节点信息，`HARBOR_IP` 为harbor节点ip信息；
- `[gpu_nodes]`配置gpu节点信息，`GPU_IP`为gpu节点ip信息（当前Nvidia-docker驱动最高支持到v1.10）;



## 配置group_vars

```
#拷贝all.yaml并配置变量
cp all.yaml.example all.yaml

cat all.yaml
---
# [Local]
TLS_TOKEN: e25555ddf761636af1e8cc8692d7f064
KUBELET_API_SERVER: https://172.17.127.65:6443
CERT_DIR_TMP: /opt/k8s/ssl

# Harbor
HARBOR_IP: 172.17.127.65
HARBOR_PORT: 5000
HARBOR_DB_PASSWD: passwd
HARBOR_BASE_DIR: /data
HARBOR_WORK_DIR: "{{ HARBOR_BASE_DIR}}/harbor"
HARBOR_ADMIN_PASSWD: passwd

# [Main]
# Docker
DOCKER_VERSION: 18.06
REG_MIRROR_1: https://registry.docker-cn.com
REG_MIRROR_2: https://docker.mirrors.ustc.edu.cn
LOG_DRIVER: json-file
LOG_LEVEL: warn
LOG_MAX_SIZE: 10m
LOG_MAX_FILE: 3
STORAGE_DIR: /data/docker
ENABLE_REMOTE_API: false

# Etcd
ETCD_PEER_URL_SCHEME: https
ETCD_DATA_DIR: /data/apps/etcd/data
ETCD_CONF_DIR: /data/apps/etcd/etc
ETCD_BIN_DIR: /data/apps/etcd/bin
ETCD_VERSION: v3.3.12
ETCD_PEER_GROUP: etcd
ETCD_PEER_PORT: 2380
ETCD_CLIENT_PORT: 2379
ETCD_PEER_CA_FILE: "{{ CERT_DIR }}/ca.pem"
ETCD_PEER_CERT_FILE: "{{ CERT_DIR }}/server.pem"
ETCD_PEER_KEY_FILE: "{{ CERT_DIR}}/server-key.pem"

# Flanneld
FLANNEL_ETCD_PREFIX: /coreos.com/network
FLANNEL_LOG_DIR: /data/logs/flannel
FLANNEL_CONF_DIR: /data/apps/flannel/conf
FLANNEL_BIN_DIR: /data/apps/flannel/bin
FLANNEL_NETWORK: "{{ CLUSTER_CIDR }}"
FLANNEL_SUBNET_LEN: 24
FLANNEL_BACKEND_TYPE: vxlan
FLANNEL_KEY: /coreos.com/network/config

# Master
K8S_CLUSTER: kubernetes
CERT_DIR: /etc/kubernetes/ssl
MASTER_CONF_DIR: /data/apps/kubernetes/conf
MASTER_BIN_DIR: /data/apps/kubernetes/bin
MASTER_LOG_DIR: /data/logs/kubernetes
MASTER_PEER_GROUP: masters
BOOTSTRAP_TOKEN: "{{ TLS_TOKEN }}"
SSL_CONFIG:
  IP_LIST:
    - 127.0.0.1
    - 10.254.0.1
    - 39.104.102.69
  DNS:
    - kubernetes
    - kubernetes.default
    - kubernetes.default.svc
    - kubernetes.default.svc.cluster
    - kubernetes.default.svc.cluster.local

# Node
KUBELET_POD_INFRA_CONTAINER: mirrorgooglecontainers/pause-amd64:3.1
CLUSTER_DNS: 10.254.0.2
CLUSTER_CIDR: 172.17.0.0/16
SERVICE_CLUSTRE_IP_RANGE: 10.254.0.0/16
KUBERNETES_CONF_DIR: /data/apps/kubernetes/conf
KUBERNETES_BIN_DIR: /data/apps/kubernetes/bin
KUBERNETES_LOG_DIR: /data/logs/kubernetes
KUBERNETES_WORK_DIR: /var/lib/kubelet

# Nvidia-docker
DISTRIBUTION: $(. /etc/os-release;echo $ID$VERSION_ID)
```

`[local]` 下根据实际集群环境进行修改

- `TLS_TOKEN` TLS Bootstrapping 使用的 Token，可以使用命令 head -c 16 /dev/urandom | od -An -t x | tr -d ' ' 生成；
- `KUBELET_API_SERVER` 配置kube-apiserver的接口信息；
- `CERT_DIR_TMP` 初始化时k8s密钥临时保存目录；
- `HARBOR_IP` harbor部署节点ip信息；
- `HARBOR_DB_PASSWD` harbor数据库密码；
- `HARBOR_ADMIN_PASSWD` harbor管理员密码；



`[Main]` 下的配置可以不做修改，也可自行调整如：`MASTER_CONF_DIR` `MASTER_BIN_DIR` `MASTER_LOG_DIR`



## 逐步部署

*scripts* 目录下按照步骤执行

```
#将二进制包进行分发
cp -a ../K8s-binary/{cfssl,cfssl-certinfo,cfssljson} ../roles/ssl/package/

cp -a ../K8s-binary/{etcd,etcdctl} ../roles/etcd/package/

cp -a ../K8s-binary/flanneld ../roles/flanneld/package/

cp -a ../K8s-binary/{kube-apiserver,kube-controller-manager,kubectl,kube-scheduler} ../roles/master/package/

cp -a ../K8s-binary/{kubelet,kube-proxy} ../roles/node/package/

cp -a ../K8s-binary/{harbor-offline-installer-v1.1.2.tgz,docker-compose} ../roles/harbor/package/

#初始化OS环境
bash pre-setup.sh

#生成ssl文件
bash deploy-ssl.sh

#生成kubeconfig认证文件
bash deploy-kubeconfig.sh

#部署docker
bash deploy-docker.sh

#部署etcd
bash deploy-etcd.sh

#部署flannel
bash deploy-flanneld.sh

#部署master
bash deploy-master.sh

#部署node
bash deploy-node.sh

#部署harbor
bash deploy-harbor.sh

#部署gpu_nodes
bash deploy-nvidia-docker.sh
```



## 一键部署

*scripts*目录下

```
#一键部署k8s集群
bash install.sh
```

一键部署仅满足k8s集群部署，不包含gpu节点、harbor等相关部署；



## 授权Node节点

首次注册的node节点需进行授权

```
#查看等待授权节点
kubectl get csr
NAME                                                   AGE     REQUESTOR           CONDITION
node-csr-fzroeNNUOi1LtAvBL6zGuDmlphii5zpbsSk2sw2Ro_I   3m44s   kubelet-bootstrap   Pending
node-csr-rKlGCgVbjHcz1GhOq0z1eZHqqJzcK9oiflaXuyRZjJE   3m44s   kubelet-bootstrap   Pending

#通过授权
kubectl certificate approve node-csr-fzroeNNUOi1LtAvBL6zGuDmlphii5zpbsSk2sw2Ro_I node-csr-rKlGCgVbjHcz1GhOq0z1eZHqqJzcK9oiflaXuyRZjJE

#查看node状态
kubectl get node
```

- 注：以上操作在k8s-master节点下进行，首次部署需加载环境变量（source ~/.bashrc）或重新login



## DNS容器启动

*workspaces*目录下

```
#启动dns容器
kubectl create -f dns.yaml
```



## 授权匿名用户

*workspaces*目录下

```
#授权
kubectl create -f anonymous.yaml
```



## Nvidia-docker驱动

*workspaces目录下*

```
#创建Nvidia驱动被node发现资源
kubectl create -f nvidia-device-plugin.yml
```



## 验证DNS

*workspaces*目录下

```
#启动busybox daemonset
kubectl create -f busybox.yaml

#在每个node下进行容器内部解析
for i in `kubectl get pod | grep busybox|awk '{print $1}'`;do kubectl exec -it $i nslookup www.baidu.com && kubectl exec -it $i hostname ;echo '-------------------------------';done
```



## 清理集群

*scripts*目录下

```
#清理k8s集群
bash clean.sh
```



# 沟通交流

QQ：262735860

Q群：610156560