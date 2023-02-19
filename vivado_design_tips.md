# Basic Vivado flow
1. scripts.tcl can be runned in vivado
2. Use File open journal to view the command you have used recently, script can be generated from here.
3. ``` [file normalise]``` helps you change the directory right slash into left slash automatically.

```
    set workdir {F:\Vivado\}
    set workdir [file normalize $workdir]
```
4. vivado tcl shell can be opened to run in simply shell

# IP usage in Vivado
1. In project mode, we can add .xci and .dcp IP files into the project


# XSim RTL simulation
1. xsim.ini tells you where your files in simulation comes.
2. VCD dumping is possible.
3. Scopes, objects and signals in xsim.
4. Waveform configuration can also be saved for future use.
5. Signal colours can also be used for better debug visualization
6. To analyze the time of signals, use markers.
7. Actually we can open new Waveforms viewers to display even more signals at the same time!!!! I dont know this~

```
    current_scope
    current_object
```

```
    set myobj [get_objects objects]

```
## Dump waveform in vivado
1. log_wave $my_obj
2. restart
3. This enables us to display signals using commands
4. restart, run command can be keyed into vivado shell.

# Synthesis
1. .xdc file can be used in synthesis
2. launch_run synthsis1
3. must learn scripting for design automation.

## Set out of context module
1. Uncheck I/O buffers, they would then generated their own .dcp files. This enbales independent syntesis of modules
## hierarchy
1. Which breaks modules hierarchy, these can be set in command line or gui
```
    -flatten_hierarchy -none
                       -full
                       -Rebuilt
```
## No LUT combining
1. LUT gets shared, which might leads to some problems if too many LUT combine exits.

```
    -no_lc
```

## (*srl_style = "register" *)
1. This command enables implementation of SRL using the built in LUT in vivado
2. SRL is a basic component in fpga.

```verilog
(*srl_style = "register" *)reg[4:0] match_index;

```
## When using srl_style?
1. Better area and better performance.
2. reg_srl_reg enables higher performance!

## ram_style & rom_style
1. This guide fpga to use RAM block and ROM block for your design.
```verilog
(*ram_style = "distributed" *) reg [BYTE-1:0] str_B_ram[0:STR_LENGTH-1];
(*rom_style = "distributed" *) reg [BYTE-1:0] pattern_B_rom[0:PATTERN_LENGTH-1];

```

## use_dsp48
1. Tells the design tools to use dsp_48 blocks on fpga.
2. The arithmetic needed dsp_48 are as the following.
- Mult
- Mult-add & mult-sub
- Mult-accumulate
3. Adders,Sub,accumulators are implemented with fabric instead of DSP48 blocks.
4. However, we can also let add,sub,accumulators to use dsp_48 instead, to release some area and enables adders and subtractors of this type to gain even higher performance.

```verilog
(* dsp_48 *)wire[31:0] multiply_out;

```

## black_box
1. This turns a whole hierarchy into a black box for the module or entity.
```verilog
(* black_box *) module test(in1,in2,in3);
```

## dont_touch
1. dont_touch prevents vivado from optimization the circuits
```verilog
(* dont_touch = "true" *) sig1;
assign sig1 & sig2;
```
## fsm_encoding
1. This enbales other encoding for your design on FPGA. Possible encoding scheme are one_hot, sequential, johnson, gray or auto.
```verilog
(*fsm_encoding = "one_hot" *)reg [3:0] l1_curState,l1_nxtState,l2_curState,l2_nxtState;

```
2. To see the result, look at the file of your verilog in the message window.

# Multiple runs in Vivado
1. Creating and manage multiple runs in Vivado
2. Enables different constraint on different parts with different strategy.
3. current_run [get_runs synth1_1]
4. delete_run synth_2

# Message management
1. We can use filters in message info
2. Grouping info and discarding infos in message window.

# Implementation
## Directives
1. Use different implementation algorithm to help you build your design onto fpga.
2. Alternative implementation strategy can be used to save your time.
3. help -opt to find all possible options
## P&R

-effort level high.
```
    -directive Explore
```
-effort level medium
```
    -directive Default
```

-effor_levellow
```
    -directive RuntimeOptimized
```

-effort_level quick
```
    -directive Quick
```
# Implementation strategies
1. You can select strategis, performance, area,power,flow,congestion.
- performance_explore
- area_explore
- power_defaultopt
- flow_runphysopt
- congestion_spreadlogic_high
2. Different strategy has different directives, user defined strategy can be used.
3. Performance_Explore can be used if you cannot meet your goals in timing or area.

# TCL API
1. .tcl pre, the tcl file you want to run before implementaion design
2. .tcl post, the tcl you want to run after implementaion design

## physical optimization can also be optimized.

## Incremental APR flow on FPGA
1. Enables faster implementation if the change is not too much on your design.