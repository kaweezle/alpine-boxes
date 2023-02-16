#!/usr/bin/env zsh

usage() {
    echo "oci2wsl: Create a WSL distribution from an OCI image"
    echo
    echo "Usage: oci2wsl <image> <name> <directoy>"
    echo
    exit 1
}

if [ $# -ne 3 ]; then
    usage
fi

image="$1"
name="$2"
directory="$3"

if [ ! -d "$directory" ]; then
    echo "Error! $directory is not a directory."
    usage
fi

ID=$(podman create -q $image)
if [ -z "$ID" ]; then
    echo "Error! creation of container from $image impossible."
    exit 1
fi

podman export $ID | wsl.exe --import $name $directory - 

if [ $? -ne 0 ]; then
    echo "Error! Creation of the image impossible!"
    podman rm $ID >/dev/null
    exit 1
fi

podman rm $ID >/dev/null
