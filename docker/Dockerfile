ARG BASE_VERSION=latest

FROM ghcr.io/kaweezle/alpine-boxes-base:${BASE_VERSION}

USER root

RUN apk add --no-cache docker && \
    rc-update add docker default

USER alpine
