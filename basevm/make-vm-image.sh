#!/bin/sh
#---help---
# Usage: make-vm-image.sh [options] [--] <docker-image> [<image>] 
#
# This script creates an Alpine linux VM image from an OCI image.
#
# Arguments:
#
#  <oci-image>                            The OCI image to export.
#
#  <image>                                Base name of the image. alpinevm by default.
#
# Options and Environment Variables:
#   -f --image-format IMAGE_FORMAT        Format of the disk image (see qemu-img --help).
#
#   -s --image-size IMAGE_SIZE            Size of the disk image to create in bytes or with suffix
#                                         (e.g. 1G, 1024M). Default is 2G.
#
#      --rootfs ROOTFS                    Filesystem to create on the image. Default is ext4.
#
#   -C --no-cleanup (CLEANUP)             Don't cleanup in case of error.
#
#   -h --help                             Show this help message and exit.
#
#   -v --version                          Print version and exit.
#
# Each option can be also provided by environment variable. If both option and
# variable is specified and the option accepts only one argument, then the
# option takes precedence.
#
# https://github.com/kaweezle/alpine-boxes
#---help---

set -eu

readonly PROGNAME='make-vm-image.sh'
readonly VERSION='0.0.1'

die() {
	echo -e '\e[1;31mERROR:\e[0m ' "$@" >&2  # bold red
	exit 1
}

ebegin() {
    echo -e -n '\e[s\e[1;32m* \e[0m'
    echo -e -n "$@"
    echo -e -n '...'
}

eend() {
    echo -e -n '\e[u\e[120C'
    echo -e -n '\e[7D'
    echo -e -n '\e[1;34m[ \e[0m'
    if [ $1 -eq 0 ]; then
         echo -e -n '\e[1;32mok\e[0m'
    else
         echo -e -n '\e[1;31m!!\e[0m'
    fi
    echo -e '\e[1;34m ]\e[0m'

    if [ $1 -ne 0 ]; then
        exit $1
    fi
}

help() {
	sed -En '/^#---help---/,/^#---help---/p' "$0" | sed -E 's/^# ?//; 1d;$d;'
	exit ${1:-0}
}

umount_recursively() {
	local mount_point="$1"
	test -n "$mount_point" || return 1

	cat /proc/mounts \
		| cut -d ' ' -f 2 \
		| grep "^$mount_point" \
		| sort -r \
		| xargs umount -rn
}

cleanup() {
	set +eu
	trap '' EXIT HUP INT TERM  # unset trap to avoid loop

	if [ "$mntdir" ]; then
		umount_recursively "$mntdir" \
			|| die "Failed to unmount $mntdir; unmount it and delete $root_dev manually"
		rm -Rf "$mntdir"
	fi
	if [ "$root_dev" ]; then
        losetup -d $root_dev
	fi

    [ -z "$ID" ] || docker rm $ID >/dev/null 2>&1
}



opts=$(getopt -n $PROGNAME -o f:s:hVC \
	-l image-format:,image-size:,rootfs:,help,version,no-cleanum \
	-- "$@") || help 1 >&2

eval set -- "$opts"
while [ $# -gt 0 ]; do
	n=2
	case "$1" in
		-f | --image-format) IMAGE_FORMAT="$2";;
		-s | --image-size) IMAGE_SIZE="$2";;
		     --rootfs) ROOTFS="$2";;
		-C | --no-cleanup) CLEANUP='no'; n=1;;
        -h | --help) help 0;;
		-V | --version) echo "$PROGNAME $VERSION"; exit 0;;
		--) shift; break;;
	esac
	shift $n
done

: ${CLEANUP:="yes"}
: ${IMAGE_FORMAT:="vhdx qcow2"}
: ${IMAGE_SIZE:="1G"}
: ${ROOTFS:="ext4"}
[ "$ROOTFS" = ext4 ] && mkfs_args='-O ^64bit -E nodiscard' || mkfs_args='-K'

[ $# -ne 0 ] || help 1 >&2

DOCKER_IMAGE="$1"; shift

vmname="alpinevm"

[ $# -eq 0 ] || { vmname="$1"; shift; }

[ "$CLEANUP" = no ] || trap cleanup EXIT HUP INT TERM

imgname="${vmname}.img"

[ -f $imgname ] && die "Image fille $imgname already exist."

ebegin "Creating image"
dd if=/dev/zero of=$imgname bs=${IMAGE_SIZE} count=1 >/dev/null 2>&1
eend $?

ebegin "Setting parition table"
echo "type=83,bootable" | sfdisk $imgname >/dev/null 2>&1
eend $?

root_dev=$(losetup -f)

ebegin "Creating loop device on $root_dev"
losetup -o 1048576 $root_dev $imgname
eend $?

ebegin "Creating ext4 filesystem"
mkfs.$ROOTFS -L root $mkfs_args $root_dev >/dev/null 2>&1
eend $?

# ebegin "Building docker image"
# docker buildx build -t basevm --load --quiet ./basevm >/dev/null 2>&1
# eend $?

mntdir=$(mktemp -d /tmp/$PROGNAME.XXXXXX)
uuid=$(blkid -s UUID -o value $root_dev)

ebegin "Dumping image into partition"
mount $root_dev $mntdir && \
    ID=$(docker create basevm) && \
    docker export $ID | tar x --numeric-owner -C $mntdir && \
    dd if=$mntdir/usr/share/syslinux/mbr.bin of=$imgname bs=440 count=1 conv=notrunc >/dev/null 2>&1
eend $?

ebegin "Preparing chroot"
    mount -t proc none $mntdir/proc && \
    mount --bind /dev $mntdir/dev && \
    mount --bind /sys $mntdir/sys && \
    mount --make-private $mntdir/sys && \
    mount --make-private $mntdir/dev
eend $?

ebegin "Updating boot information"
echo "UUID=$uuid / ext4 noatime 0 1" > $mntdir/etc/fstab
sed -Ei \
    -e "s|^[# ]*(root)=.*|\1=UUID=$uuid|" \
    $mntdir/etc/update-extlinux.conf && \
    chroot $mntdir mkinitfs >/dev/null 2>&1 || /bin/true && \
    chroot $mntdir extlinux --install /boot >/dev/null 2>&1 && \
    chroot $mntdir update-extlinux --warn-only >/dev/null 2>&1
eend $?

ebegin "Cleaning chroot"
cleanup
eend $?

for format in $IMAGE_FORMAT; do
    qemu_opts=""
    [ $format == "qcow" -o $format == "qcow2" ] && qemu_opts="-c"
    ebegin "Converting image to $format"
    qemu-img convert $qemu_opts $imgname -O $format ${vmname}.${format}
    eend $?
done
