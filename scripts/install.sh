#!/bin/bash
if [ -d ../K8s-binary ]
  then
	echo -e "Copying binary files.................."
	cp -a ../K8s-binary/{cfssl,cfssl-certinfo,cfssljson} ../roles/ssl/package/
	cp -a ../K8s-binary/{etcd,etcdctl} ../roles/etcd/package/
	cp -a ../K8s-binary/flanneld ../roles/flanneld/package/
	cp -a ../K8s-binary/{kube-apiserver,kube-controller-manager,kubectl,kube-scheduler} ../roles/master/package/
	cp -a ../K8s-binary/{kubelet,kube-proxy} ../roles/node/package/
	cp -a ../K8s-binary/{harbor-offline-installer-v1.1.2.tgz,docker-compose} ../roles/harbor/package/
	bash pre-setup.sh && bash deploy-ssl.sh && bash deploy-kubeconfig.sh && bash deploy-docker.sh && bash deploy-etcd.sh && bash deploy-flanneld.sh && bash deploy-master.sh && bash deploy-node.sh
  else
	echo -e "Please confirm whether you downloaded k8s-binary on cloud disk!!!"
        exit 1
fi
