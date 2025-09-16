FROM balenalib/raspberrypi4-64-ubuntu-node:jammy-build as builder
# LABEL io.balena.device-type="raspberrypi4-64"

RUN [ "cross-build-start" ]

RUN ln -s -f /bin/true /usr/bin/chfn
RUN mkdir -p /tmp/.X11-unix
RUN chmod 1777 /tmp/.X11-unix

RUN apt update && apt install -y xvfb xfonts-100dpi xfonts-75dpi xfonts-scalable xfonts-cyrillic
RUN apt install -y fluxbox

RUN apt-get update
RUN apt-get -y install apt-utils binutils build-essential ca-certificates pkg-config

RUN apt -y install libboost-all-dev libudev-dev libinput-dev libts-dev libmtdev-dev libjpeg-dev libfontconfig1-dev libssl-dev libdbus-1-dev \
  libglib2.0-dev libxkbcommon-dev libegl1-mesa-dev libgbm-dev libgles2-mesa-dev mesa-common-dev libasound2-dev libpulse-dev \
  libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev  gstreamer1.0-alsa libvpx-dev libsrtp2-dev libsnappy-dev \
  libnss3-dev "^libxcb.*" flex bison libxslt-dev ruby gperf libbz2-dev libcups2-dev libatkmm-1.6-dev libxi6 libxcomposite1 libfreetype6-dev \
  libicu-dev libsqlite3-dev libxslt1-dev

RUN apt -y install libavcodec-dev libavformat-dev libswscale-dev libx11-dev freetds-dev libsqlite3-dev libpq-dev libiodbc2-dev firebird-dev \
  libgst-dev libxext-dev libxcb1 libxcb1-dev libx11-xcb1 libx11-xcb-dev libxcb-keysyms1 libxcb-keysyms1-dev libxcb-image0 libxcb-image0-dev  \
  libxcb-shm0 libxcb-shm0-dev libxcb-icccm4 libxcb-icccm4-dev libxcb-sync1 libxcb-sync-dev libxcb-render-util0 libxcb-render-util0-dev \
  libxcb-xfixes0-dev libxrender-dev libxcb-shape0-dev libxcb-randr0-dev libxcb-glx0-dev libxi-dev libdrm-dev libxcb-xinerama0 \
  libxcb-xinerama0-dev libatspi2.0-dev libxcursor-dev libxcomposite-dev libxdamage-dev libxss-dev libxtst-dev libpci-dev libcap-dev \
  libxrandr-dev libdirectfb-dev libaudio-dev libxkbcommon-x11-dev

# nlohmann-json3-dev, libjansson-dev
# External dependencies to check cross compilation
RUN apt -y install ccache espeak fuse gosu kmod libespeak-dev libfontconfig1 libfuse2 libsdl2-dev locales ninja-build patchelf \
  speech-dispatcher zlib1g-dev nlohmann-json3-dev libjansson-dev libgl1-mesa-dev


RUN [ "cross-build-end" ]


FROM ubuntu:jammy

RUN ln -s -f /bin/true /usr/bin/chfn
RUN mkdir -p /tmp/.X11-unix
RUN chmod 1777 /tmp/.X11-unix

RUN apt update && apt install -y xvfb xfonts-100dpi xfonts-75dpi xfonts-scalable xfonts-cyrillic
RUN apt install -y fluxbox
RUN apt -y install sudo

# nlohmann-json3-dev, libjansson-dev
# External dependencies to check cross compilation
RUN apt update
RUN apt -y install apt-utils binutils build-essential ca-certificates cmake g++ gcc make git locales pkg-config rsync wget \
  curl mc lsb-release subversion nlohmann-json3-dev libjansson-dev glibc-source libglib2.0-dev libgl1-mesa-dev

RUN apt -y install libclang-dev clang ninja-build bison gperf libfontconfig1-dev \
  libfreetype6-dev libx11-dev libx11-xcb-dev libxext-dev libxfixes-dev libxi-dev libxrender-dev libxcb1-dev libxcb-glx0-dev \
  libxcb-keysyms1-dev libxcb-image0-dev libxcb-shm0-dev libxcb-icccm4-dev libxcb-sync-dev libxcb-xfixes0-dev libxcb-shape0-dev \
  libxcb-randr0-dev libxcb-render-util0-dev libxcb-util-dev libxcb-xinerama0-dev libxcb-xkb-dev libxkbcommon-dev libxkbcommon-x11-dev \
  libatspi2.0-dev libgl1-mesa-dev libglu1-mesa-dev freeglut3-dev

RUN apt -y install gcc-aarch64-linux-gnu g++-aarch64-linux-gnu binutils-aarch64-linux-gnu


RUN mkdir -p /sysroot/usr /sysroot/opt /sysroot/lib
COPY --from=builder /lib/ /sysroot/lib/
COPY --from=builder /usr/include/ /sysroot/usr/include/
COPY --from=builder /usr/lib/ /sysroot/usr/lib/
COPY --from=builder /opt/ /sysroot/opt/

ENV QT_MAJOR="6"
ENV QT_MINOR="6"
ENV QT_BUG_FIX="3"
ENV QT_VERSION="$QT_MAJOR.$QT_MINOR.$QT_BUG_FIX"

# I don't know why this is
COPY sysroot-relativelinks.py /usr/local/bin/
RUN chmod +x /usr/local/bin/sysroot-relativelinks.py
RUN /usr/local/bin/sysroot-relativelinks.py /sysroot

RUN apt-get update && apt-get install -y locales
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

RUN useradd -rm -d /home/user -s /bin/bash -g root -G sudo -u 1001 user
RUN echo "user ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

RUN groupadd -g 1002 data
RUN usermod -aG data user

ENV HOME /home/user
WORKDIR $HOME
USER user

RUN cd $HOME && git clone "https://codereview.qt-project.org/qt/qt5" && \
  cd qt5/ && git checkout $QT_VERSION && perl init-repository -f && cd .. && mkdir $HOME/qt-hostbuild && mkdir $HOME/qtpi-build && mkdir $HOME/qt-host && mkdir $HOME/project && mkdir $HOME/qt-raspi

RUN sudo apt install nodejs -y
RUN sudo apt install npm -y

RUN cd $HOME/qt-hostbuild && cmake ../qt5/ -GNinja -DCMAKE_BUILD_TYPE=Release -DQT_BUILD_EXAMPLES=OFF -DQT_BUILD_TESTS=OFF -DCMAKE_INSTALL_PREFIX=$HOME/qt-host && \
  cmake --build . --parallel 3 && cmake --install .

COPY toolchain.cmake $HOME
# RUN sudo apt install htop -y

RUN cd $HOME/qtpi-build && \
  ../qt5/configure -release -opengl es2 -nomake examples -nomake tests -qt-host-path $HOME/qt-host -extprefix $HOME/qt-raspi -prefix /usr/local/qt6 -device linux-rasp-pi4-aarch64 -device-option CROSS_COMPILE=aarch64-linux-gnu- -- -DCMAKE_TOOLCHAIN_FILE=$HOME/toolchain.cmake -DQT_FEATURE_xcb=ON -DFEATURE_xcb_xlib=ON -DQT_FEATURE_xlib=ON && \
  cmake --build . --parallel 3 && \
  cmake --install .

RUN rm -r $HOME/qtpi-build
RUN rm -r $HOME/qt-hostbuild

VOLUME $HOME/project
