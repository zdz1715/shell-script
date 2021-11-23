#!/bin/sh

. ./tools.sh

set +e

export DOCKER_VERSION="19.03.15"
export KUBERNETES_VERSION="1.20.4"
export MIRROR="Aliyun"
export DOCKER_INSTALL_SH="./docker-install.sh"

i_os_not_conform() {
  log_exit "Unsupported distribution '$i_distributions'"
}


if ! is_root > /dev/null; then
  log_exit "this installer needs the ability to run commands as root."
fi

#i_lsb_dist=$( get_distribution )
i_distributions=$( get_distribution true " ")
i_hostname=$( hostname )

# todo: 主机名称不能为 localhost，且不包含下划线、小数点、大写字母
if [ "$i_hostname" = "localhost" ]; then
  log_exit "The hostname cannot be localhost"
fi


docker_install() {
    item "Install Docker"
    if command_exists docker && [ -e /var/run/docker.sock ]; then
      # 启动docker
      docker_start
      NOW_DOCKER_VERSION=$(docker version -f "{{.Server.Version}}")
      if [ "$NOW_DOCKER_VERSION" != "$DOCKER_VERSION" ]; then
        log_info "Docker version is not $DOCKER_VERSION, reinstall now"
        docker_install_sh
      else
        log_info "Docker already installed, Version: $DOCKER_VERSION"
      fi
    else
      log_info "Docker not install, install now"
      docker_install_sh
    fi
}

docker_install_sh() {
  sh -c "VERSION=$DOCKER_VERSION $DOCKER_INSTALL_SH --mirror $MIRROR"
  # 启动docker
  docker_start
}

docker_start() {
    if command_exists systemctl; then
      log_command systemctl start docker && systemctl enable docker
    fi
}

item "Prepare The Environment"

log_info "Linux Distributions: $i_distributions"
log_info "Hostname: $i_hostname"
log_info "Kubernetes Version: $KUBERNETES_VERSION"
log_info "Docker Version: $DOCKER_VERSION"

case "$i_distributions" in

  "centos 7")
    # 安装基本工具
    log_command yum install -y -q yum-utils curl openssl socat conntrack ebtables ipset
    # https://kubernetes.io/docs/setup/production-environment/container-runtimes/#containerd
    log_command "cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF"
    log_command modprobe overlay
    log_command modprobe br_netfilter
    log_command "cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF"
    log_command sysctl --system
    # 关闭 停止防火墙
    log_command systemctl stop firewalld
    log_command systemctl disable firewalld

    # 关闭 SeLinux
    log_command setenforce 0
    log_command "sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config"

    # 关闭 swap
    log_command swapoff -a
    log_command "yes | cp /etc/fstab /etc/fstab_bak"
    log_command "cat /etc/fstab_bak | grep -v swap > /etc/fstab"

    # 安装docker
    docker_install

    # 安装kubeadm
    item "Install Kubernetes"
    log_command 'cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF'
    log_command yum install -y -q --nogpgcheck kubelet-${KUBERNETES_VERSION} kubeadm-${KUBERNETES_VERSION} kubectl-${KUBERNETES_VERSION}
    log_command systemctl enable kubelet && systemctl start kubelet
    log_command kubelet --version
  ;;
  *)
    i_os_not_conform
  ;;
esac





