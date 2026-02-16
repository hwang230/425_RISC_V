proc AddWaves {} {
    ;# Add waves for the Avalon MM Interface
    add wave -position end sim:/avalon_mm_tb/clk
    add wave -position end sim:/avalon_mm_tb/reset
    add wave -position end sim:/avalon_mm_tb/op_type
    add wave -position end sim:/avalon_mm_tb/fsm_addr
    add wave -position end sim:/avalon_mm_tb/in_block
    add wave -position end sim:/avalon_mm_tb/out_block
    add wave -position end sim:/avalon_mm_tb/busy
    add wave -position end sim:/avalon_mm_tb/mem_waitrequest
    add wave -position end sim:/avalon_mm_tb/mem_readdata
    add wave -position end sim:/avalon_mm_tb/mem_addr
    add wave -position end sim:/avalon_mm_tb/mem_read
    add wave -position end sim:/avalon_mm_tb/mem_write
    add wave -position end sim:/avalon_mm_tb/mem_writedata

    ;# Internal Architecture Signals
    add wave -position end sim:/avalon_mm_tb/uut/byte_counter
    add wave -position end sim:/avalon_mm_tb/uut/tmp_busy
    add wave -position end sim:/avalon_mm_tb/uut/tmp_out_block
}

vlib work

;# Compile components
vcom ./src/avalon_bus.vhd
vcom ./tests/unit/avalon_mm_tb.vhd

;# Start simulation
vsim work.avalon_mm_tb

;# Add the waves
AddWaves

;# Run simulation
run 200ns