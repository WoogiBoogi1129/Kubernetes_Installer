#!/bin/bash
set -euo pipefail

DEFAULT_K8S_VERSION="1.33"
DEFAULT_CRIO_VERSION="1.33"
DEFAULT_CILIUM_VERSION="latest"

K8S_VERSION=""
CRIO_VERSION=""
CILIUM_VERSION=""
AUTO_CONFIRM=false

function print_green() {
    echo -e "\e[32m$1\e[0m"
}

function print_error() {
    echo -e "\e[31m$1\e[0m" >&2
}

function usage() {
    cat <<USAGE
Kubernetes 자동 설치 스크립트

사용법: sudo ./k8s_auto_install.sh [옵션]

옵션:
  -k, --k8s-version <버전>      설치할 Kubernetes 버전 (기본: ${DEFAULT_K8S_VERSION})
  -r, --crio-version <버전>     설치할 CRI-O 버전 (기본: ${DEFAULT_CRIO_VERSION})
  -c, --cilium-version <버전>   설치할 Cilium 버전 (기본: ${DEFAULT_CILIUM_VERSION})
                                 latest 사용 시 최신 버전 설치
  -y, --yes                     프롬프트 없이 진행
  -h, --help                    도움말 출력
USAGE
}

function parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -k|--k8s-version)
                if [[ $# -lt 2 ]]; then
                    print_error "--k8s-version 옵션에는 값이 필요합니다."
                    exit 1
                fi
                K8S_VERSION="$2"
                shift 2
                ;;
            -r|--crio-version)
                if [[ $# -lt 2 ]]; then
                    print_error "--crio-version 옵션에는 값이 필요합니다."
                    exit 1
                fi
                CRIO_VERSION="$2"
                shift 2
                ;;
            -c|--cilium-version)
                if [[ $# -lt 2 ]]; then
                    print_error "--cilium-version 옵션에는 값이 필요합니다."
                    exit 1
                fi
                CILIUM_VERSION="$2"
                shift 2
                ;;
            -y|--yes)
                AUTO_CONFIRM=true
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                print_error "알 수 없는 옵션입니다: $1"
                usage
                exit 1
                ;;
        esac
    done
}

function ask_for_versions() {
    if [[ -z "$K8S_VERSION" ]]; then
        if $AUTO_CONFIRM; then
            K8S_VERSION="$DEFAULT_K8S_VERSION"
        else
            read -rp "설치할 Kubernetes 버전 [${DEFAULT_K8S_VERSION}]: " input
            K8S_VERSION="${input:-$DEFAULT_K8S_VERSION}"
        fi
    fi

    if [[ -z "$CRIO_VERSION" ]]; then
        if $AUTO_CONFIRM; then
            CRIO_VERSION="$DEFAULT_CRIO_VERSION"
        else
            read -rp "설치할 CRI-O 버전 [${DEFAULT_CRIO_VERSION}]: " input
            CRIO_VERSION="${input:-$DEFAULT_CRIO_VERSION}"
        fi
    fi

    if [[ -z "$CILIUM_VERSION" ]]; then
        if $AUTO_CONFIRM; then
            CILIUM_VERSION="$DEFAULT_CILIUM_VERSION"
        else
            read -rp "설치할 Cilium 버전 [${DEFAULT_CILIUM_VERSION}]: " input
            CILIUM_VERSION="${input:-$DEFAULT_CILIUM_VERSION}"
        fi
    fi
}

function require_root() {
    if [[ $(id -u) -ne 0 ]]; then
        print_error "이 스크립트는 root 권한으로 실행해야 합니다."
        exit 1
    fi
}

function gather_system_info() {
    if [[ ! -r /etc/os-release ]]; then
        print_error "/etc/os-release 파일을 읽을 수 없습니다."
        exit 1
    fi
    . /etc/os-release
    OS_ID=${ID:-}
    OS_VERSION_CODENAME=${VERSION_CODENAME:-}
    if [[ "$OS_ID" != "ubuntu" && "$OS_ID" != "debian" ]]; then
        print_error "지원하지 않는 운영 체제입니다: ${OS_ID}"
        exit 1
    fi
    if [[ -z "$OS_VERSION_CODENAME" ]]; then
        print_error "배포판 코드네임을 확인할 수 없습니다."
        exit 1
    fi
}

function system_update() {
    print_green "[1/11] 시스템 패키지 업데이트 및 필수 패키지 설치 중..."
    apt-get update
    apt-get install -y apt-transport-https ca-certificates curl gpg software-properties-common
}

function configure_kernel() {
    print_green "[2/11] Kubernetes 필수 커널 모듈 및 sysctl 설정 중..."
    cat <<EOF >/etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

    modprobe overlay
    modprobe br_netfilter

    cat <<EOF >/etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

    sysctl --system >/dev/null
}

function disable_swap() {
    print_green "[3/11] Swap 비활성화 중..."
    sed -i.bak '/\sswap\s/s/^/#/' /etc/fstab
    swapoff -a || true
}

function install_crio() {
    print_green "[4/11] CRI-O ${CRIO_VERSION} 설치 중..."
    local keyring_dir="/etc/apt/keyrings"
    install -m 0755 -d "$keyring_dir"

    local libcontainers_key="$keyring_dir/libcontainers-archive-keyring.gpg"
    local crio_key="$keyring_dir/crio-archive-keyring.gpg"

    curl -fsSL "https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/${OS_VERSION_CODENAME}/Release.key" \
        | gpg --dearmor -o "$libcontainers_key"

    curl -fsSL "https://download.opensuse.org/repositories/devel:/kubic:/cri-o:/${CRIO_VERSION}/${OS_VERSION_CODENAME}/Release.key" \
        | gpg --dearmor -o "$crio_key"

    cat <<EOF >/etc/apt/sources.list.d/libcontainers.list
deb [signed-by=${libcontainers_key}] https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/${OS_VERSION_CODENAME}/ /
EOF

    cat <<EOF >/etc/apt/sources.list.d/crio-${CRIO_VERSION}.list
deb [signed-by=${crio_key}] https://download.opensuse.org/repositories/devel:/kubic:/cri-o:/${CRIO_VERSION}/${OS_VERSION_CODENAME}/ /
EOF

    apt-get update
    apt-get install -y cri-o cri-o-runc
    systemctl enable --now crio
}

function install_kubernetes_components() {
    print_green "[5/11] Kubernetes ${K8S_VERSION} 저장소 추가 및 구성 요소 설치 중..."
    local keyring_dir="/etc/apt/keyrings"
    install -m 0755 -d "$keyring_dir"

    local k8s_key="$keyring_dir/kubernetes-apt-keyring.gpg"
    curl -fsSL "https://pkgs.k8s.io/core:/stable:/v${K8S_VERSION}/deb/Release.key" | gpg --dearmor -o "$k8s_key"

    cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb [signed-by=${k8s_key}] https://pkgs.k8s.io/core:/stable:/v${K8S_VERSION}/deb/ /
EOF

    apt-get update
    apt-get install -y kubelet kubeadm kubectl
    apt-mark hold kubelet kubeadm kubectl
    systemctl enable --now kubelet
}

function pull_required_images() {
    print_green "[6/11] kubeadm이 필요한 이미지를 사전 Pull 중..."
    kubeadm config images pull --kubernetes-version "v${K8S_VERSION}" --cri-socket unix:///var/run/crio/crio.sock
}

function kubeadm_init() {
    print_green "[7/11] Kubernetes Control Plane 초기화 중..."
    kubeadm init --kubernetes-version "v${K8S_VERSION}" --pod-network-cidr=10.244.0.0/16 --cri-socket unix:///var/run/crio/crio.sock

    print_green "[8/11] kubeconfig 설정 중..."
    mkdir -p "$HOME/.kube"
    cp -i /etc/kubernetes/admin.conf "$HOME/.kube/config"
    chown $(id -u):$(id -g) "$HOME/.kube/config"
}

function install_cilium_cli() {
    print_green "[9/11] Cilium CLI 설치 중..."
    local tmpdir
    tmpdir=$(mktemp -d)
    local cli_version
    cli_version=$(curl -fsSL https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
    local archive="cilium-linux-amd64.tar.gz"
    curl -L "https://github.com/cilium/cilium-cli/releases/download/${cli_version}/${archive}" -o "$tmpdir/${archive}"
    tar -xzf "$tmpdir/${archive}" -C "$tmpdir"
    install -m 0755 "$tmpdir/cilium" /usr/local/bin/cilium
    rm -rf "$tmpdir"
}

function install_cilium_cni() {
    print_green "[10/11] Cilium CNI 설치 중..."
    local args=(install)
    if [[ "$CILIUM_VERSION" != "latest" ]]; then
        local version="$CILIUM_VERSION"
        if [[ "$version" != v* ]]; then
            version="v${version}"
        fi
        args+=("--version" "$version")
    fi
    args+=("--wait")
    cilium "${args[@]}"
    cilium status --wait
}

function enable_bash_completion() {
    print_green "[11/11] Bash Completion 설정 중..."
    apt-get install -y bash-completion
    local bashrc="/root/.bashrc"
    if ! grep -q "kubectl completion" "$bashrc" 2>/dev/null; then
        echo 'source <(kubectl completion bash)' >> "$bashrc"
        echo 'alias k=kubectl' >> "$bashrc"
        echo 'complete -F __start_kubectl k' >> "$bashrc"
    fi
}

parse_args "$@"
require_root
gather_system_info
ask_for_versions

print_green "선택된 설정: Kubernetes ${K8S_VERSION}, CRI-O ${CRIO_VERSION}, Cilium ${CILIUM_VERSION}"

system_update
configure_kernel
disable_swap
install_crio
install_kubernetes_components
pull_required_images
kubeadm_init
install_cilium_cli
install_cilium_cni
enable_bash_completion

print_green "Kubernetes 클러스터 설치가 완료되었습니다! 새로운 셸 세션에서 kubectl을 사용하세요."
