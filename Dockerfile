# Use NVIDIA's CUDA image as the base for GPU support
FROM nvidia/cuda:11.7.1-cudnn8-runtime-ubuntu20.04

# Install dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    python3-dev \
    git \
    g++ \
    cmake \
    libgl1-mesa-glx \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app
COPY ./automatic1111 /app

# Install Python dependencies
RUN pip install --upgrade pip
RUN pip install --upgrade huggingface_hub
# Install the CUDA version of PyTorch
RUN pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu117
RUN pip install -r requirements.txt

# Expose the Web UI port
EXPOSE 7860

CMD ["python", "launch.py", "--share", "--listen", "--port", "7860"]
