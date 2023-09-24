#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" > /dev/null && pwd )"

sudo docker build -t devbox:latest ${DIR}
