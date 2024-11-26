FROM python:3.12-slim-bookworm AS stage-1
ARG TARGETARCH

ARG HUGGINGFACE_MODEL=fish-speech-1.4
ARG HF_ENDPOINT=https://huggingface.co

WORKDIR /opt/fish-speech

RUN set -ex \
    && pip install huggingface_hub \
    && HF_ENDPOINT=${HF_ENDPOINT} huggingface-cli download --resume-download fishaudio/${HUGGINGFACE_MODEL} --local-dir checkpoints/${HUGGINGFACE_MODEL}

RUN set -ex \
    && pip install huggingface_hub \
    && huggingface-cli download --resume-download ResembleAI/resemble-enhance \
       --include "enhancer_stage2/hparams.yaml" \
       --include "enhancer_stage2/ds/G/latest" \
       --include "enhancer_stage2/ds/G/default/mp_rank_00_model_states.pt" \
       --local-dir checkpoints/resemble-enhance

FROM pytorch/pytorch:2.4.0-cuda12.4-cudnn9-devel
ARG TARGETARCH

ARG DEPENDENCIES="  \
    ca-certificates \
    libsox-dev \
    build-essential \
    cmake \
    libasound-dev \
    portaudio19-dev \
    libportaudio2 \
    libportaudiocpp0 \
    ffmpeg"

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    set -ex \
    && rm -f /etc/apt/apt.conf.d/docker-clean \
    && echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' >/etc/apt/apt.conf.d/keep-cache \
    && apt-get update \
    && apt-get -y install --no-install-recommends ${DEPENDENCIES} \
    && echo "no" | dpkg-reconfigure dash

WORKDIR /opt/fish-speech

COPY . .

RUN --mount=type=cache,target=/root/.cache,sharing=locked \
    set -ex \
    && pip install -e .[stable]

COPY --from=stage-1 /opt/fish-speech/checkpoints /opt/fish-speech/checkpoints

ENV GRADIO_SERVER_NAME="0.0.0.0"

# EXPOSE 7860
EXPOSE 6200

CMD ["./entrypoint.sh"]
