FROM --platform=linux/amd64 ubuntu:24.04 AS ubuntu-swift
RUN export DEBIAN_FRONTEND=noninteractive \
    && apt-get update \
    && apt install -y \
        build-essential \
        clang \
        curl \
        libicu-dev \
        pkg-config
RUN curl -OL https://download.swift.org/swift-5.10.1-release/ubuntu2404/swift-5.10.1-RELEASE/swift-5.10.1-RELEASE-ubuntu24.04.tar.gz \
    && tar xzf swift-5.10.1-RELEASE-ubuntu24.04.tar.gz \
    && mv swift-5.10.1-RELEASE-ubuntu24.04 /usr/share/swift \
    && rm swift-5.10.1-RELEASE-ubuntu24.04.tar.gz
ENV PATH="$PATH:/usr/share/swift/usr/bin"


FROM --platform=linux/amd64 ubuntu-swift AS plister-builder
RUN mkdir /out
# Install git.
RUN apt install -y git
# Clone repository.
WORKDIR /usr/src/app
RUN git clone https://github.com/Nosskirneh/plister
# Compile binary.
WORKDIR /usr/src/app/plister
RUN swift build --configuration release -Xswiftc -static-stdlib && mv .build/release/plister /out


FROM --platform=linux/amd64 ubuntu:24.04 AS install_name_tool-builder
RUN mkdir /out
# Install cmake and git.
RUN export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
    && apt-get update \
    && apt-get install -y \
        build-essential \
        cmake \
        g++ \
        git
# Clone repository.
WORKDIR /usr/src/app
RUN git clone https://github.com/dmikushin/install_name_tool
# Compile binary.
WORKDIR /usr/src/app/install_name_tool/build
RUN cmake .. \
    && make \
    && mv install_name_tool /out


FROM --platform=linux/amd64 ubuntu:24.04 AS plistutil-builder
RUN bash -c 'mkdir -p /out/{bin/.libs,lib}'
RUN export DEBIAN_FRONTEND=noninteractive \
    && apt-get update \
    && apt-get install -y \
        build-essential \
        checkinstall \
        git \
        autoconf \
        automake \
        libtool-bin \
        # these two should be optional for documentation or Python bindings,
        # but autogen fails if they're not installed
        doxygen \
        cython3 \
        # these are required to make autogen pass on ubuntu 24.04
        python-is-python3 \
        python3-setuptools

# Clone repository.
WORKDIR /usr/src/app
RUN git clone https://github.com/libimobiledevice/libplist.git
# Compile binary.
WORKDIR /usr/src/app/libplist
RUN ./autogen.sh \
    && make \
    && mv tools/plistutil /out/bin \
    && mv tools/.libs/plistutil /out/bin/.libs/ \
    && mv src/.libs/libplist-2.*.so* /out/lib/


FROM --platform=linux/amd64 ubuntu:24.04
# Install dependencies.
RUN apt-get update \
    && apt install -y \
        bash \
        curl \
        sudo \
        adduser

# Set the timezone (needed when theos installer installs the tzdata package).
RUN ln -snf /usr/share/zoneinfo/$CONTAINER_TIMEZONE /etc/localtime \
    && echo $CONTAINER_TIMEZONE > /etc/timezone

# Add user with sudo permission.
RUN adduser --disabled-password --gecos '' me \
    && usermod -aG sudo me \
    && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
WORKDIR /home/me
USER me

# Copy binaries from builders.
ENV PATH="$PATH:/opt/theos/bin"
COPY --from=plister-builder /out/plister /opt/theos/bin/
COPY --from=install_name_tool-builder /out/install_name_tool /opt/theos/bin/
COPY --from=plistutil-builder /out/bin/. /opt/theos/bin/
COPY --from=plistutil-builder /out/lib/. /usr/lib/x86_64-linux-gnu/

# Install theos.
# Export CI to install iOS toolchain no questions asked.
# Keep only the target SDK.
ARG SDK
ENV SDK=${SDK:-iPhoneOS11.4}
RUN export CI=1 \
    && bash -c "$(curl -fsSL https://raw.githubusercontent.com/theos/theos/master/bin/install-theos)" \
    && find theos/sdks -maxdepth 1 -type d -not -name "$SDK.sdk" ! -path theos/sdks -print0 | xargs -0 -I {} rm -rd {}

ENV THEOS="/home/me/theos"
# Install fork of theos-jailed with support for Linux.
RUN git clone --recursive https://github.com/totteCh/theos-jailed \
    && ./theos-jailed/install \
    && rm -rd theos-jailed

# Clean up the apt cache to reduce image size.
USER root
RUN rm -rf /var/lib/apt/lists/*
USER me
