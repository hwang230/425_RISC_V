# ====================================================================
# Batch-Mode ModelSim/QuestaSim Tcl Script for ALU Testbenches
# ====================================================================

# 1. SET YOUR VARIABLES HERE
# Define where your source files live relative to this script
set SRC_DIR "../../../src/alu"

# Change these three variables to match the unit you want to test.
set DESIGN_FILE "alu_shift.vhd"
set TB_FILE     "alu_shift_tb.vhd"
set TB_ENTITY   "alu_shift_tb"

# 2. CREATE WORKING LIBRARY
# This creates a virtual folder called "work" where the compiled files go.
if {[file exists work]} {
    vdel -lib work -all
}
vlib work
vmap work work

# 3. COMPILE THE VHDL FILES
echo "Compiling Design..."
vcom -work work $SRC_DIR/$DESIGN_FILE

echo "Compiling Testbench..."
vcom -work work $TB_FILE

# 4. LOAD THE SIMULATION IN COMMAND-LINE MODE
# The -c flag forces the simulator to run without the graphical interface.
echo "Running Simulation..."
vsim -c work.$TB_ENTITY

# 5. EXECUTE AND QUIT
# Run it for enough time to process your wait statements, then exit.
run 100 ms