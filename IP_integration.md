# IP integration design
1. Must first integrated you design to enable SDK usage.
2. DRC, Check and automatically connected can be used
3. make debug can also be used

# Features
1. Block automation
2. Run connection auto
3. Address editor
4. Make debug


# Flow
1. create block desgin.
2. Add IP
3. Find the IP you want to use in IP catalog
4. ZYNQ processing system can be used.
5. Block automation can later be performed.
6. Then we can add even more IP
7. BRAM controller? GPIO can all be added
8. In run connection automation, it helps us auto connect the mapping connection for block wire connections.
9. AXI intercconnections  and memory generator will all be added into your design.
10. Then set the address in the address editor, MMIO rule is being used here.
11. DRC , Validate design can be used to check if your design is compatible.
12. Debug signals can be added to help you debug wires.
13. Generate block design
14. Then we can create HDL Wrapper.
15. Later synthesis
16. In the debug line, we can see the wires selected.
17. Setup debug can used to analyze signals
18. Remember to set up clk, use the PS clock
19. Add clock domain for global clk, CLK0 used. PS CLK.
20. ILA corse need to be selected to capture control and selcted plk.
21. Run implementation to generate bit stream.
22. Later we can export hardware
23. Later launch SDK for project developing.
24. This flow can also be automated with tcl to further simplying the control flow.