# 425_RISC_V

This repository contains a VHDL implementation of a simple pipelined RISC-V processor for **ECSE 425: Computer Architecture**.

The project includes:
- a top-level processor with instruction and data memory
- modular ALU subcomponents for arithmetic, logic, shifts, multiply, and branches
- ModelSim testbenches for processor integration and unit-level verification
- sample assembly programs and their corresponding 32-bit binary program files

## Project Structure

### Source Files
- `src/processor.vhd`: top-level processor datapath and control
- `src/memory.vhd`: instruction/data memory model with configurable delay and waitrequest behavior
- `src/alu/alu.vhd`: ALU top-level wrapper
- `src/alu/alu_arithmetic.vhd`: add/subtract operations
- `src/alu/alu_logical.vhd`: and/or/xor/slt-style operations
- `src/alu/alu_shift.vhd`: shift operations
- `src/alu/alu_multiply.vhd`: multiply operation
- `src/alu/alu_branch.vhd`: branch comparison logic

### Testbenches
- `tests/processor_tb.vhd`: full processor integration testbench
- `tests/unit/alu_components/*.vhd`: ALU component unit tests

### Programs
- To run the integration flow, the active program should be placed in the same directory as `testbench.tcl` and named `program.txt`.

## Processor Test Flow
The integration flow uses `testbench.tcl` to:
1. compile the processor and its dependencies
2. load `program.txt` into instruction memory
3. run the simulation for `10000 ns`
4. dump register file contents to `register_file.txt`
5. dump data memory contents to `memory.txt`