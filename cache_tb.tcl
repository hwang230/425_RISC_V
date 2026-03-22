proc AddWaves {} {
    ;# Add waves for the cache unit
    add wave -position end sim:/cache_tb/clock
    add wave -position end sim:/cache_tb/reset

    ;# Avalon slave interface (CPU side)
    add wave -position end sim:/cache_tb/s_addr
    add wave -position end sim:/cache_tb/s_read
    add wave -position end sim:/cache_tb/s_readdata
    add wave -position end sim:/cache_tb/s_write
    add wave -position end sim:/cache_tb/s_writedata
    add wave -position end sim:/cache_tb/s_waitrequest

    ;# Avalon master interface (RAM side)
    add wave -position end sim:/cache_tb/m_addr
    add wave -position end sim:/cache_tb/m_read
    add wave -position end sim:/cache_tb/m_readdata
    add wave -position end sim:/cache_tb/m_write
    add wave -position end sim:/cache_tb/m_writedata
    add wave -position end sim:/cache_tb/m_waitrequest

    ;# Internal Signals (add/remove based on what you actually declare)
    ;# To declare next
}

vlib work

;# Compile components
vcom ./src/cache.vhd
vcom ./tests/unit/cache_tb.vhd

;# Start simulation
vsim work.cache_tb

;# Add the waves
AddWaves

;# Run for 10000 ns
run 10000ns