# syntax=docker/dockerfile:1.3-labs
ARG BASE_VERSION=latest
ARG BASE_IMAGE=ghcr.io/kaweezle/alpine-boxes-base
FROM ${BASE_IMAGE}:${BASE_VERSION}

USER root

RUN apk add --no-cache podman && \
     echo alpine:100000:65536 >>/etc/subuid && \
     echo alpine:100000:65536 >>/etc/subgid

COPY ./oci2wsl.sh /usr/local/bin/oci2wsl
COPY ./dockeralias.ps1 /dockeralias.ps1
COPY ./wsl.conf /etc/wsl.conf

USER alpine
