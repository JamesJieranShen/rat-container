FROM ubuntu:20.04

LABEL maintainer="Will Parker <william.parker@physics.ox.ac.uk>"

# Switch default shell to bash
SHELL ["/bin/bash", "-c"]

# Create place to copy scripts to
RUN mkdir /home/scripts
COPY scripts/build-rat.sh /home/scripts
COPY scripts/setup-env.sh /home/scripts
COPY scripts/docker-entrypoint.sh /usr/local/bin/

ENV DEBIAN_FRONTEND=noninteractive

ARG SOFTWAREDIR=/home/software
RUN mkdir -p /home/software

RUN apt-get update && apt-get install -y gcc g++ gfortran \
    libssl-dev libpcre3-dev xlibmesa-glu-dev libglew1.5-dev \
    libftgl-dev libmysqlclient-dev libfftw3-dev libcfitsio-dev cppcheck \
    graphviz-dev libavahi-compat-libdnssd-dev libldap2-dev libxml2-dev libkrb5-dev \
    libgsl0-dev emacs wget git tar curl nano vim rsync strace valgrind make cmake \
    libxpm-dev libxft-dev libxext-dev libcurl4-openssl-dev libbz2-dev latex2html \
    python3 python3-dev python3-pip python3-venv python-is-python3

# Install Python packages
RUN python3 -m pip install --upgrade --no-cache-dir pip && \
    python3 -m pip install --upgrade --no-cache-dir setuptools && \
    python3 -m pip install --no-cache-dir pipx && \
    python3 -m pip install --no-cache-dir requests pytz python-dateutil \
    ipython numpy scipy matplotlib pylint

# Install SCons via pip (quicker and simpler than from source)
ARG SCONS_VERSION=3.1.2
RUN PIPX_HOME=/opt/pipx PIPX_BIN_DIR=/usr/local/bin pipx install scons==$SCONS_VERSION

# Fetch and install TensorFlow C API v1.15.0 and cppflow
ARG TENSORFLOW_VERSION=2.5.3
ARG TENSORFLOW_TAR_FILE=libtensorflow-cpu-linux-x86_64-$TENSORFLOW_VERSION.tar.gz
WORKDIR $SOFTWAREDIR
RUN wget https://storage.googleapis.com/tensorflow/libtensorflow/$TENSORFLOW_TAR_FILE && \
    tar -C /usr/local -xzf $TENSORFLOW_TAR_FILE && \
    export LIBRARY_PATH=$LIBRARY_PATH:/usr/local/lib && \
    export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib && \
    rm $TENSORFLOW_TAR_FILE && \
    git clone --single-branch https://github.com/serizba/cppflow && \
    cd cppflow && \
    git checkout 883eb4c526979dae56f921571b1ab93df85a0a0d

# Fetch and install GEANT4 from source
ARG GEANT4_VERSION=4.10.00.p04
WORKDIR $SOFTWAREDIR
RUN wget https://cern.ch/geant4-data/releases/geant$GEANT4_VERSION.tar.gz && \
    mkdir geant$GEANT4_VERSION && mkdir geant$GEANT4_VERSION-source && mkdir geant$GEANT4_VERSION-build && \
    tar zxvf geant$GEANT4_VERSION.tar.gz -C geant$GEANT4_VERSION-source --strip-components 1 && \
    cd geant$GEANT4_VERSION-build && \
    cmake -DCMAKE_INSTALL_PREFIX=../geant$GEANT4_VERSION \
    -DGEANT4_INSTALL_DATA=ON \
    -DGEANT4_BUILD_CXXSTD=c++11 \
    ../geant$GEANT4_VERSION-source && \
    make -j$(nproc) && make install && \
    cd .. && \
    rm -rf geant$GEANT4_VERSION-source && \
    rm -rf geant$GEANT4_VERSION-build && \
    rm -rf geant$GEANT4_VERSION.tar.gz

# Install ROOT 6 binary
ARG ROOT_VERSION=6.32.02
WORKDIR $SOFTWAREDIR

RUN wget https://root.cern/download/root_v$ROOT_VERSION.source.tar.gz && \
    tar xvf root_v6.32.02.source.tar.gz && \
    mv root-6.32.02 root && \
    mkdir root-build && cd root-build && \
    cmake -Droofit=ON -Dfortran=OFF -Dfftw3=ON -Dgsl=ON -Dgdml=ON -Dmathmore=ON -Dclad=OFF -Dbuiltin_tbb=OFF -Dimt=OFF  ../root && \
    make -j $(nproc) && \
    rm ../root_v$ROOT_VERSION.source.tar.gz

# Cleanup the cache to make the image smaller
RUN apt-get autoremove -y && apt-get clean -y

# Set up the environment when entering the container
WORKDIR /home
ENTRYPOINT ["docker-entrypoint.sh"]
CMD [ "/bin/bash" ]
