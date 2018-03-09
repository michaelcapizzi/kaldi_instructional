#!/bin/bash

# $1 <bool> install with GPU support?

#export HOME=$PWD/tensorflow_build/

has_gpu=$1

if [[ $has_gpu == "true" ]]; then
    tf_source=https://storage.googleapis.com/tensorflow/linux/gpu/tensorflow_gpu-1.2.0-cp27-none-linux_x86_64.whl
else
    tf_source=https://storage.googleapis.com/tensorflow/linux/cpu/tensorflow-1.2.0-cp27-none-linux_x86_64.whl
fi

pip install $tf_source
