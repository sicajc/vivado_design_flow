# Power estimation
1. Power can be reported at any stage.


## Toggle rates
1. This can be sent in with saif file for the synthesis tool to analyze and further reduce power.
2. SAIF file is better and can give a good power estimation for analysis.

```
    Data frequency = toggle rate * clock frequency
```
3. Provide accurate device and environment info
4. Supply SAIF input

5. Used in implementation.
```
    report_power_opt
    set_power_opt
    power_opt_design
```

6. Local optimization can be made on the cell you want to specify for power optimization
