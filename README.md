# alpine-boxes

[![stability-experimental](https://img.shields.io/badge/stability-experimental-orange.svg)](https://github.com/mkenney/software-guides/blob/master/STABILITY-BADGES.md#experimental)

This repository contains the files and build tools to build Alpine Linux based
OCI images, WSL and LXC root file systems and VM images.

The base build system used is [docker buildx](https://docs.docker.com/build/).
It offers several advantages over other systems (see
[alternatives](#alternatives)):

- Layers cache
- Simple _recipe based_
- Multi-architecture (not used right now)
- Inheritance (`FROM ...`)
- Easy efficient online storage (registry)

## Why Alpine Linux ?

- Small
- Used as a base container image for many standard container images.
- Good community.
- Contrary to Systemd based systems, Alpine is based on OpenRC that plays well
  in WSL distributions (see
  [OpenRC Gentoo Documentation](https://wiki.gentoo.org/wiki/OpenRC)).

## Making root file systems from docker images

docker buildx has
[several output types](https://docs.docker.com/engine/reference/commandline/buildx_build/#output)
and one of them is `tar`, which is convenient to produce a root filesystem
suitable for import into WSL or LXC.

## Making VM images from docker images

An _almost_ bootable docker image can easily been derived from an existing
docker image (see
[this Dockerfile](https://github.com/linka-cloud/d2vm/blob/main/templates/alpine.Dockerfile)).
Then it's just a matter to dump the image filesystem in a locally mounted image
file and install a bootloader.

## Alternatives

- [Packer](https://www.packer.io/)
- [Ansible](https://www.ansible.com/)
- [distobuilder](https://github.com/lxc/distrobuilder)
- [alpine-make-vm-image](https://github.com/alpinelinux/alpine-make-vm-image)
- Makefile
- Shell scripts

## See also

- [d2vm](https://github.com/linka-cloud/d2vm)
- [docker-to-linux](https://github.com/iximiuz/docker-to-linux)
- [alpine-openstack-vm](https://github.com/antoinemartin/alpine-openstack-vm)
