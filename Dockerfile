FROM balenalib/raspberrypi3-debian:buster-build

ARG ARROW_VERSION=0.16.0

RUN install_packages \
      autoconf \
      bison \
      build-essential \
      cmake \
      curl \
      cython3 \
      flex \
      libboost-dev \
      libboost-filesystem-dev \
      libboost-regex-dev \
      libboost-system-dev \
      libgflags-dev \
      libgmock-dev \
      libgtest-dev \
      libssl-dev \
      python3-dev \
      python3-numpy \
      python3-pandas \
      python3-pip \
      python3-psutil \
      python3-pytest \
      python3-setuptools \
      python3-six \
      python3-wheel \
      rapidjson-dev \
      unzip \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /build
RUN wget https://github.com/apache/arrow/archive/apache-arrow-${ARROW_VERSION}.zip \
 && unzip apache-arrow-${ARROW_VERSION}.zip

ENV ARROW_HOME=/arrow-dist
ENV LD_LIBRARY_PATH=${ARROW_HOME}/lib:$LD_LIBRARY_PATH

WORKDIR /build/arrow-apache-arrow-${ARROW_VERSION}/cpp/release
RUN cmake -DCMAKE_INSTALL_PREFIX=${ARROW_HOME} \       
          -DCMAKE_INSTALL_LIBDIR=lib \
          -DARROW_PLASMA=ON \
          -DARROW_PYTHON=ON \
          -DPYTHON_EXECUTABLE=/usr/bin/python3 \
	  .. \
 && make -j2 \
 && make install

WORKDIR /build/arrow-apache-arrow-${ARROW_VERSION}/python
RUN PYARROW_WITH_PLASMA=1 python3 setup.py build_ext --bundle-arrow-cpp bdist_wheel \
 && cp ./dist/pyarrow-${ARROW_VERSION}-cp37-cp37m-linux_armv7l.whl ${ARROW_HOME}

# Test wheel install
WORKDIR ${ARROW_HOME}
RUN pip3 install --extra-index-url https://www.piwheels.org/simple \
      pyarrow-${ARROW_VERSION}-cp37-cp37m-linux_armv7l.whl \
  && python3 -c 'from pyarrow import compat' \
  && python3 -c 'import pyarrow.plasma as plasma'

CMD ["/bin/bash"]
