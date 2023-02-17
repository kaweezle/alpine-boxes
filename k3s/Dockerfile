# syntax=docker/dockerfile:1.3-labs
ARG BASE_VERSION=latest
ARG BASE_IMAGE=ghcr.io/kaweezle/alpine-boxes-base
FROM ${BASE_IMAGE}:${BASE_VERSION}

USER root

RUN apk add --no-cache curl openntpd && \
     rc-update add openntpd default && \
     curl -sfL https://get.k3s.io | sed -e 's/sourcex/./g' | INSTALL_K3S_SKIP_START="true" sh -

