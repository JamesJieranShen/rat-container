ARG SCONS_VERSION=3.1.2
ARG TENSORFLOW_VERSION=2.5.3
ARG GEANT4_VERSION=4-11.3.0
ARG ROOT_VERSION=6.32.02
ARG SOFTWAREDIR=/home/software

FROM ubuntu:20.04 AS BASE


# Switch default shell to bash
# SHELL ["/bin/bash", "-c"]

# Create place to copy scripts to
RUN mkdir /home/scripts
COPY scripts/build-rat.sh /home/scripts
COPY scripts/setup-env.sh /home/scripts
COPY scripts/docker-entrypoint.sh /usr/local/bin/

ENV DEBIAN_FRONTEND=noninteractive

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

ARG SCONS_VERSION
# Install SCons via pip (quicker and simpler than from source)
RUN PIPX_HOME=/opt/pipx PIPX_BIN_DIR=/usr/local/bin pipx install scons==$SCONS_VERSION
# Cleanup the cache to make the image smaller
RUN apt-get autoremove -y && apt-get clean -y
ARG TENSORFLOW_VERSION
ARG SOFTWAREDIR
# Fetch and install TensorFlow C API v1.15.0 and cppflow
ARG TENSORFLOW_TAR_FILE=libtensorflow-cpu-linux-x86_64-$TENSORFLOW_VERSION.tar.gz
WORKDIR $SOFTWAREDIR
RUN wget -q https://storage.googleapis.com/tensorflow/libtensorflow/$TENSORFLOW_TAR_FILE && \
    tar -C /usr/local -xzf $TENSORFLOW_TAR_FILE && \
    rm $TENSORFLOW_TAR_FILE &&
RUN git clone --single-branch https://github.com/serizba/cppflow && \
    cd cppflow && \
    git checkout 883eb4c526979dae56f921571b1ab93df85a0a0d

FROM BASE AS G4_BUILDER
LABEL maintainer="Will Parker <william.parker@physics.ox.ac.uk>"
ARG GEANT4_VERSION
ARG SOFTWAREDIR
# Fetch and install GEANT4 from source
WORKDIR $SOFTWAREDIR
RUN wget -q https://gitlab.cern.ch/geant4/geant4/-/archive/v11.3.0/geant${GEANT4_VERSION}.tar.gz && \
    mkdir geant4 && mkdir geant$GEANT4_VERSION-source && mkdir geant$GEANT4_VERSION-build && \
    tar zxvf geant$GEANT4_VERSION.tar.gz -C geant$GEANT4_VERSION-source --strip-components 1 && \
    cd geant$GEANT4_VERSION-build && \
    cmake -DCMAKE_INSTALL_PREFIX=../geant4 \
    -DGEANT4_INSTALL_DATA=ON \
    -DGEANT4_BUILD_TLS_MODEL=global-dynamic \
    ../geant$GEANT4_VERSION-source && \
    make -j$(nproc) && make install && \
    cd .. && \
    rm -rf geant$GEANT4_VERSION-source && \
    rm -rf geant$GEANT4_VERSION-build && \
    rm -rf geant$GEANT4_VERSION.tar.gz

FROM BASE AS ROOT_BUILDER
LABEL maintainer="Will Parker <william.parker@physics.ox.ac.uk>"
ARG SOFTWAREDIR
ARG ROOT_VERSION
# Install ROOT 6 binary
WORKDIR $SOFTWAREDIR
RUN wget -q https://root.cern/download/root_v$ROOT_VERSION.source.tar.gz
RUN tar xvf root_v${ROOT_VERSION}.source.tar.gz && \
    mv root-${ROOT_VERSION} root-src
RUN mkdir root-build root
WORKDIR $SOFTWAREDIR/root-build
RUN cmake -Droofit=ON -Dfortran=OFF -Dfftw3=ON -Dgsl=ON -Dgdml=ON -Dmathmore=ON -Dclad=OFF -Dbuiltin_tbb=OFF -Dimt=OFF -DCMAKE_INSTALL_PREFIX=${SOFTWAREDIR}/root ../root-src
RUN make -j "$(nproc)" && make install

FROM BASE
ARG SOFTWAREDIR
LABEL maintainer="Will Parker <william.parker@physics.ox.ac.uk>"
COPY --from=TF_BUILDER $SOFTWAREDIR/cppflow $SOFTWAREDIR/cppflow
COPY --from=G4_BUILDER $SOFTWAREDIR/geant4 $SOFTWAREDIR/geant4
COPY --from=ROOT_BUILDER $SOFTWAREDIR/root $SOFTWAREDIR/root

# Set up the environment when entering the container
WORKDIR /home
ENTRYPOINT ["docker-entrypoint.sh"]
