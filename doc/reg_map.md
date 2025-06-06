# Register Map: AXI4-Lite Counter Peripheral

This document describes the memory-mapped register interface for the `counter_peripheral` module using AXI4-Lite.

## Register Overview

| Offset (Hex) | Name       | Description                          | Access | Reset Value |
|--------------|------------|--------------------------------------|--------|-------------|
| 0x00         | CTRL       | Control register                     | R/W    | 0x00000000  |
| 0x04         | COUNT      | Current counter value                | R      | 0x00000000  |
| 0x08         | INIT_VAL   | Initial value for counter reset      | W      | undefined   |

## Register Descriptions

### 0x00 – CTRL Register

| Bit Range | Name     | Description                               |
|-----------|----------|-------------------------------------------|
| [0]       | enable   | 1: Start counter, 0: Pause counter         |
| [31:1]    | reserved | Reserved. Write as 0.                     |

- Writing 1 to bit 0 enables counting on the next clock cycle.
- Writing 0 disables the counter.
- Reading returns the current control state.

### 0x04 – COUNT Register

- Returns the current counter value.
- Increments once per clock cycle when `CTRL.enable` is set.
- Read-only.

### 0x08 – INIT_VAL Register

- Writing sets the initial value used when the counter is reset or re-enabled.
- This value is loaded into the counter the next time counting is started.

## Reset Behavior

- On system reset, all internal registers are cleared.
- The counter is initialized to 0 unless a value is set via `INIT_VAL`.

## Example Transaction Sequence

1. Write `INIT_VAL` with a custom starting point:
   ```
   write(0x08, 0x00001000)
   ```

2. Enable counting:
   ```
   write(0x00, 0x1)
   ```

3. Read current counter value:
   ```
   read(0x04) -> returns current count
   ```

4. Pause counting:
   ```
   write(0x00, 0x0)
   ```