#!/bin/bash

PLUGIN_ROOT=$(dirname "${BASH_SOURCE[0]}")/..
cd $PLUGIN_ROOT

pnpm -C fontawesome-workspace install
