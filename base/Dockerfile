# syntax=docker/dockerfile:1.3-labs
ARG ALPINE_VERSION=3.17
ARG ALPINE_IMAGE=alpine
FROM ${ALPINE_IMAGE}:${ALPINE_VERSION}


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
    git clone --quiet --depth=1 https://github.com/romkatv/powerlevel10k.git /usr/share/oh-my-zsh/custom/themes/powerlevel10k && \
    git clone --quiet --depth=1  https://github.com/zsh-users/zsh-autosuggestions "/usr/share/oh-my-zsh/custom/plugins/zsh-autosuggestions" && \
    sed -ie '/^plugins=/ s#.*#plugins=(git zsh-autosuggestions)#' /usr/share/oh-my-zsh/templates/zshrc.zsh-template && \
    sed -ie '/^ZSH_THEME=/ s#.*#ZSH_THEME="powerlevel10k/powerlevel10k"#' /usr/share/oh-my-zsh/templates/zshrc.zsh-template && \
    echo '[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh' >> /usr/share/oh-my-zsh/templates/zshrc.zsh-template

# OpenRC stuff
RUN mkdir -p /lib/rc/init.d && \
    ln -s /lib/rc/init.d /run/openrc && \
    touch /lib/rc/init.d/softlevel && \
    cp /etc/rc.conf /etc/rc.conf.orig

ADD rc.conf /etc/rc.conf

# Configure root user
USER root
RUN install -m 700 -o root -g root /usr/share/oh-my-zsh/templates/zshrc.zsh-template /root/.zshrc && \
    install --directory -o root -g root -m 0700 /root/.ssh

COPY --chown=root:root ./p10k.zsh /root/.p10k.zsh


# Add user alpine
RUN adduser -s /bin/zsh -g alpine -D alpine && \
    addgroup alpine wheel && \
    echo "permit nopass keepenv :wheel" >> /etc/doas.d/doas.conf

# Configure user alpine
USER alpine

RUN install -m 700 -o alpine -g alpine /usr/share/oh-my-zsh/templates/zshrc.zsh-template /home/alpine/.zshrc && \
    install --directory -o alpine -g alpine -m 0700 /home/alpine/.ssh 

COPY --chown=alpine:alpine ./p10k.zsh /home/alpine/.p10k.zsh

# Run shell by default. Allows using the docker image
CMD /bin/zsh
