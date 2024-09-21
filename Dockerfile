# Ubuntu 22.04ベースのCUDAイメージを使用
FROM nvidia/cuda:11.7.1-cudnn8-runtime-ubuntu22.04

# 必要な依存関係をインストール
RUN apt-get update && apt-get install -y \
    gcc \
    python3-dev \
    git \
    g++ \
    cmake \
    libgl1-mesa-glx \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# 作業ディレクトリを設定
WORKDIR /app
COPY ./automatic1111 /app

# Pythonの依存関係をインストール
RUN pip install --upgrade pip
RUN pip install --upgrade huggingface_hub
# CUDA対応のPyTorchをインストール
RUN pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu117
RUN pip install -r requirements.txt

# Web UIのポートを公開
EXPOSE 7860

CMD ["python", "launch.py", "--share", "--listen", "--port", "7860"]
