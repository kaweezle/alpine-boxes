# syntax=docker/dockerfile:1.3-labs
ARG BASE_VERSION=latest
ARG BASE_IMAGE=ghcr.io/kaweezle/alpine-boxes-minimal
FROM ${BASE_IMAGE}:${BASE_VERSION}

ARG USERNAME=alpine
USER root

RUN apk add --no-progress --no-cache \
    alpine-base \
    less \
    logrotate \
    openssh \
    openntpd \
    acpi \
    e2fsprogs-extra \
    linux-virt \
    cloud-init \
    py3-pyserial \
    py3-netifaces \
    syslinux

RUN for s in cgroups devfs dmesg hwdrivers mdev; do ln -s /etc/init.d/$s /etc/runlevels/sysinit/$s; done \
    && \
    for s in bootmisc hostname hwclock loadkmap modules networking swap sysctl syslog termencoding; do ln -s /etc/init.d/$s /etc/runlevels/boot/$s; done \
    && \
    for s in killprocs mount-ro savecache; do ln -s /etc/init.d/$s /etc/runlevels/shutdown/$s; done \
    && \
    for s in acpid crond openntpd sshd cloud-init cloud-config cloud-final; do ln -s /etc/init.d/$s /etc/runlevels/default/$s; done \
    && \
    setup-hostname alpinevm \ 
    && \
    setup-timezone -z Europe/Paris \
    && \
    setup-keymap fr fr-azerty \
    && \
    printf '\
auto lo\n\
iface lo inet loopback\n\
\n\
auto eth0\n\
iface eth0 inet dhcp\n\
    hostname alpinevm\n\
' > /etc/network/interfaces \
    && \
    sed -e '/disable_root:/ s/true/false/' \
	    -e '/ssh_pwauth:/ s/0/no/' \
        -e '/name: alpine/a \     passwd: "*"' \
        -e '/lock_passwd:/ s/True/False/' \
        -e '/shell:/ s#/bin/ash#/bin/zsh#' \
        -i /etc/cloud/cloud.cfg \
    && \
    sed -e '/PermitRootLogin yes/d' \
        -e 's/^#PasswordAuthentication yes/PasswordAuthentication no/' \
        -e 's/^#PubkeyAuthentication yes/PubkeyAuthentication yes/' \
        -i /etc/ssh/sshd_config \
    && \
    echo "PubkeyAcceptedKeyTypes=+ssh-rsa" >> /etc/ssh/sshd_config \
    && \
    sed -Ei \
	    -e 's/^[# ](rc_depend_strict)=.*/\1=NO/' \
	    -e 's/^[# ](rc_logger)=.*/\1=YES/' \
	    -e 's/^[# ](unicode)=.*/\1=YES/' \
	    -e 's/^[# ](rc_sys)=.*/\1=""/' \
	    /etc/rc.conf \
    && \
    sed -Ei \
	    -e 's/^[# ]*(features)=.*/\1="base ext4 scsi virtio"/' \
	    /etc/mkinitfs/mkinitfs.conf \
    && \
	sed -Ei \
		-e "s|^[# ]*(default_kernel_opts)=.*|\1=\"\"|" \
		-e "s|^[# ]*(modules)=.*|\1=\"ext4\"|" \
		"$mnt"/etc/update-extlinux.conf \
    && \
    echo "iso9660" >> /etc/filesystems \
    && \
    usermod -p '*' root \
    && \
    usermod -p '*' $USERNAME

USER $USERNAME
