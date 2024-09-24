# リポジトリのURL
REPO_URL = git@github.com:AUTOMATIC1111/stable-diffusion-webui.git

# クローン先のディレクトリ名
CLONE_DIR = automatic1111

# SSHキー関連
SSH_KEY_PATH = ~/.ssh/id_rsa_github
SSH_CONFIG_PATH = ~/.ssh/config
SSH_HOST_ALIAS = github github.com
GITHUB_HOST = github.com

# デフォルトのターゲット
prepare: setup_ssh install_git
build: clone install_docker install_nvidia_driver configure_nvidia_runtime restart_system

# SSHキー作成ターゲット
setup_ssh:
	@echo "Checking if SSH key exists..."
	@if [ -f "$(SSH_KEY_PATH)" ]; then \
		echo "SSH key already exists at $(SSH_KEY_PATH). Skipping key generation."; \
	else \
		echo "Generating new SSH key..."; \
		ssh-keygen -t rsa -b 4096 -f $(SSH_KEY_PATH) -N ""; \
		echo "SSH key generated at $(SSH_KEY_PATH)."; \
	fi
	@echo "Checking if SSH config contains GitHub information..."
	@if grep -q "$(SSH_HOST_ALIAS)" $(SSH_CONFIG_PATH); then \
		echo "GitHub SSH config already exists. Skipping config addition."; \
	else \
		echo "Adding GitHub SSH config to $(SSH_CONFIG_PATH)..."; \
		echo "\nHost $(SSH_HOST_ALIAS)\n  HostName $(GITHUB_HOST)\n  IdentityFile $(SSH_KEY_PATH)\n  User git\n" >> $(SSH_CONFIG_PATH); \
		echo "GitHub SSH config added."; \
	fi

# Gitインストールターゲット
install_git:
	@echo "Checking if Git is installed..."
	@if [ -x "$$(command -v git)" ]; then \
		echo "Git is already installed. Skipping installation."; \
	else \
		echo "Git not found. Installing Git..."; \
		sudo apt-get update && sudo apt-get install -y git; \
		echo "Git installation completed."; \
	fi

# クローンを実行するターゲット
clone:
	@echo "Cloning repository..."
	@if [ -d "$(CLONE_DIR)" ]; then \
		echo "Directory $(CLONE_DIR) already exists. Skipping clone."; \
	else \
		git clone $(REPO_URL) $(CLONE_DIR); \
	fi
	@echo "Clone completed."

# Dockerインストールターゲット
install_docker:
	@echo "Removing any conflicting containerd packages..."
	@sudo apt-get remove -y containerd containerd.io
	@echo "Adding Docker’s official GPG key and setting up the repository..."
	@if [ ! -f /etc/apt/sources.list.d/docker.list ]; then \
		sudo apt-get update && sudo apt-get install -y ca-certificates curl gnupg lsb-release; \
		sudo mkdir -p /etc/apt/keyrings; \
		curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg; \
		echo "deb [arch=$$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $$(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null; \
	fi
	@echo "Installing Docker and containerd..."
	# リトライを含めたdpkgのインストールプロセス
	@for i in 1 2 3; do \
		sudo apt-get update && sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin && break; \
		echo "Retrying installation..."; \
		sleep 10; \
	done
	@sudo systemctl start docker
	@sudo systemctl enable docker
	@sudo usermod -aG docker ubuntu
	@echo "Docker and Docker Compose installation completed. You may need to log out and log back in for group changes to take effect."

# NVIDIAドライバのインストール
install_nvidia_driver:
	@echo "Installing NVIDIA driver 535..."
	@sudo apt-get update && sudo apt-get install -y nvidia-driver-535
	@echo "NVIDIA driver 535 installed."

# NVIDIAランタイム設定
configure_nvidia_runtime:
	@echo "Configuring Docker to use NVIDIA runtime..."
	@sudo apt-get install -y nvidia-container-runtime
	@if [ ! -f /etc/docker/daemon.json ]; then \
		echo '{ "runtimes": { "nvidia": { "path": "nvidia-container-runtime", "runtimeArgs": [] } } }' | sudo tee /etc/docker/daemon.json; \
	else \
		echo "Daemon config exists. Adding NVIDIA runtime."; \
		sudo sed -i 's/}/, "runtimes": { "nvidia": { "path": "nvidia-container-runtime", "runtimeArgs": [] } } }/' /etc/docker/daemon.json; \
	fi
	@sudo systemctl restart docker
	@echo "Docker restarted with NVIDIA runtime configuration."

# システム再起動
restart_system:
	@echo "Rebooting the system to apply NVIDIA driver..."
	@sudo reboot

# クリーンアップ用のターゲット
clean:
	@echo "Removing cloned repository..."
	@rm -rf $(CLONE_DIR)
	@echo "Cleanup completed."

# automatic1111スタート
start:
	@docker compose up

# automatic1111スタート
down:
	@docker compose down

.PHONY: all setup_ssh install_git clone install_docker install_nvidia_driver configure_nvidia_runtime restart_system clean
