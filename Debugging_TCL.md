# Common TCL commands in Vivado
## Objects
1. cell,port,net,pin are naming block system of your design.
2. commonly used commands
```
    get_cells
    get_nets
    get_pins
    get_ports
    get_clocks

    -hier
    -of
    -filter
```

# Programming DEBUG
## Adding vivado debug cores
1. Using HDL instantiation model
2. Netlist Insertion Method
```
    -flatten_hierchy
     none

```
- Probing and adding IPs
3. To find target nets from HDL source code, netlist view or schematic view.
4. Adding debug core on certain wire.

```verilog
(* mark_debug = "true" *) wire[7:0] char_fifo_out;

```
## set mark_debug
1. This only works in netlist
```
    set_property mark_debug true [get_nets sine*]
```

## HDL debug
1. Use DONT TOUCH
2. get probe list
3. Generate ILA IP corse and add it to project
4. Instantiate ILA in HDL src
## dbg_hub
1. No need to care, it is automatically generated.

## VIO core
1. It can monitor signals in FPGA and Drive FPGA in fpga.
2. Generated signals are synchrounous to your design
3. Instantiated only in HDL src

## Use Tcl to debug units
1. search for it, but you can also generate the probes using tcls.

## Hardware manager
1. .bit and debug_nets.ltx:probes info is necessary

## Debug for netlist and schemetic
1. You can mark_debug in netlist
2. schematic too
3. Then setup debug to trace the signals
4. Then debug cores can be created for you.
5. Use get_debug_cores to check the generated debug cores.
```
    get_debug_cores
```
6. The debug cores define would be saved in sdc file. Debug cores inserted.
7. After implementation.
```
    open_run_impl1
```
```
    report_timing_summary
```
8. Generate bitstream, open the HW manager.
9. Later bitstream generated will contain ILA cores and main design. Later the corresponding signals can be displayed.
10. After implementing and getting your design onto FPGA, you can then trace your code.

## ILA instantiation from IP catalog
1. First you fpga command in HDL code to set up the signals you wanted to probe out.
2. Then we have to declare ILA HDL core in HDL src code.
3. From IP Catalog find ILA, setting it up
4. After selecting, run synthesis.