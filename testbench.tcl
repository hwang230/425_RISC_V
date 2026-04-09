# Dump the contents of the register file to a text file
proc DumpRegisterFile {outfile} {
    set fh [open $outfile w]
    for {set i 0} {$i < 32} {incr i} {
        set value [string trim [examine -radix bin sim:/processor_tb/dut/regs\\($i\\)]]
        puts $fh $value
    }
    close $fh
}

# Dump the contents of the data memory to a text file
proc DumpDataMemory {outfile} {
    set fh [open $outfile w]
    for {set i 0} {$i < 8192} {incr i} {
        set value [string trim [examine -radix bin sim:/processor_tb/dut/D_MEM/ram_block\\($i\\)]]
        puts $fh $value
    }
    close $fh
}

# Load the program instructions from a text file into the instruction memory
proc LoadProgram {infile} {
    if {![file exists $infile]} {
        error "Program file '$infile' not found"
    }

    set fh [open $infile r]
    set addr 0

    while {[gets $fh line] >= 0} {
        regsub {--.*$} $line {} line
        regsub {//.*$} $line {} line
        set line [string trim $line]

        if {$line eq ""} {
            continue
        }

        regsub -all {_} $line {} line
        if {![regexp {^[01]{32}$} $line]} {
            error "Invalid instruction format at word $addr: expected 32-bit binary string, got '$line'"
        }

        set word $line
        set path sim:/processor_tb/dut/I_MEM/ram_block\\($addr\\)

        force -deposit $path 2#$word 0
        incr addr
    }

    close $fh
}

if {[file exists work]} {
    vdel -lib work -all
}

vlib work
vmap work work

vcom ./src/memory.vhd
vcom ./src/processor.vhd
vcom ./tests/processor_tb.vhd

vsim work.processor_tb
LoadProgram program.txt
run -all

# After simulation, write the register file and data memory contents to text files
DumpRegisterFile register_file.txt
DumpDataMemory memory.txt
