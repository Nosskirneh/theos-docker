FROM --platform linux/amd64 ubuntu:20.04

RUN export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
    build-essential \
    make \
    fakeroot \
    perl \
    libtinfo5 \
    zstd \
    sudo \
    libedit-dev \
    binutils \
    git \
    libc6-dev \
    libcurl4 \
    libedit2 \
    libgcc-9-dev \
    libpython2.7 \
    libsqlite3-0 \
    libstdc++-9-dev \
    libxml2 \
    pkg-config \
    tzdata \
    zlib1g-dev \
    libz3-dev \
    openssh-client \
    nano \
    ca-certificates \
    curl \
    zip \
    rsync \
    libplist-utils \
    wget \
    gnupg \
    lsb-release \
    software-properties-common \
    libxml2-dev \
    ninja-build

# Install cmake
RUN wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | gpg --dearmor - | tee /etc/apt/trusted.gpg.d/kitware.gpg >/dev/null \
    && apt-add-repository "deb https://apt.kitware.com/ubuntu/ $(lsb_release -cs) main" \
    && apt update \
    && apt install -y cmake \
    && rm -rf /var/lib/apt/lists/*

RUN adduser --disabled-password --gecos '' me \
    && usermod -aG sudo me \
    && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

RUN git clone --recursive https://github.com/theos/theos /theos \
    && rm -rf /theos/sdks \
    && git clone --recursive https://github.com/theos/sdks /theos/sdks

RUN curl -#L https://github.com/kabiroberai/swift-toolchain-linux/releases/download/v2.2.1/swift-5.7-ubuntu20.04$([ "$(uname -m)" = aarch64 ] && echo -aarch64).tar.xz \
    | tar xvJ -C /theos/toolchain \
    && rm /theos/toolchain/linux/host/bin/plutil

RUN git clone --recursive https://github.com/withgraphite/plutil.git /plutil \
    && cd /plutil && make install && rm -R /plutil

ENV THEOS="/theos"
ENV PATH="${THEOS}/bin:${THEOS}/toolchain/linux/host/bin:${PATH}"
ENV THEOS_MAKE_PATH="${THEOS}/makefiles"

RUN git clone --recursive https://github.com/kabiroberai/theos-jailed /theos-jailed \
    && /theos-jailed/install

WORKDIR /home/me
USER me
