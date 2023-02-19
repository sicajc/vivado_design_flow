# Timing
1. Creating basic clock period Constraints.
2. Used to check if the design meets the timing constraints.


## Organizing constraints
- timing constraints : .xdc
- physic constraints : .xdc


## Clock description
1. Clock period
2. Duty cycle
3. Phase

```
    clk0 : period = 10,waveform = {0,5}
```

```
    clk1 : period = 8, waveform = {2,8} #first posedge change in 2, first negedge change in 8.
```

## Primary clock
1. Primary clock must be defined first, timing constraints are refered to them.
```
    create_clock -period 10 [get_ports sysclk]
```

## Generate clock
1. create_generated_clock
2. automatically derievd clock