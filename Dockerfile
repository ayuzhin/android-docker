FROM ubuntu:18.04
LABEL maintainer Ascensio System SIA <support@onlyoffice.com>

ARG NDK_VERSION=r21d
ARG QT_VERSION=5.13.2
ARG NODE_VERSION=10.x
ARG SDK_BUILD_TOOLS=29.0.2
ARG TIME_ZONE=Europe/Riga
ARG SDK_PACKAGES="tools platform-tools"
ARG SDK_PLATFORM=android-21
ARG BUILD_BRANCH=develop
ARG BUILD_CONFIG=release

ENV \
    ANDROID_HOME=/opt/android-sdk \
    DEBIAN_FRONTEND=noninteractive \
    QMAKESPEC=android-clang \
    QT_PATH=/opt/qt

ENV \
    ANDROID_SDK_ROOT=${ANDROID_HOME} \
    ANDROID_NDK_ROOT=${ANDROID_HOME}/ndk-${NDK_VERSION}

ENV \
    BASE_PATH=${PATH} \
    PATH=${ANDROID_HOME}/tools:${ANDROID_HOME}/tools/bin:${ANDROID_HOME}/platform-tools:${PATH}

RUN ln -snf /usr/share/zoneinfo/${TIME_ZONE} /etc/localtime && echo ${TIME_ZONE} > /etc/timezone

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

# Download & install NodeJS
RUN curl -sL https://deb.nodesource.com/setup_${NODE_VERSION} | sudo -E bash -
RUN sudo apt-get install -y nodejs

# Install Grunt
RUN sudo npm install -g grunt-cli

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

# Reconfigure locale
RUN locale-gen en_US.UTF-8 && dpkg-reconfigure locales \
# Add group & user, and make the SDK directory writable
    && groupadd -r user \
    && useradd --create-home --gid user user \
    && echo 'user ALL=NOPASSWD:ALL' > /etc/sudoers.d/user \
    && chown -R user:user ${ANDROID_HOME}

USER user
WORKDIR /home/user

# Reset PATH
ENV PATH=${BASE_PATH}

RUN git clone --branch ${BUILD_BRANCH} https://github.com/ONLYOFFICE/DocumentBuilder.git
RUN git clone --branch ${BUILD_BRANCH} https://github.com/ONLYOFFICE/build_tools.git

WORKDIR /home/user/build_tools
RUN python configure.py --branch ${BUILD_BRANCH} --update 1 --module mobile --platform android --qt-dir=${QT_PATH}/${QT_VERSION} --clean 1 --git-protocol https --config ${BUILD_CONFIG}
RUN python make.py || true

WORKDIR /home/user/build_tools/out/
RUN zip -r /home/user/libs.zip ./*
RUN ls -al /home/user/libs.zip