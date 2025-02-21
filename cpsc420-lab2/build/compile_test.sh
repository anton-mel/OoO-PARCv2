rm -rf ../tests/build/dep
rm -rf ../tests/build/dump
cd ../tests/build
make clean
make
../convert
make check-asm-pv2stall