#!/bin/bash

# Script to install LTX-Video on Ubuntu
# Tested for Ubuntu 20.04, 22.04, and later
# Requires sudo privileges and NVIDIA GPU with CUDA support
# This script was prompbed by passing the github repository URL to GROK3
# Initiall there was an error with litinfo5 not being installable and I asked grok3 to fix that
# grok3 then added in the libtinfo5 installation using a different source repo
#!/bin/bash
# Script to install LTX-Video on Ubuntu
# Tested for Ubuntu 20.04, 22.04, and later
# Requires NVIDIA GPU with CUDA support
# Minimizes sudo usage by prompting only for privileged commands

#!/bin/bash

# Script to install LTX-Video on Ubuntu
# Tested for Ubuntu 20.04, 22.04, and later
# Requires NVIDIA GPU with CUDA support
# Minimizes sudo usage by prompting only for privileged commands

# Script to install LTX-Video on Ubuntu
# Tested for Ubuntu 20.04, 22.04, and later
# Requires NVIDIA GPU with CUDA support
# Minimizes sudo usage and skips torchaudio

# Exit on any error
set -e

# Check for NVIDIA GPU and CUDA support
if ! command -v nvidia-smi >/dev/null 2>&1; then
    echo "NVIDIA GPU not detected or nvidia-smi not installed. LTX-Video requires CUDA support."
    exit 1
fi

# Detect Ubuntu version
UBUNTU_VERSION=$(lsb_release -cs)
case "$UBUNTU_VERSION" in
    "focal") CUDA_REPO="ubuntu2004" ;;
    "jammy") CUDA_REPO="ubuntu2204" ;;
    "noble") CUDA_REPO="ubuntu2404" ;;
    *)
        echo "Unsupported Ubuntu version: $UBUNTU_VERSION. Supported versions: focal (20.04), jammy (22.04), noble (24.04)."
        exit 1
        ;;
esac
echo "Detected Ubuntu version: $UBUNTU_VERSION (using CUDA repo: $CUDA_REPO)"

# Clean up existing CUDA repositories
echo "Cleaning up existing CUDA repositories..."
sudo rm -f /etc/apt/sources.list.d/cuda*.list
sudo rm -f /etc/apt/preferences.d/cuda-repository-pin-600
sudo apt-key del 3bf863cc 2>/dev/null || true
sudo apt-get update

# Update package list and install prerequisites with sudo
echo "Updating package list and installing prerequisites..."
sudo apt-get update
sudo apt-get install -y git python3 python3-venv python3-pip wget unzip
# Install libtinfo5 if missing (for nsight-systems compatibility)
if ! dpkg -l | grep -q libtinfo5; then
    echo "Installing libtinfo5..."
    sudo apt-get install -y libtinfo5 || {
        echo "Adding Ubuntu 20.04 repository for libtinfo5..."
        sudo add-apt-repository "deb http://archive.ubuntu.com/ubuntu focal main universe"
        sudo apt-get update
        sudo apt-get install -y libtinfo5
        sudo add-apt-repository -r "deb http://archive.ubuntu.com/ubuntu focal main universe"
        sudo apt-get update
    }
fi

# Install CUDA Toolkit if not already installed
CUDA_VERSION="12-2"
if ! nvcc --version | grep -q "release 12.2"; then
    echo "Installing CUDA Toolkit $CUDA_VERSION..."
    wget https://developer.download.nvidia.com/compute/cuda/repos/$CUDA_REPO/x86_64/cuda-$CUDA_REPO.pin
    sudo mv cuda-$CUDA_REPO.pin /etc/apt/preferences.d/cuda-repository-pin-600
    sudo apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/$CUDA_REPO/x86_64/3bf863cc.pub
    sudo add-apt-repository "deb https://developer.download.nvidia.com/compute/cuda/repos/$CUDA_REPO/x86_64/ /"
    sudo apt-get update
    sudo apt-get install -y cuda-toolkit-$CUDA_VERSION --no-install-recommends
fi

# Clone the LTX-Video repository as regular user
echo "Cloning LTX-Video repository..."
if [ -d "LTX-Video" ]; then
    rm -rf LTX-Video
fi
git clone https://github.com/Lightricks/LTX-Video.git
cd LTX-Video

# Create and activate a virtual environment as regular user
echo "Creating and activating virtual environment..."
rm -rf env # Ensure clean environment
python3 -m venv env || { echo "Failed to create virtual environment"; exit 1; }
if [ -f env/bin/activate ]; then
    . ./env/bin/activate || { echo "Failed to activate virtual environment"; exit 1; }
else
    echo "Virtual environment activation script not found"
    exit 1
fi

# Upgrade pip and install dependencies as regular user
echo "Installing Python dependencies..."
pip install --upgrade pip
pip install -e .[inference-script]

# Install PyTorch with CUDA support (without torchaudio)
echo "Installing PyTorch with CUDA support..."
pip install torch==2.7.0 torchvision==0.22.0 --index-url https://download.pytorch.org/whl/cu122

# Install diffusers library
echo "Installing diffusers..."
pip install -U git+https://github.com/huggingface/diffusers

# Download model checkpoints as regular user
echo "Downloading model checkpoint..."
MODEL_DIR="models/checkpoints"
mkdir -p $MODEL_DIR
wget -P $MODEL_DIR https://huggingface.co/Lightricks/LTX-Video/resolve/main/ltx-video-2b-v0.9.5.safetensors

# Download text encoder as regular user
echo "Downloading text encoder..."
TEXT_ENCODER_DIR="models/text_encoders"
mkdir -p $TEXT_ENCODER_DIR
wget -P $TEXT_ENCODER_DIR https://huggingface.co/google/t5-v1_1-xxl_encoderonly/resolve/main/t5xxl_fp16.safetensors

# Verify installation
echo "Verifying installation..."
if python -c "import torch; import diffusers; print('Dependencies installed successfully')" >/dev/null 2>&1; then
    echo "LTX-Video dependencies installed successfully."
else
    echo "Installation failed: Required Python packages not found."
    exit 1
fi

# Provide example command to run inference
echo "Installation complete! You can now run LTX-Video inference."
echo "Example command to generate a video:"
echo "python inference.py --prompt \"A lone astronaut drifts through a spaceship corridor\" --height 512 --width 704 --num_frames 121 --seed 42 --pipeline_config configs/ltxv-2b-0.9.5.yaml"

# Clean up
echo "Cleaning up temporary files..."
rm -f cuda-$CUDA_REPO.pin

echo "Setup complete! Activate the virtual environment with '. LTX-Video/env/bin/activate' to use LTX-Video."