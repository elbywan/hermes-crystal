#/bin/bash

env LLVM_CONFIG=/usr/local/Cellar/llvm@8/8.0.1/bin/llvm-config \
crystal lib/crystal_lib/src/main.cr -- gen/libsnips_hermes.cr \
# > ./src/bindings/bindings.cr