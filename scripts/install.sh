#!/bin/bash
if ! [ -x "$(command -v yarn)" ]; then
    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add - &&\
        echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list &&\
        apt update &&\
        apt install -y yarn nodejs &&\
fi
yarn install
