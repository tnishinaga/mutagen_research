image := "build-container"
container := "worker"
volume := "cmake_volume"
mutagen_name := "cmake-code"
mutagen := if os_family() == "windows" { "./mutagen.exe" } else { "mutagen" }
parallel := "8"

# `just --shell powershell.exe --shell-arg -c build`

build:
    docker run -it --rm -v {{invocation_directory()}}/cmake:/cmake {{image}} bash -c "mkdir -p /cmake/build && cd /cmake/build && ../bootstrap --parallel={{parallel}} && time make -j{{parallel}}"

build_with_mutagen:
    docker run -it -d --name {{container}} --rm {{image}}
    {{mutagen}} sync create --name={{mutagen_name}} {{invocation_directory()}}/cmake docker://{{container}}/cmake
    time mutagen sync flush {{mutagen_name}}
    docker exec {{container}} bash -c "mkdir -p /cmake/build && cd /cmake/build && ../bootstrap --parallel={{parallel}} && time make -j{{parallel}}"
    {{mutagen}} sync flush {{mutagen_name}}
    docker stop {{container}}
    {{mutagen}} sync terminate {{mutagen_name}}

build_with_mutagen_using_volume:
    docker run -it -d -v {{volume}}:/cmake --name {{container}} --rm {{image}}
    {{mutagen}} sync create --name={{mutagen_name}} {{invocation_directory()}}/cmake docker://{{container}}/cmake
    time mutagen sync flush {{mutagen_name}}
    docker exec {{container}} bash -c "mkdir -p /cmake/build && cd /cmake/build && ../bootstrap --parallel={{parallel}} && time make -j{{parallel}}"
    {{mutagen}} sync flush {{mutagen_name}}
    docker stop {{container}}
    {{mutagen}} sync terminate {{mutagen_name}}

build_in_container:
    docker run -it --rm  {{image}} bash -c "mkdir -p /cmake_in_container/build && cd /cmake_in_container/build && ../bootstrap --parallel={{parallel}} && time make -j{{parallel}}"

shell:
    docker run -it --rm -v {{invocation_directory()}}/cmake:/cmake {{image}} bash

clean:
    docker stop {{container}} || true
    {{mutagen}} sync terminate {{mutagen_name}} || true
    rm -rf /cmake/build || true
    docker run -it -v {{volume}}:/cmake --name {{container}} --rm {{image}} bash -c "rm -rf /cmake/build || true" 


setup:
    bash -c 'if [ ! -e cmake ]; then git clone https://github.com/kitware/cmake --depth=1 ; fi'
    docker build -t {{image}} .
    docker volume create {{volume}}
    docker run -it -d -v {{volume}}:/cmake --name {{container}} --rm {{image}}
    {{mutagen}} sync create --name={{mutagen_name}} {{invocation_directory()}}/cmake docker://{{container}}/cmake
    {{mutagen}} sync flush {{mutagen_name}}
    docker stop {{container}}
    {{mutagen}} sync terminate {{mutagen_name}}
