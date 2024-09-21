# リポジトリのURL
REPO_URL = git@github.com:AUTOMATIC1111/stable-diffusion-webui.git

# クローン先のディレクトリ名
CLONE_DIR = automatic1111

# SSHキー関連
SSH_KEY_PATH = ~/.ssh/id_rsa_github
SSH_CONFIG_PATH = ~/.ssh/config
SSH_HOST_ALIAS = github
GITHUB_HOST = github.com

# デフォルトのターゲット
all: setup_ssh install_git clone install_docker configure_nvidia

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
		sudo yum install git -y; \
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
	@echo "Installing Docker..."
	@sudo amazon-linux-extras install docker -y
	@sudo service docker start
	@sudo usermod -a -G docker ec2-user
	@sudo yum install docker-compose -y
	@echo "Docker and Docker Compose installation completed. You may need to log out and log back in for group changes to take effect."

# NVIDIA Container Toolkit のインストールと Docker 設定
configure_nvidia:
	@echo "Configuring Docker for NVIDIA GPU support..."
	# Install NVIDIA Container Toolkit
	@distribution=$$(. /etc/os-release;echo $$ID$$VERSION_ID) && \
	curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add - && \
	curl -s -L https://nvidia.github.io/nvidia-docker/$$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list && \
	sudo apt-get update && sudo apt-get install -y nvidia-docker2
	@echo "NVIDIA Container Toolkit installed."
	# Configure Docker to use NVIDIA runtime
	@echo "Setting NVIDIA runtime in Docker daemon.json..."
	@sudo mkdir -p /etc/docker
	@echo '{ "runtimes": { "nvidia": { "path": "nvidia-container-runtime", "runtimeArgs": [] } } }' | sudo tee /etc/docker/daemon.json
	@echo "NVIDIA runtime added to Docker."
	# Restart Docker to apply changes
	@echo "Restarting Docker service..."
	@sudo systemctl restart docker
	@echo "Docker restarted with NVIDIA GPU support."

# クリーンアップ用のターゲット
clean:
	@echo "Removing cloned repository..."
	@rm -rf $(CLONE_DIR)
	@echo "Cleanup completed."

.PHONY: all setup_ssh install_git clone install_docker configure_nvidia clean
