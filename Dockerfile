# syntax=docker/dockerfile:1

FROM debian:trixie-slim

ARG TARGETPLATFORM

# https://docs.docker.com/reference/dockerfile/#example-cache-apt-packages
RUN rm -f /etc/apt/apt.conf.d/docker-clean; echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
  --mount=type=cache,target=/var/lib/apt,sharing=locked \
  apt-get update && apt-get --no-install-recommends install -y \
  build-essential pkg-config ca-certificates just bison flex libssl-dev libgnutls28-dev git

COPY ./u-boot /u-boot_in_container
RUN mkdir -p /u-boot
