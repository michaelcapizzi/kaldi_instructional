#!/usr/bin/env bash

# -p which port is open for jupyter access

port=8880

while getopts "p:" opt; do
    case ${opt} in
        p)
            port=${OPTARG}
            ;;
        \?)
            echo "Wrong flags"
            exit 1
            ;;
    esac
done

jupyter notebook --port $port --no-browser --ip=0.0.0.0 --allow-root