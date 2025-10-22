# Automatically_installing_Kubernetes
쿠버네티스 자동 쉘 스크립트 (CRI-O + kubeadm)
- Kubernetes 클러스터 자동 설치 스크립트입니다.
- 기본 Runtime: CRI-O
- 기본 Kubernetes Version: v1.33

## 사용방법
### 설치 절차 (Control Plane 자동 구성)
1. git clone 명령어를 이용하여 로컬로 파일 가져오기.
   ```sh
   git clone https://github.com/WoogiBoogi1129/Kubernetes_Installer.git
   ```

2. 스크립트 실행 권한 부여.
   ```sh
   chmod +x Kubernetes_Installer/k8s_auto_install.sh
   ```

3. 스크립트 실행.
   ```sh
   ./Kubernetes_Installer/k8s_auto_install.sh
   ```

   실행 중 Kubernetes, CRI-O, Cilium 버전을 직접 입력하여 선택할 수 있으며 아무 입력도 하지 않으면 아래 기본값으로 진행됩니다.
   - Kubernetes: v1.33
   - CRI-O: v1.33
   - Cilium: 최신 버전

   스크립트는 필요한 단계에서 자동으로 `sudo` 권한을 요청합니다. 일반 사용자 계정에서도 실행할 수 있지만 `sudo` 사용 권한이 필요합니다.

4. 프롬프트 없이 자동 진행하려면 원하는 버전을 인자와 함께 전달할 수 있습니다.
   ```sh
   ./k8s_auto_install.sh \
     --k8s-version 1.32 \
     --crio-version 1.32 \
     --cilium-version 1.15.6 \
     --yes
   ```

## Single Node에서 Kubernetes 설치
Single Node에서 Kubernetes를 설치할 경우, Master Node가 Worker Node 역할 또한 수행할 수 있도록 아래 명령을 통해 Taint를 제거해야합니다.
```sh
kubectl taint nodes --all node-role.kubernetes.io/control-plane-
```

## 레거시 스크립트
기존 Master/Worker 분리 스크립트는 `legacy/` 디렉터리로 이동되었습니다.

## 추가
- 2024.06.12: Snapshot 전용 자동설치 파일 추가
- 2024.07.24: Master, Worker로 Installer 명칭 변경 및 최적화
- 2024.07.26: Repository 이름 변경
- 2024.08.08: Bash Completion 설치 기능 추가 및 코드 최적화
- 2024.09.26: Forwarding IPv4 and letting iptables see bridged traffic 설정 누락으로 인한 에러 발생 확인[수정]
- 2024.12.02: Shell 진행사항 보일 수 있도록 초록 문구로 강조 추가(Master, Worker 포함)
- 2025.10.22: CRI-O 기반 통합 설치 스크립트로 업데이트 및 버전 선택 기능 추가
