# Automatically_installing_Kubernetes
쿠버네티스 자동 쉘 스크립트 v1.29
- Kubernetes 클러스터 자동 설치 스크립트입니다.
- Version: 1.29v
- Cluster: Kubeadm

## 사용방법
### Master Node 설치
- git clone 명령어를 이용하여 로컬로 파일 가져오기.
```sh
git clone https://github.com/WoogiBoogi1129/Kubernetes_Installer.git
```

- sh파일 권한 부여
```sh
chmod +x Kubernetes_Installer/k8s_auto_install_master.sh
```

- sh 파일 실행
```sh
sudo ./Kubernetes_Installer/k8s_auto_install_master.sh
```

### Worker Node 설치
- git clone 명령어를 이용하여 로컬로 파일 가져오기.
```sh
git clone https://github.com/WoogiBoogi1129/Kubernetes_Installer.git
```

- sh파일 권한 부여
```sh
chmod +x Kubernetes_Installer/k8s_auto_install_worker.sh
```

- sh 파일 실행
```sh
sudo ./Kubernetes_Installer/k8s_auto_install_worker.sh
```

## Single Node에서 Kubernetes 설치
Single Node에서 Kubernetes를 설치할 경우, Master Node가 Worker Node 역할 또한 수행할 수 있도록 아래 명령을 통해 Taint를 제거해야합니다.
```sh
kubectl taint nodes --all node-role.kubernetes.io/control-plane-
```

## 추가
- 2024.06.12: Snapshot 전용 자동설치 파일 추가
- 2024.07.24: Master, Worker로 Installer 명칭 변경 및 최적화
- 2024.07.26: Repository 이름 변경
- 2024.08.08: Bash Completion 설치 기능 추가 및 코드 최적화
- 2024.09.26: Forwarding IPv4 and letting iptables see bridged traffic 설정 누락으로 인한 에러 발생 확인[수정]
