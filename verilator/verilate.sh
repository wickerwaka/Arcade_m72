verilator \
-cc -exe --public --trace --savable \
--compiler msvc +define+SIMULATION=1 \
-O3 --x-assign fast --x-initial fast --noassert \
--converge-limit 6000 \
--output-split 0 \
-Wno-UNOPTFLAT \
-Wno-TIMESCALEMOD \
-Wno-COMBDLY \
-Wno-BLKANDNBLK \
-Wno-CASEX \
-Wno-WIDTH \
-Wno-CASEINCOMPLETE \
-I../zet-master/cores/zet/rtl/altera \
-I../zet-master/cores/zet/rtl \
-I../tv80 \
--top-module top m72_sim.v \
../rtl/m72.v \
../rtl/dpramv.sv \
../rtl/kna6034201.v \
../rtl/kna70h015.sv \
../rtl/kna91h014.v \
../rtl/board_b_d_layer.sv \
../rtl/board_b_d.sv \
../rtl/shifter_ls166.v \
../rtl/rom.sv \
../rtl/sound.sv \
../rtl/sprite.sv \
../rtl/pal.sv \
../rtl/pic.sv
