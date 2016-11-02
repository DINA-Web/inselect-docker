FROM debian:8.5

ENV HOME /root
ENV DEBIAN_FRONTEND noninteractive
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8
ENV TZ=Europe/Stockholm
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt-get update --fix-missing && apt-get install -y \
	python-pyside pyside-tools python-numpy python-scipy python-pip \
	python-sklearn python-opencv python-pil libdmtx-dev libzbar-dev

# browserify using noVNC
RUN apt-get update && apt-get -y install \
	xvfb \
	x11vnc \
	supervisor \
	fluxbox \
	git-core \
	git

# set display
ENV DISPLAY :0

# netstat is needed by noVNC
RUN apt-get install -y \
	net-tools \
	autocutsel

# change work directory to add novnc files
WORKDIR /root/
ADD novnc /root/novnc/


# zombie reaper "tini"
RUN apt-get install -y curl grep sed dpkg && \
    TINI_VERSION=`curl https://github.com/krallin/tini/releases/latest | grep -o "/v.*\"" | sed 's:^..\(.*\).$:\1:'` && \
    curl -L "https://github.com/krallin/tini/releases/download/v${TINI_VERSION}/tini_${TINI_VERSION}.deb" > tini.deb && \
    dpkg -i tini.deb && \
    rm tini.deb && \
    apt-get clean

# inselect installation 

RUN apt-get install -y \
	libdc1394-22-dev \
	libdc1394-22 \
	libdc1394-utils

# fix for python error reported when running "build.sh"
# src: http://stackoverflow.com/questions/31768441/how-to-persist-ln-in-docker-with-ubuntu#31798536
RUN ln /dev/null /dev/raw1394 && \
	echo 'ln /dev/null /dev/raw1394' >> ~/.bashrc

RUN cd /opt && \
	git clone --depth=1 git://libdmtx.git.sourceforge.net/gitroot/libdmtx/dmtx-wrappers && \
    cd dmtx-wrappers/python && \
    python2 setup.py install

RUN curl --progress-bar -L -o /opt/inselect.tgz \
	https://github.com/NaturalHistoryMuseum/inselect/archive/v0.1.34.tar.gz && \
	cd /opt && mkdir inselect && tar xvfz inselect.tgz --strip-components=1 -C inselect

WORKDIR /opt/inselect

# needed because requirements.pip had seveal rows with exif
# (should be removed)
COPY requirements.pip /opt/inselect
RUN pip2 install -r /opt/inselect/requirements.pip

# needed because otherwise "build.sh" would complain
RUN cd /opt/dmtx-wrappers/python && \
    python2 setup.py install

# needed because otherwise error about missing icons
RUN cd /opt/inselect && python -m bin.freeze_icons 
# && ln /dev/null /dev/raw1394 && ./build.sh && ./build.sh

# not yet used, but could be (?)
# COPY qt-settings /root/.config/inselect/qt-settings?

RUN apt-get autoclean
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
EXPOSE 8083
ENTRYPOINT [ "/usr/bin/tini", "--" ]
CMD ["/usr/bin/supervisord"]
