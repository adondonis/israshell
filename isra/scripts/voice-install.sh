#!/usr/bin/env bash
# voice-install.sh DIR WHISPER_TAG LLAMA_TAG -> a GPU-capable whisper-server in DIR/bin/, from prebuilt releases (any distro).
# whisper.cpp's Linux build is CPU-only, so whisper-server + libwhisper come from it and the ggml libs (incl. the
# Vulkan backend) from llama.cpp's Ubuntu Vulkan build. The two tags must share a ggml version (both 0.26.0 here).
# ggml loads backends from $ORIGIN at runtime and skips Vulkan if the system has no libvulkan, so no detection needed.
# stderr: "stage:N" then curl's progress bar, per download.
set -euo pipefail
dir=$1/bin
case $(uname -m) in
    x86_64) arch=x64 ;;
    aarch64) arch=arm64 ;;
    *) echo "unsupported CPU: $(uname -m)" >&2; exit 1 ;;
esac

fetch() {  # URL FILES...
    local url=$1
    shift
    curl -fL --progress-bar "$url" | tar -xz -C "$dir.new" --strip-components=1 --exclude='*/libggml-rpc*' --wildcards "$@"
}

rm -rf "$dir.new"
mkdir -p "$dir.new"
printf 'stage:1\r' >&2
fetch "https://github.com/ggml-org/llama.cpp/releases/download/$3/llama-$3-bin-ubuntu-vulkan-$arch.tar.gz" '*/libggml*'
printf 'stage:2\r' >&2
fetch "https://github.com/ggml-org/whisper.cpp/releases/download/$2/whisper-bin-ubuntu-$arch.tar.gz" '*/whisper-server' '*/libwhisper*'
echo "$2+$3" >"$dir.new/version"
rm -rf "$dir"
mv "$dir.new" "$dir"
