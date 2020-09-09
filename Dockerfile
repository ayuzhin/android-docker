FROM ubuntu:18.04

ARG NDK_VERSION=r21d
ARG OPENSSL_VERSION=1.1.1d
ARG QT_VERSION=5.13.2
ARG SDK_BUILD_TOOLS=29.0.2
ARG SDK_PACKAGES="tools platform-tools"
ARG SDK_PLATFORM=android-21
ARG BUILD_BRANCH=develop

ENV \
    ANDROID_HOME=/opt/android-sdk \
    ANDROID_NDK_ARCH=arch-arm64 \
    ANDROID_NDK_EABI=llvm \
    ANDROID_NDK_HOST=linux-x86_64 \
    ANDROID_NDK_TOOLCHAIN_PREFIX=aarch64-linux-android \
    ANDROID_NDK_TOOLCHAIN_VERSION=4.9 \
    DEBIAN_FRONTEND=noninteractive \
    QMAKESPEC=android-clang \
    QT_PATH=/opt/qt

ENV \
    ANDROID_SDK_ROOT=${ANDROID_HOME} \
    ANDROID_NDK_PLATFORM=${SDK_PLATFORM} \
    ANDROID_NDK_ROOT=${ANDROID_HOME}/ndk-${NDK_VERSION} \
    ANDROID_NDK_TOOLS_PREFIX=${ANDROID_NDK_TOOLCHAIN_PREFIX}

ENV \
    ANDROID_DEV=${ANDROID_NDK_ROOT}/platforms/${ANDROID_NDK_PLATFORM}/${ANDROID_NDK_ARCH}/usr \
    ANDROID_NDK_TOOLCHAIN=${ANDROID_NDK_ROOT}/toolchains/${ANDROID_NDK_TOOLCHAIN_PREFIX}-${ANDROID_NDK_TOOLCHAIN_VERSION}/prebuilt/${ANDROID_NDK_HOST}

# ENV \
#     PATH=${ANDROID_NDK_TOOLCHAIN}/${ANDROID_NDK_TOOLCHAIN_PREFIX}/bin:${ANDROID_NDK_ROOT}/toolchains/${ANDROID_NDK_EABI}/prebuilt/${ANDROID_NDK_HOST}/bin:${ANDROID_HOME}/tools:${ANDROID_HOME}/tools/bin:${ANDROID_HOME}/platform-tools:${PATH}

ENV \
    PATH=${ANDROID_NDK_ROOT}/toolchains/${ANDROID_NDK_EABI}/prebuilt/${ANDROID_NDK_HOST}/bin:${ANDROID_HOME}/tools:${ANDROID_HOME}/tools/bin:${ANDROID_HOME}/platform-tools:${PATH}
  
# ENV PATH ${QT_PATH}/${QT_VERSION}/android_arm64_v8a/bin:${PATH}
ENV PATH ${QT_PATH}/${QT_VERSION}/android_armv7/bin:${PATH}
# ENV PATH ${QT_PATH}/${QT_VERSION}/android_x86/bin:${PATH}
# ENV PATH ${QT_PATH}/${QT_VERSION}/android_x86_64/bin:${PATH}

# Install updates & requirements:
#  * unzip - unpack platform tools
#  * git, openssh-client, ca-certificates - clone & build
#  * locales, sudo - useful to set utf-8 locale & sudo usage
#  * curl - to download Qt bundle
#  * make, openjdk-8-jdk-headless, ant - basic build requirements
#  * libsm6, libice6, libxext6, libxrender1, libfontconfig1, libdbus-1-3, libx11-xcb1 - dependencies of Qt bundle run-file
#  * libc6:i386, libncurses5:i386, libstdc++6:i386, libz1:i386 - dependencides of android sdk binaries
#  * patch - to apply patches
RUN dpkg --add-architecture i386 && apt update && apt full-upgrade -y && apt install -y --no-install-recommends \
    unzip \
    build-essential \
    git \
    openssh-client \
    ca-certificates \
    locales \
    sudo \
    curl \
    chrpath \
    libxkbcommon-x11-0 \
    make \
    openjdk-8-jdk-headless \
    openjdk-8-jre-headless \
    ant \
    libsm6 \
    libice6 \
    libxext6 \
    libxrender1 \
    libfontconfig1 \
    libdbus-1-3 \
    libx11-xcb1 \
    libc6:i386 \
    libncurses5:i386 \
    libstdc++6:i386 \
    libz1:i386 \
    patch \
    zip \
    p7zip-full \
    wget \
    python \
    && apt-get -qq clean \
    && rm -rf /var/lib/apt/lists/*

# Download & unpack Qt toolchain
COPY scripts/install-qt.sh /tmp/build/
RUN for tc in "android_x86_64" "android_x86" "android_armv7" "android_arm64_v8a"; do /tmp/build/install-qt.sh --version ${QT_VERSION} --directory ${QT_PATH} --target android --toolchain $tc \
      qtbase \
      qtsensors \
      qtquickcontrols2 \
      qtquickcontrols \
      qtmultimedia \
      qtlocation \
      qtimageformats \
      qtgraphicaleffects \
      qtdeclarative \
      qtandroidextras \
      qttools \
      qtimageformats \
      qtsvg; done

# Download & unpack android SDK
COPY scripts/install-android-sdk.sh /tmp/build/
RUN /tmp/build/install-android-sdk.sh

# Download & unpack android NDK
COPY scripts/install-android-ndk.sh /tmp/build/
RUN /tmp/build/install-android-ndk.sh

# # Download, build & install OpenSSL for Android
# COPY scripts/install-openssl-android-clang.sh /tmp/build/
# RUN /tmp/build/install-openssl-android-clang.sh

# Reconfigure locale
RUN locale-gen en_US.UTF-8 && dpkg-reconfigure locales \
# Add group & user, and make the SDK directory writable
    && groupadd -r user \
    && useradd --create-home --gid user user \
    && echo 'user ALL=NOPASSWD:ALL' > /etc/sudoers.d/user \
    && chown -R user:user ${ANDROID_HOME}

USER user
WORKDIR /home/user

RUN git clone --branch ${BUILD_BRANCH} https://github.com/ONLYOFFICE/build_tools.git

WORKDIR /home/user/build_tools
RUN python configure.py --branch ${BUILD_BRANCH} --update 1 --module mobile --platform android --qt-dir=${QT_PATH}/${QT_VERSION} --clean 1 --git-protocol https
RUN python make.py || true

WORKDIR /home/user/build_tools/out/
RUN zip -r /home/user/libs.zip ./*
RUN ls -al /home/user/libs.zip