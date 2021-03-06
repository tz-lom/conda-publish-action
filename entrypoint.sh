#!/bin/bash

set -ex
set -o pipefail

go_to_build_dir() {
    if [ ! -z $INPUT_SUBDIR ]; then
        cd $INPUT_SUBDIR
    fi
}

check_if_setup_file_exists() {
    if [ ! -f setup.py ]; then
        echo "setup.py must exist in the directory that is being packaged and published."
        exit 1
    fi
}

check_if_meta_yaml_file_exists() {
    if [ ! -f meta.yaml ]; then
        echo "meta.yaml must exist in the directory that is being packaged and published."
        exit 1
    fi
}

build_package(){
    # Build for Linux
    export GIT_VERSION=$(git describe --tags --abbrev=0)
    export GIT_BUILD_NUMBER=$(git rev-list  `git rev-list --tags --no-walk --max-count=1`..HEAD --count)
    conda build `echo "$INPUT_CHANNELS" | sed 's/\([^ ]\+\)/-c \1/g'` --output-folder . .

    if [[ $INPUT_PLATFORMS == *"linux"* ]]; then
    conda convert -p linux-32 linux-64/*.tar.bz2
    fi

    # Convert to other platforms: OSX, WIN
    if [[ $INPUT_PLATFORMS == *"osx"* ]]; then
    conda convert -p osx-64 linux-64/*.tar.bz2
    fi
    if [[ $INPUT_PLATFORMS == *"win"* ]]; then
    conda convert -p win-64 linux-64/*.tar.bz2
    conda convert -p win-32 linux-64/*.tar.bz2
    fi
}

upload_package(){
    if [[ $INPUT_PLATFORMS == *"osx"* ]]; then
    anaconda --token "$INPUT_ANACONDATOKEN" upload -u $INPUT_TARGET_CHANNEL osx-*/*.tar.bz2
    fi
    if [[ $INPUT_PLATFORMS == *"linux"* ]]; then
    anaconda --token "$INPUT_ANACONDATOKEN" upload -u $INPUT_TARGET_CHANNEL linux-*/*.tar.bz2
    fi
    if [[ $INPUT_PLATFORMS == *"win"* ]]; then
    anaconda --token "$INPUT_ANACONDATOKEN" upload -u $INPUT_TARGET_CHANNEL win-*/*.tar.bz2
    fi
}

check_if_setup_file_exists
go_to_build_dir
check_if_meta_yaml_file_exists
build_package
upload_package
