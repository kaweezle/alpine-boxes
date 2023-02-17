# syntax=docker/dockerfile:1.3-labs
ARG ALPINE_VERSION=3.17
ARG ALPINE_IMAGE=alpine
FROM ${ALPINE_IMAGE}:${ALPINE_VERSION}

# Add the dependencies
RUN echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing/" >> /etc/apk/repositories && \
    apk update --quiet && \
    apk add --no-progress --no-cache openrc zsh doas

# Change root shell
RUN sed -ie '/^root:/ s#:/bin/.*$#:/bin/zsh#' /etc/passwd

# Add Oh-my-zsh
RUN apk add --no-progress --no-cache --virtual ohmy git && \
    git clone --quiet --depth 1 https://github.com/ohmyzsh/ohmyzsh.git /usr/share/oh-my-zsh && \
    sed -i -e 's#^export ZSH=.*#export ZSH=/usr/share/oh-my-zsh#g' /usr/share/oh-my-zsh/templates/zshrc.zsh-template && \
    git clone --quiet --depth=1  https://github.com/zsh-users/zsh-autosuggestions "/usr/share/oh-my-zsh/custom/plugins/zsh-autosuggestions" && \
    mkdir -p /etc/skel && \
    install -m 700 -o root -g root /usr/share/oh-my-zsh/templates/zshrc.zsh-template /etc/skel/.zshrc && \
    install --directory -o root -g root -m 0700 /etc/skel/.ssh && \
    sed -ie '/^plugins=/ s#.*#plugins=(git zsh-autosuggestions)#' /etc/skel/.zshrc && \
    sed -ie '/^ZSH_THEME=/ s#.*#ZSH_THEME="amuse"#' /etc/skel/.zshrc && \
    apk del ohmy

# Configure root user
USER root
RUN install -m 700 -o root -g root /etc/skel/.zshrc /root/.zshrc && \
    install --directory -o root -g root -m 0700 /root/.ssh

# Add user 
ARG USERNAME=alpine
RUN adduser -s /bin/zsh -g $USERNAME -D $USERNAME && \
    addgroup $USERNAME wheel && \
    echo "permit nopass keepenv :wheel" >> /etc/doas.d/doas.conf

# Configure user
USER $USERNAME

# Run shell by default. Allows using the docker image
CMD /bin/zsh

