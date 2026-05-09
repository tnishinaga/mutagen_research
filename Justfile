image := "build-container"
container := "worker"
volume := "uboot_volume"
mutagen_name := "uboot-code"

build:
    docker run -it --rm -v `pwd`/u-boot:/u-boot {{image}} bash -c "cd /u-boot/ && make rpi_arm64_defconfig && time make -j 8"

build_with_mutagen:
    docker run -it -d --name {{container}} --rm {{image}}
    mutagen sync create --name={{mutagen_name}} {{invocation_directory()}}/u-boot docker://{{container}}/u-boot
    time mutagen sync flush {{mutagen_name}}
    docker exec {{container}} bash -c "cd /u-boot/ && make rpi_arm64_defconfig && time make -j 8"
    mutagen sync flush {{mutagen_name}}
    docker stop {{container}}
    mutagen sync terminate {{mutagen_name}}

build_with_mutagen_using_volume:
    docker run -it -d --mount source={{volume}},target=/u-boot --name {{container}} --rm {{image}}
    mutagen sync create --name={{mutagen_name}} {{invocation_directory()}}/u-boot docker://{{container}}/u-boot
    # time mutagen sync flush {{mutagen_name}}
    docker exec {{container}} bash -c "cd /u-boot/ && make rpi_arm64_defconfig && time make -j 8"
    mutagen sync flush {{mutagen_name}}
    docker stop {{container}}
    mutagen sync terminate {{mutagen_name}}

build_in_container:
    docker run -it --rm  {{image}} bash -c "cd /u-boot_in_container/ && make rpi_arm64_defconfig && time make -j 8"

shell:
    docker run -it --rm -v `pwd`/u-boot:/u-boot {{image}} bash

clean:
    docker stop {{container}} || true
    mutagen sync terminate {{mutagen_name}} || true
    cd u-boot/ && git clean -fdx
    docker run -it --mount source={{volume}},target=/u-boot --name {{container}} --rm {{image}} bash -c "cd /u-boot/ && git clean -fdx"


setup:
    #!/usr/bin/env -S bash -x
    if [ ! -e u-boot ]; then
        git clone https://github.com/u-boot/u-boot
    fi
    docker build -t {{image}} .
    docker volume create {{volume}}

    docker run -it -d --mount source={{volume}},target=/u-boot --name {{container}} --rm {{image}}
    mutagen sync create --name={{mutagen_name}} {{invocation_directory()}}/u-boot docker://{{container}}/u-boot
    mutagen sync flush {{mutagen_name}}
    docker exec {{container}} bash -c "cd /u-boot/ && ls"
    docker stop {{container}}
    mutagen sync terminate {{mutagen_name}}