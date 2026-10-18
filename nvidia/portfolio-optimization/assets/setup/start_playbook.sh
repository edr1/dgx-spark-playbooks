#!/bin/bash
set -euo pipefail

# Get the script's directory, handling symlinks and different invocation methods
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
PARENT_DIR="${SCRIPT_DIR%/*}"
# Print the location
echo "Starting container with volumized data folder at: $PARENT_DIR"

IMAGE="nvcr.io/nvidia/rapidsai/notebooks:25.10-cuda13-py3.13"
CACHE_VOLUME="portfolio-optimization-uv-cache"

# Keep completed package downloads when the disposable notebook container exits.
# Initialize ownership for the image's non-root user before mounting the cache.
docker pull "$IMAGE"
docker run --rm --user root --entrypoint bash \
    -v "$CACHE_VOLUME:/cache" "$IMAGE" \
    -c 'chown "$(id -u rapids):$(id -g rapids)" /cache'

docker run --gpus all --rm -it \
    --shm-size=1g --ulimit memlock=-1 --ulimit stack=67108864 \
    -p 8888:8888 -p 8787:8787 -p 8786:8786 -p 8501:8501 -p 8050:8050 \
    -e UV_HTTP_TIMEOUT="${UV_HTTP_TIMEOUT:-600}" \
    -e UV_CONCURRENT_DOWNLOADS="${UV_CONCURRENT_DOWNLOADS:-4}" \
    -e UV_CACHE_DIR=/home/rapids/uv-cache \
    -v "$CACHE_VOLUME:/home/rapids/uv-cache" \
    -v "$PARENT_DIR:/home/rapids/notebooks/playbook" \
    "$IMAGE" bash /home/rapids/notebooks/playbook/setup/setup_playbook.sh
