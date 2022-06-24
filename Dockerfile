FROM ubuntu:18.04

ARG    TURBOVNC_VERSION="2.2.1"
ENV    GUACAMOLE_HOME="/etc/guacamole"
ENV    RES "1920x1080"
ENV    DEBIAN_FRONTEND=noninteractive
ENV    export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64/bin/java

EXPOSE 8080

WORKDIR /etc/guacamole

# Install locale and set
RUN apt-get update &&            \
    apt-get install -y           \
      locales &&                 \
    apt-get clean &&             \
    rm -rf /var/lib/apt/lists/*
# Before installing desktop, set the locale to UTF-8
# see https://stackoverflow.com/questions/28405902/how-to-set-the-locale-inside-a-ubuntu-docker-container
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    locale-gen
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# Install libraries/dependencies
RUN apt-get update &&            \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
      software-properties-common \
      libjpeg-turbo8             \
      libjpeg-turbo8-dev         \
      libcairo2-dev              \
      libossp-uuid-dev           \
      libpng-dev                 \
      libpango1.0-dev            \
      libssh2-1-dev              \
      libssl-dev                 \
      libtasn1-bin               \
      libvorbis-dev              \
      libwebp-dev                \
      libpulse-dev               \

      # Install remaining dependencies, tools, and XFCE desktop
      bash-completion  \
      chromium-browser \
      gcc              \
      gcc-6            \
      make             \
      openssh-server   \
      sudo             \
      tomcat8          \
      vim              \
      wget             \
      xfce4            \
#     xfce4-goodies    \
      xauth            \
      scilab           \
      zip              \
      unzip            \
      git              \
      build-essential  \
      python3-pip      \
      curl             \

      # install libvncserver depencies
      libvncserver-dev \
      gtk2.0       

# Install gezebo - https://classic.gazebosim.org/tutorials?tut=install_ubuntu
WORKDIR /root
RUN curl -sSL http://get.gazebosim.org | sh

RUN wget --quiet http://packages.osrfoundation.org/gazebo.key -O - | apt-key add - \
	&& sh -c 'echo "deb http://packages.osrfoundation.org/gazebo/ubuntu-stable `lsb_release -sc` main" > /etc/apt/sources.list.d/gazebo-stable.list' \
	&& apt-get update \
	&& DEBIAN_FRONTEND=noninteractive apt-get -y --quiet --no-install-recommends install \
		ant \
		bc \
		#gazebo9 \
		gstreamer1.0-plugins-bad \
		gstreamer1.0-plugins-base \
		gstreamer1.0-plugins-good \
		gstreamer1.0-plugins-ugly \
		libeigen3-dev \
		#libgazebo9-dev \
		libgstreamer-plugins-base1.0-dev \
		libimage-exiftool-perl \
		libopencv-dev \
		libxml2-utils \
		protobuf-compiler \
		ignition-edifice \
	&& apt-get -y autoremove \
	&& apt-get clean autoclean \
	&& rm -rf /var/lib/apt/lists/{apt,dpkg,cache,log} /tmp/* /var/tmp/*

# Some QT-Apps/Gazebo don't not show controls without this
ENV QT_X11_NO_MITSHM 1

# Use UTF8 encoding in java tools (needed to compile jMAVSim)
ENV JAVA_TOOL_OPTIONS=-Dfile.encoding=UTF8

# Install JSBSim
RUN wget https://github.com/JSBSim-Team/jsbsim/releases/download/v1.1.1a/JSBSim-devel_1.1.1-134.bionic.amd64.deb
RUN dpkg -i JSBSim-devel_1.1.1-134.bionic.amd64.deb

# Git and Build CMake
# https://askubuntu.com/questions/1164459/how-to-install-cmake-3-14-on-ubuntu-18-04#1218867
WORKDIR /root
RUN git clone https://github.com/Kitware/CMake/
WORKDIR /root/CMake
RUN ./bootstrap && make && sudo make install

# Install required python packages
RUN pip3 install jinja2 pyyaml jsonschema empy pyros-genmsg packaging toml numpy kconfiglib

# Install Boost
RUN apt update
RUN apt install -y libignition-math4-dev
RUN apt install -y libboost-all-dev

# Update protobuf - https://github.com/uuvsimulator/uuv_simulator/issues/287
RUN apt-get install -y protobuf-compiler protobuf-c-compiler

# Install opencv - https://linuxize.com/post/how-to-install-opencv-on-ubuntu-18-04/
RUN apt install -y python3-opencv
RUN apt install -y build-essential cmake git pkg-config libgtk-3-dev \
    libavcodec-dev libavformat-dev libswscale-dev libv4l-dev \
    libxvidcore-dev libx264-dev libjpeg-dev libpng-dev libtiff-dev \
    gfortran openexr libatlas-base-dev python3-dev python3-numpy \
    libtbb2 libtbb-dev libdc1394-22-dev
RUN mkdir /root/opencv_build
WORKDIR /root/opencv_build
RUN git clone https://github.com/opencv/opencv.git
RUN git clone https://github.com/opencv/opencv_contrib.git
WORKDIR /root/opencv_build/opencv
RUN mkdir build
WORKDIR /root/opencv_build/opencv/build
RUN cmake -D CMAKE_BUILD_TYPE=RELEASE \
    -D CMAKE_INSTALL_PREFIX=/usr/local \
    -D INSTALL_C_EXAMPLES=ON \
    -D INSTALL_PYTHON_EXAMPLES=ON \
    -D OPENCV_GENERATE_PKGCONFIG=ON \
    -D OPENCV_EXTRA_MODULES_PATH=~/opencv_build/opencv_contrib/modules \
    -D BUILD_EXAMPLES=ON ..
RUN make -j8
RUN make install

# add remove opencv_build dir

# Include mavlink headers
WORKDIR /usr/local/bin
RUN git clone https://github.com/mavlink/c_library_v2.git

# Swtitch back to wd
WORKDIR /etc/guacamole

# install turbovnc
RUN wget "https://sourceforge.net/projects/turbovnc/files/${TURBOVNC_VERSION}/turbovnc_${TURBOVNC_VERSION}_amd64.deb/download" -O /opt/turbovnc.deb && \
    dpkg -i /opt/turbovnc.deb && \
    rm -f /opt/turbovnc.deb

# Download necessary Guacamole files
RUN rm -rf /var/lib/tomcat8/webapps/ROOT && \
    wget "http://apache.org/dyn/closer.cgi?action=download&filename=guacamole/1.0.0/binary/guacamole-1.0.0.war" -O /var/lib/tomcat8/webapps/ROOT.war && \
    wget "http://apache.org/dyn/closer.cgi?action=download&filename=guacamole/1.0.0/source/guacamole-server-1.0.0.tar.gz" -O /etc/guacamole/guacamole-server-1.0.0.tar.gz && \
    tar xvf /etc/guacamole/guacamole-server-1.0.0.tar.gz && \
    cd /etc/guacamole/guacamole-server-1.0.0 && \
   ./configure --with-init-dir=/etc/init.d &&   \
    make CC=gcc-6 &&                            \
    make install &&                             \
    ldconfig &&                                 \
    rm -r /etc/guacamole/guacamole-server-1.0.0*

# Create Guacamole configurations
RUN echo "user-mapping: /etc/guacamole/user-mapping.xml" > /etc/guacamole/guacamole.properties && \
    touch /etc/guacamole/user-mapping.xml

# Create user account with password-less sudo abilities
RUN useradd -s /bin/bash -g 100 -G sudo -m user && \
    /usr/bin/printf '%s\n%s\n' 'password' 'password'| passwd user && \
    echo "user ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Install Cameo
#RUN wget https://www.magicdraw.com/main.php?ts=download&cmd_download_file=8478&mirror=137&menu=download_cameo_systems_modeler&NMSESSID=9d46470c1fdcf286c5ef6e25049c5a03&c=c1a7f1439ed8809d691965224317c9a1&pr=7324
#COPY files/Cameo_Systems_Modeler_190_sp4_no_install.zip /tmp
#RUN chmod +x Cameo_Systems_Modeler_190_sp4_unix.sh
#RUN unzip /tmp/Cameo_Systems_Modeler_190_sp4_no_install.zip -d /home/user/csm
#RUN rm /tmp/Cameo_Systems_Modeler_190_sp4_no_install.zip

# Set VNC password
#RUN mkdir /home/user/.vnc && \
#    chown user /home/user/.vnc && \
#    /usr/bin/printf '%s\n%s\n%s\n' 'password' 'password' 'n' | su user -c /opt/TurboVNC/bin/vncpasswd
#RUN  echo -n 'password\npassword\nn\n' | su user -c vncpasswd

# Remove keyboard shortcut to allow bash_completion in xfce4-terminal
RUN echo "DISPLAY=:1 xfconf-query -c xfce4-keyboard-shortcuts -p \"/xfwm4/custom/<Super>Tab\" -r" >> /home/user/.bashrc

# Fix chromium-browser to run with no sandbox
RUN sed -i -e 's/Exec=chromium-browser/Exec=chromium-browser --no-sandbox/g' /usr/share/applications/chromium-browser.desktop

# enable pulse audio
RUN echo "load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" >> /etc/pulse/default.pa

# Add help message
RUN touch /etc/help-msg

# Clone PX4 repo
WORKDIR /home/user/
RUN git clone https://github.com/PX4/PX4-Autopilot.git

#Install mavlink tool chain --> https://mavlink.io/en/getting_started/installation.html
#RUN pip3 install --user future
RUN pip3 install future
RUN apt install -y python3-lxml libxml2-utils
RUN apt install -y python3-tk

# Clone mavlink
RUN git clone https://github.com/mavlink/mavlink.git --recursive
ENV PYTHONPATH="/home/user/mavlink"

# Prebuild (this will fail its ok..)
#WORKDIR /home/user/PX4-Autopilot
#RUN make px4_sitl gezebo

# Fetch qgroundcontrol
RUN wget https://d176tv9ibo4jno.cloudfront.net/latest/QGroundControl.AppImage
RUN chmod +x QGroundControl.AppImage
# To execute QGC >> ./QGroundControl.AppImage --appimage-extract-and-run

# Change folder owners
RUN chown -R user /home/user/PX4-Autopilot
RUN chown -R user /home/user/mavlink

# Clean up some permissions for user and serial ports
RUN usermod -a -G dialout user
#RUN apt-get remove modemanager

# Continue...
WORKDIR /home/user/Desktop

COPY startup.sh /startup.sh
RUN chmod +x /startup.sh

USER 1000:100

# copy and untar the default xfce4 config so that we don't get an annoying startup dialog
COPY xfce4-default-config.tgz /home/user/xfce4-default-config.tgz
RUN mkdir -p /home/user/.config/xfce4/ && \
    tar -C /home/user/.config/xfce4/ --strip-components=1 -xvzf /home/user/xfce4-default-config.tgz && \
    rm -f /home/user/xfce4-default-config.tgz

# Fix web browser panel launcher
RUN sed -i -e 's/Exec=exo-open --launch WebBrowser %u/Exec=chromium-browser --no-sandbox/g' /home/user/.config/xfce4/panel/launcher-11/15389508853.desktop

ENTRYPOINT sudo -E /startup.sh
