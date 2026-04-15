proc ResolveArrayBase {root leafname} {
    set matches [find signals ${root}/*]
    foreach m $matches {
        if {[string match "*$leafname" $m]} {
            return $m
        }
    }
    error "Could not find signal '$leafname' under $root"
}

proc DumpRegisterFile {outfile} {
    set regs_base [ResolveArrayBase sim:/processor_tb/dut regs]
    puts "Register array found at: $regs_base"

    set fh [open $outfile w]
    for {set i 0} {$i < 32} {incr i} {
        set path "${regs_base}($i)"
        set value [string trim [examine -radix bin $path]]
        puts $fh $value
    }
    close $fh
}

proc DumpDataMemory {outfile} {
    set mem_base [ResolveArrayBase sim:/processor_tb/dut/D_MEM ram_block]
    puts "Data memory array found at: $mem_base"

    set fh [open $outfile w]
    for {set i 0} {$i < 8192} {incr i} {
        set path "${mem_base}($i)"
        set value [string trim [examine -radix bin $path]]
        puts $fh $value
    }
    close $fh
}

proc LoadProgram {infile} {
    if {![file exists $infile]} {
        error "Program file '$infile' not found"
    }

    set imem_base [ResolveArrayBase sim:/processor_tb/dut/I_MEM ram_block]
    puts "Instruction memory array found at: $imem_base"

    set fh [open $infile r]
    set addr 0

    while {[gets $fh line] >= 0} {
        regsub -- {--.*$} $line {} line
        regsub -- {//.*$} $line {} line
        set line [string trim $line]

        if {$line eq ""} {
            continue
        }

        regsub -all {_} $line {} line
        if {![regexp {^[01]{32}$} $line]} {
            error "Invalid instruction format at word $addr: expected 32-bit binary string, got '$line'"
        }

        set path "${imem_base}($addr)"
        force -deposit $path 2#$line 0
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
vcom ./src/alu/alu_arithmetic.vhd
vcom ./src/alu/alu_branch.vhd
vcom ./src/alu/alu_logical.vhd
vcom ./src/alu/alu_multiply.vhd
vcom ./src/alu/alu_shift.vhd
vcom ./src/alu/alu.vhd
vcom ./src/processor.vhd
vcom ./tests/processor_tb.vhd

vsim work.processor_tb

puts "Loading program"
LoadProgram program.txt

puts "Running simulation"
run 10000 ns

puts "PWD = [pwd]"
puts "Dumping register file"
DumpRegisterFile ./register_file.txt
puts "Dumping data memory"
DumpDataMemory ./memory.txt
