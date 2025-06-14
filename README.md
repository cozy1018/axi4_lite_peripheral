# AXI4-Lite Counter Peripheral

A lightweight AXI4-Lite memory-mapped peripheral module implemented in SystemVerilog.  
This module provides a simple up-counter that can be controlled and read via an AXI4-Lite interface.

---

## Features

- AXI4-Lite compliant slave interface
- Memory-mapped registers:
  - Control (`0x00`), Count (`0x04`), and Init Value (`0x08`)
- FSM-based AXI read/write logic
- Fully synthesizable and testable
- Verified with Icarus Verilog and GTKWave

---

## Register Map Summary

This peripheral exposes three memory-mapped registers:

| Address | Name       | Access | Description               |
|---------|------------|--------|---------------------------|
| `0x00`  | `CTRL`     | R/W    | Control (start/pause)     |
| `0x04`  | `COUNT`    | R      | Current counter value     |
| `0x08`  | `INIT_VAL` | W      | Initial value to load     |

**Full documentation:** [`doc/reg_map.md`](doc/reg_map.md)

---

## Project Structure
```
src/     # RTL source files
tb/      # Testbench for simulation
sim/     # Simulation outputs (.vvp, .vcd, waveform.png)
doc/     # Register map and design notes
```
---

## How to Simulate

```bash
# Compile with Icarus Verilog
iverilog -g2012 -o sim/df_counter.vvp tb/counter_tb.sv src/counter_peripheral.sv

# Run the simulation
vvp sim/df_counter.vvp

# View waveform
gtkwave