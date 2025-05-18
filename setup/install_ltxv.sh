#!/bin/bash
git clone https://github.com/Lightricks/LTX-Video.git
cd LTX-Video

python -m venv ltxv
source ltxv/bin/activate
python -m pip install -e .\[inference-script\]