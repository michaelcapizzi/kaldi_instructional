# docker-kaldi-instructional - A simplified version of Kaldi in Docker

FROM ubuntu:16.04
MAINTAINER Michael Capizzi <mcapizzi@email.arizona.edu>

# ENV and ARG variables
ARG HOME=/scratch
ENV SHELL=/bin/bash
ENV KALDI_PATH=${HOME}/kaldi
ENV KALDI_INSTRUCTIONAL_PATH=${KALDI_PATH}/egs/INSTRUCTIONAL

# install dependencies
RUN apt-get update -qq \
 && apt-get install --no-install-recommends -y \
    graphviz \
    git \
    python \
    python3 \
    python-setuptools \
    python-numpy \
    python-dev \
    python-pip \
    tmux \
    flac \
    vim \
    ffmpeg \
    unzip \
    curl \
    g++ \
    libatlas3-base \
    zlib1g-dev \
    make \
    automake \
    autoconf \
    patch \
    bzip2 \
    wget \
    libtool \
    subversion \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# install bazel
#RUN wget https://github.com/bazelbuild/bazel/releases/download/0.5.4/bazel-0.5.4-installer-linux-x86_64.sh
#RUN chmod +x bazel-0.5.4-installer-linux-x86_64.sh && ./bazel-0.5.4-installer-linux-x86_64.sh

# update pip
RUN pip install --upgrade pip

# install jupyter kernel for bash
RUN pip install jupyter bash_kernel ; python -m bash_kernel.install

# install numpy and plotly and PyNLPl and graphviz
RUN pip install plotly pynlpl graphviz

# clone kaldi_instructional
WORKDIR ${HOME}
RUN git clone https://github.com/michaelcapizzi/kaldi.git
WORKDIR ${KALDI_PATH}
RUN git fetch && git checkout kaldi_instructional

# install kaldi-specific tools
WORKDIR ${KALDI_PATH}/tools
# irstlm
ENV IRSTLM=${KALDI_PATH}/tools/irstlm
RUN extras/install_irstlm.sh
RUN export PATH=${PATH}:${IRSTLM}/bin

# tensorflow (python)
#RUN extras/install_tensorflow_py.sh false

# tensorflow (C)
#WORKDIR ${KALDI_PATH}/tools
#RUN git clone https://github.com/tensorflow/tensorflow
#WORKDIR ${KALDI_PATH}/tools/tensorflow
#ENV TF_NEED_CUDA=1
#RUN ./configure
#RUN tensorflow/contrib/makefile/download_dependencies.sh
#RUN bazel build -c opt //tensorflow:libtensorflow.so
#RUN bazel build -c opt //tensorflow:libtensorflow_cc.so

# compile remaining tools
WORKDIR ${KALDI_PATH}/tools
RUN make

# compile kaldi source code
WORKDIR ${KALDI_PATH}/src
RUN ./configure --shared
RUN make depend
RUN make

# compile TF RNN src
#WORKDIR ${KALDI_PATH}/src/tfrnnlm
#RUN cp ${KALDI_PATH}/tools/tensorflow/tensorflow/contrib/makefile/downloads/nsync/public/nsync*.h /usr/include    # see https://github.com/tensorflow/tensorflow/issues/12482
#RUN make
#WORKDIR ${KALDI_PATH}/src/tfrnnlmbin
#RUN make

# check installations
#WORKDIR ${KALDI_PATH}/tools
#RUN extras/check_installations.sh

WORKDIR ${KALDI_INSTRUCTIONAL_PATH}
