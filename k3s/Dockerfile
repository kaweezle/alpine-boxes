ARG BASE_VERSION=latest

FROM ghcr.io/kaweezle/alpine-boxes-base:${BASE_VERSION}

USER root

RUN apk add --no-cache curl openntpd && \
     rc-update add openntpd default && \
     curl -sfL https://get.k3s.io | sed -e 's/sourcex/./g' | INSTALL_K3S_SKIP_START="true" sh -

