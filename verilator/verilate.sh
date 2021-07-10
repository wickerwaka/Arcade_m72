verilator \
-cc -exe --public --trace --savable \
--compiler msvc +define+SIMULATION=1 \
-O3 --x-assign fast --x-initial fast --noassert \
--converge-limit 6000 \
-Wno-UNOPTFLAT \
--top-module top centipede_sim.v \
../rtl/centipede.v \
../rtl/p6502.v \
../rtl/pokey.v \
../rtl/ram.v \
../rtl/rom.v \
../rtl/color_ram.v \
../rtl/pf_rom.v \
../rtl/pf_ram_dp.v \
../rtl/vprom.v \
../rtl/hs_ram.v