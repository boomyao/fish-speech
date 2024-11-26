#!/bin/bash

CUDA_ENABLED=${CUDA_ENABLED:-true}
DEVICE=""

if [ "${CUDA_ENABLED}" != "true" ]; then
    DEVICE="--device cpu"
fi

# exec python tools/webui.py ${DEVICE}
# exec python -m tools.api --listen 0.0.0.0:6200 --compile ${DEVICE}
exec python -m tools.api --listen 0.0.0.0:6200
