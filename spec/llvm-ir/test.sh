#!/bin/sh

set -euo pipefail

SCRIPT_PATH="$(realpath "$0")"
SCRIPT_ROOT="$(dirname "$SCRIPT_PATH")"

BUILD_DIR=$SCRIPT_ROOT/../../.build
crystal=$SCRIPT_ROOT/../../bin/crystal

mkdir -p $BUILD_DIR

function test() {
  echo "test: $@"

  input_cr="$SCRIPT_ROOT/$1"
  output_ll="$BUILD_DIR/${1%.cr}.ll"
  compiler_options="$2"
  check_prefix="$3"

  # $BUILD_DIR/test-ir is never used
  # pushd $BUILD_DIR + $output_ll is a workaround due to the fact that we can't control
  # the filename generated by --emit=llvm-ir
  $crystal build --single-module --no-debug --no-color --emit=llvm-ir $2 -o $BUILD_DIR/test-ir $input_cr
  FileCheck $input_cr --input-file $output_ll --check-prefix $check_prefix

  rm $BUILD_DIR/test-ir.o
  rm $output_ll
}

pushd $BUILD_DIR >/dev/null

test memset.cr "--cross-compile --target i386-apple-darwin --prelude=empty" X32
test memset.cr "--cross-compile --target i386-unknown-linux-gnu --prelude=empty" X32
test memset.cr "--cross-compile --target x86_64-apple-darwin --prelude=empty" X64
test memset.cr "--cross-compile --target x86_64-unknown-linux-gnu --prelude=empty" X64

test memcpy.cr "--cross-compile --target x86_64-apple-darwin --prelude=empty" X64
test memcpy.cr "--cross-compile --target x86_64-unknown-linux-gnu --prelude=empty" X64

popd >/dev/null
