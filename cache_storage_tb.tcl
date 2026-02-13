proc AddWaves {} {
    ;# Add waves for the cache storage unit
    add wave -position end sim:/cache_storage_tb/clock
    add wave -position end sim:/cache_storage_tb/reset
    add wave -position end sim:/cache_storage_tb/index
    add wave -position end sim:/cache_storage_tb/tag
    add wave -position end sim:/cache_storage_tb/write_word
    add wave -position end sim:/cache_storage_tb/write_block
    add wave -position end sim:/cache_storage_tb/hit
    add wave -position end sim:/cache_storage_tb/data_out

    ;# Internal Signals
    add wave -position end sim:/cache_storage_tb/uut/idx
    add wave -position end sim:/cache_storage_tb/uut/data
    add wave -position end sim:/cache_storage_tb/uut/tags
    add wave -position end sim:/cache_storage_tb/uut/valid_bits
    add wave -position end sim:/cache_storage_tb/uut/dirty_bits
}

vlib work

;# Compile components
vcom ./src/cache_storage.vhd
vcom ./tests/unit/cache_storage_tb.vhd

;# Start simulation
vsim work.cache_storage_tb
;# vsim -voptargs="+acc" work.cache_storage_tb 
;# add this if the other one does not work

;# Add the waves
AddWaves

;# Run for 150 ns
run 150ns