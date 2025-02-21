make clean
rm -rf ../tests/build/bin
rm -rf ../tests/build/dep
rm -rf ../tests/build/vmh
rm -rf ../tests/build/dump
cd ../tests/build
make clean
make
../convert
cd ../../build
make check-asm-pv2stall check-asm-pv2byp check-asm-pv2long