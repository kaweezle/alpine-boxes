# syntax=docker/dockerfile:1.3-labs
ARG BASE_IMAGE=alpine:3.17
FROM $BASE_IMAGE

# TODO: move this into a base image -- start --

# Add the dependencies
RUN echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing/" >> /etc/apk/repositories && \
    apk update --quiet && \
    apk add --no-progress --no-cache openrc zsh git curl doas && \
    rm -rf `find /var/cache/apk/ -type f`

# Change root shell
RUN sed -ie '/^root:/ s#:/bin/.*$#:/bin/zsh#' /etc/passwd

# Add Oh-my-zsh
RUN git clone --quiet --depth 1 https://github.com/ohmyzsh/ohmyzsh.git /usr/share/oh-my-zsh && \
    sed -i -e 's#^export ZSH=.*#export ZSH=/usr/share/oh-my-zsh#g' /usr/share/oh-my-zsh/templates/zshrc.zsh-template && \
    git clone --quiet --depth=1  https://github.com/zsh-users/zsh-autosuggestions "/usr/share/oh-my-zsh/custom/plugins/zsh-autosuggestions" && \
    mkdir -p /etc/skel && \
    install -m 700 -o root -g root /usr/share/oh-my-zsh/templates/zshrc.zsh-template /etc/skel/.zshrc && \
    install --directory -o root -g root -m 0700 /etc/skel/.ssh && \
    sed -ie '/^plugins=/ s#.*#plugins=(git zsh-autosuggestions)#' /etc/skel/.zshrc && \
    sed -ie '/^ZSH_THEME=/ s#.*#ZSH_THEME="amuse"#' /etc/skel/.zshrc

# Configure root user
USER root
RUN install -m 700 -o root -g root /etc/skel/.zshrc /root/.zshrc && \
    install --directory -o root -g root -m 0700 /root/.ssh

# Add user alpine
RUN adduser -s /bin/zsh -g alpine -D alpine && \
    addgroup alpine wheel && \
    echo "permit nopass keepenv :wheel" >> /etc/doas.d/doas.conf

# Configure user alpine
USER alpine

# Run shell by default. Allows using the docker image
CMD /bin/zsh

# TODO: move this into a base image -- end --


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
    usermod -p '*' alpine

USER alpine
