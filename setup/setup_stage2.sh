# I had to run this after grok3 script failed to install torchaudio
cd /home/rbussell/repos/ltxv/setup/LTX-Video
. ./env/bin/activate
pip install torch==2.7.0 torchvision==0.22.0 --index-url https://download.pytorch.org/whl/cu122
pip install -e .[inference-script]
pip install -U git+https://github.com/huggingface/diffusers

# Check NVIDIA CUDA Compiler version
echo "Checking NVIDIA CUDA version:"
nvcc --version
