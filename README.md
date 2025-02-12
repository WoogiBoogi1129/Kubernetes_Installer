# Automatically_installing_Kubernetes
쿠버네티스 자동 쉘 스크립트 v1.29
- Kubernetes 클러스터 자동 설치 스크립트입니다.
- Version: 1.29v
- Cluster: Kubeadm

## 사용방법
### 사전 요구사항
- 해당 스크립트는 root 권한에서만 동작하여 아래와 같은 명령어를 통해 root 권한으로 변경해야함.
```sh
sudo su -
```

### Master Node 설치
- git clone 명령어를 이용하여 로컬로 파일 가져오기.
```sh
git clone https://github.com/WoogiBoogi1129/Kubernetes_Installer.git
```

- sh파일 권한 부여
```sh
sudo chmod +x Kubernetes_Installer/k8s_auto_install_master.sh
```

- sh 파일 실행
```sh
sudo ./Kubernetes_Installer/k8s_auto_install_master.sh
```

### Worker Node 설치
- git clone 명령어를 이용하여 로컬로 파일 가져오기.
```sh
sudo git clone https://github.com/WoogiBoogi1129/Kubernetes_Installer.git
```

- sh파일 권한 부여
```sh
sudo chmod +x Kubernetes_Installer/k8s_auto_install_worker.sh
```

- sh 파일 실행
```sh
sudo ./Kubernetes_Installer/k8s_auto_install_worker.sh
```

## Single Node에서 Kubernetes 설치
Single Node에서 Kubernetes를 설치할 경우, Master Node가 Worker Node 역할 또한 수행할 수 있도록 아래 명령을 통해 Taint를 제거해야합니다.
```sh
sudo kubectl taint nodes --all node-role.kubernetes.io/control-plane-
```

## 추가
- 2024.06.12: Snapshot 전용 자동설치 파일 추가
- 2024.07.24: Master, Worker로 Installer 명칭 변경 및 최적화
- 2024.07.26: Repository 이름 변경
- 2024.08.08: Bash Completion 설치 기능 추가 및 코드 최적화
- 2024.09.26: Forwarding IPv4 and letting iptables see bridged traffic 설정 누락으로 인한 에러 발생 확인[수정]
- 2024.12.02: Shell 진행사항 보일 수 있도록 초록 문구로 강조 추가(Master, Worker 포함)
