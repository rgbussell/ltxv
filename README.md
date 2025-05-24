# LTXV

A package for generating video from image or text prompts.

## Overview

LTXV is a generative model with a diffusion transformer architecture that can create videos from prompts.

## Requirements

- Python 3.10.5
- CUDA 12.2
- PyTorch > 2.1.2

## Setup

Initial setup attempts:
- `setup_claude_prompted.sh` - Used Claude 4 for guidance (note: did not install torch correctly)
- `setup_grok3_prompted.sh`

## Troubleshooting

### Memory Issues


#### System RAM Limitations

When creating a video, encountered the following error:

```
RuntimeError: unable to mmap 28579183444 bytes from file <MODEL_DIR/ltxv-13b-0.9.7-distilled.safetensors>: Cannot allocate memory (12)
```

Initial memory status:
```
$ free -h
               total        used        free      shared  buff/cache   available
Mem:            15Gi       6.1Gi       1.5Gi       1.1Gi       9.2Gi       9.2Gi
Swap:          4.0Gi       768Ki       4.0Gi

$ swapon --show
NAME      TYPE SIZE USED PRIO
/swap.img file   4G 768K   -2
```

Increasing swap space:
```bash
$ sudo swapoff -a  # Disable existing swap
$ sudo fallocate -l 32G /swapfile
$ sudo chmod 600 /swapfile
$ sudo mkswap /swapfile
$ sudo swapon /swapfile
```

Making swap persistent:
```bash
$ echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

Verification:
```bash
$ free -h
               total        used        free      shared  buff/cache   available
Mem:            15Gi       6.1Gi       1.5Gi       1.2Gi       9.2Gi       9.2Gi
Swap:           31Gi          0B        31Gi
```

#### Hardware Specifications

Current memory configuration (from `sudo dmidecode -t memory`):
- Maximum Capacity: 256 GB
- Currently installed: Two 8GB DDR5 modules (Samsung M323R1GB4PB0-CWMOL)
- Current configuration: 16GB total with two empty slots

#### GPU Memory Limitations

Even with sufficient swap space, encountered GPU memory errors:

```
torch.OutOfMemoryError: CUDA out of memory. Tried to allocate 128.00 MiB. GPU 0 has a total capacity of 7.63 GiB of which 37.19 MiB is free. Including non-PyTorch memory, this process has 7.47 GiB memory in use. Of the allocated memory 7.38 GiB is allocated by PyTorch, and 360.00 KiB is reserved by PyTorch but unallocated. If reserved but unallocated memory is large try setting PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True to avoid fragmentation.
```

Attempted solutions:

1. Tried smaller model:
```bash
$ python inference.py --prompt "A lone astronaut drifts through a spaceship corridor" --height 512 --width 704 --num_frames 121 --seed 42 --pipeline_config configs/ltxv-2b-0.9.5.yaml
```

2. Set PyTorch memory configuration:
```bash
$ export PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True
```

3. Reduced resolution to 64x64 with 2B parameter model

**Conclusion:** Even with optimizations, the model is not runnable on 8GB RTX 3080. Consider trying Q8 LTX-video repo for quantized models that may work on smaller devices.
