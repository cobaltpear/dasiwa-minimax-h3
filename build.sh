#!/bin/sh
# DaSiWa MiniMax H3 (picture to video with sound) — everything the worker image needs. The Dockerfile in your copy downloads this file
# from the original repo on every build, so fixes made there reach you with a rebuild.
set -eu
case "${CIVITAI_TOKEN:-}" in ""|PASTE_*) echo "ERROR: set CIVITAI_TOKEN at the top of the Dockerfile" >&2; exit 1;; esac

# file <dest> <url> <sha256>
file() {
  wget -q -O "$1" "$2"
  echo "$3  $1" | sha256sum -c - || { echo "ERROR: $1 changed upstream — wait for an update of the original repo, then rebuild" >&2; exit 1; }
}

# Civitai 2877206 / version 3392061 — Hybrid v4 Turbo, int8 (20.5 GB)
file /comfyui/models/diffusion_models/dasiwa_minimax_h3_v4_turbo_int8.safetensors \
  "https://civitai.com/api/download/models/3392061?fileId=3281858&token=${CIVITAI_TOKEN}" \
  36471afb817747b711b9abad3d8e6b7c88a7c2b91b4887d040a8dcb7ee82b2d6

# Comfy-Org/MiniMax-H3 (MiniMax H3 Community License) (15.7 GB)
file /comfyui/models/text_encoders/qwen3vl_32b_minimax_h3_nvfp4_awq.safetensors \
  "https://huggingface.co/Comfy-Org/MiniMax-H3/resolve/77aac5182eb85bb20930536bac73e498bbe2bfd7/text_encoders/qwen3vl_32b_minimax_h3_nvfp4_awq.safetensors" \
  35a88d51044231fe332301d7a62aa81e3f2cba62febeb446e2c1e3e0ef76f2c6

# Comfy-Org/MiniMax-H3 (2.8 GB)
file /comfyui/models/vae/minimax_h3_video_vae_int8_convrot.safetensors \
  "https://huggingface.co/Comfy-Org/MiniMax-H3/resolve/77aac5182eb85bb20930536bac73e498bbe2bfd7/vae/minimax_h3_video_vae_int8_convrot.safetensors" \
  52a2c8c73583c86e4f41cdcce3a6ad0ea562987bc0bf3d60a0cef5f5c8e60c0e

# Comfy-Org/MiniMax-H3 (0.6 GB)
file /comfyui/models/vae/minimax_h3_audio_vae_fp32.safetensors \
  "https://huggingface.co/Comfy-Org/MiniMax-H3/resolve/77aac5182eb85bb20930536bac73e498bbe2bfd7/vae/minimax_h3_audio_vae_fp32.safetensors" \
  8e505d95dd1561d47abd43d4238fd40d9bb1ae9e147ed0a4cba778d76ae4db48

# ComfyUI 0.34.0 (base image) → 0.43.1 — for the MiniMax H3 nodes. Install into /opt/venv (the one ComfyUI actually runs with).
cd /comfyui
git fetch --depth 1 https://github.com/Comfy-Org/ComfyUI.git tag v0.43.1
git checkout -f v0.43.1
uv pip install --python /opt/venv/bin/python -r requirements.txt "transformers>=4.50.3,<5" "huggingface-hub<1.0"
timeout 300 /opt/venv/bin/python main.py --quick-test-for-ci --cpu
