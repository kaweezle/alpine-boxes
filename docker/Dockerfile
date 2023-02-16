ARG BASE_VERSION=latest

FROM ghcr.io/kaweezle/alpine-boxes-base:${BASE_VERSION}

USER root

RUN apk add --no-cache docker && \
    rc-update add docker default && \
    addgroup alpine docker

COPY ./wsl.conf /etc/wsl.conf
COPY dockeralias.ps1 /dockeralias.ps1

USER alpine

