MINIFIVE: a simple (subset of) RISC-V processor
===============================================

Abstract
--------

This repository contains HDL source codes (written in VHDL) of a simple
multi-cycle processor that executes a subset of the RV32I instruction set,
developed for an educational purpose.

The processor only supports nine instructions of RV32I: `add`, `sub`,
`addi`, `and`, `andi`, `lw`, `sw`, `lui`, and `beq`. The design is deeply
inspired from a famous textbook, "Digital Design and Computer Architecture"
by Harris and Harris, yet it always executes one instruction in a fixed
number of (five) cycles for simplification of state transition.

Since 2019, I have been using this processor in my computer architecture
class. Students can run some assembly programs through logic simulation.
They can also try to implement another instruction on the processor.

-----------------------------------------------------------------------

How to Use
----------

The operation of the processor has been confirmed through logic simulation,
using <a href="http://ghdl.free.fr/">GHDL</a>, a free VHDL simulator.

Source files to be used are **all** files in the `src` and `testbench`
directories and **one of the** VHDL files in the `program` directory.
The name of entity of test bench is `MINIFIVE_TEST`.
So, analyze these files and run the simulation with the test bench as the
top module. For example, if you are going to run the `fibonacci` program,
execute GHDL twice with the following arguments:

>     GHDL -a -fexplicit --ieee=synopsys alu.vhdl decoder.vhdl regfile.vhdl signextend.vhdl minifive.vhdl program\program_fibonacci.vhdl testbench\datamemory.vhdl testbench\minifive_test.vhdl
>     GHDL -r -fexplicit --ieee=synopsys MINIFIVE_TEST --ieee-asserts=disable --stop-time=1ms

The simulation will "fail" at 10,230 ns. Since the test bench terminates
the simulation with an `assert` statement, this is an expected behavior.

NOTE: This procedure can be easily conducted using my frontend tool,
<a href="https://github.com/nfproc/GGFront">GGFront</a>.

You will find two log files, `proc_log.txt` and `dmem_dmp.txt`.
The former is the trace of executed instructions including address,
machine code, destination (register or data memory), and written data.
Destination of `x1`, `x2`, etc. correspond to the register file, while
`*(400)`, `*(404)`, etc. correspond to the data memory.

The latter is the dump of the data memory, along with the number of
executed instruction. Note that invalid (uninitialized in most cases)
words are not dumped.

-----------------------------------------------------------------------

Sample Programs
---------------

The repository includes three test programs in the `program` directory.
The program `fibonacci` calculates the 0th-19th terms of Fibonacci
sequence. The program `collatz` calculates the first (up to) 32 terms
of Collatz sequence. The program `bubblesort` conducts bubble sort of
an array with 8 elements.

You can also find a disassembly (`(program name).txt`), an instruction
trace file (`(program name)_log.txt`), and a memory dump file
(`(program name)_dmp.txt`) in the `program` directory.

-----------------------------------------------------------------------

Copyright
---------

MINIFIVE is developed by <a href="https://aitech.ac.jp/~dslab/nf/index.en.html">Naoki FUJIEDA</a>.
It is licensed under the New BSD license.
See the COPYING file for more information.

Copyright (C) 2019-2021 Naoki FUJIEDA. All rights reserved.