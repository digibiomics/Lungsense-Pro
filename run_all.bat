cd /d "C:\Users\naffi\OneDrive\Documents\DigiBiomics\September 2026\Experiment 2"
set PYTHONIOENCODING=utf-8
set HF_HUB_OFFLINE=1
.venv_xray\Scripts\python.exe -u Infec-NonInfec\multimodal\late_fusion\scripts\03_audio_oof.py 2>&1 | .venv_xray\Scripts\python.exe Infec-NonInfec\multimodal\scripts\tee.py Infec-NonInfec\multimodal\late_fusion\logs\03_audio_oof.out