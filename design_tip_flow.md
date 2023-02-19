# VIVADO tips and design flow
1. Design files architecture
```
    filesets
        sources_1
            RTL src
            IPs
            designs
        constr_1
            .xdc
            constarints
        sim_1
            .sv
            testbench
```
2. Vivado activity cam simply add directories to quickly search for your file
3. So we need to partition the design project into these 3 files.

# IP management
1. Suggest MANAGE IP to manage IP in a better way
```
    report_ip_status -name ip_status_1
```

```
    upgrade_ip [get_ips sine_high]
```
2. Things can usually be automated with tcl files.
3. IPs sometimes mihgt get upgraded or changed in boards.
4. Reset all ips-> upgrade all ips -> regenerate all ips
![IP generation](/img/ip_generation_upgrade.png)

# Popular tcl commands: get_files
```
    get_files
```
-of_objects
-compile_order
-used_in
```
    set rtl_files [get_files -of_objects [get_filesets sources_1]]

```
# Report compile order
1. compile Orders can be get
```
    report_compile_order -constraints
```

```
    synth_design -rtl
```
```
    open_run synth_1 -name netlist_1
```