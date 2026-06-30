# 3x3 Systolic Array Matrix Multiplier using Verilog HDL

## Overview

This project implements a **3x3 Systolic Array Matrix Multiplier** using Verilog HDL.

The design performs matrix multiplication:

```
C = A × B
```

Two 3x3 matrices are multiplied using a grid of Processing Elements (PEs).

The architecture contains 9 Processing Elements where each PE performs a Multiply-Accumulate (MAC) operation.

The design demonstrates:

- Parallel processing using systolic architecture
- Data movement between processing elements
- Accumulation of partial multiplication results
- RTL simulation verification

---

# Features

- 3x3 systolic array architecture
- 9 Processing Elements
- MAC operation inside each PE
- 8-bit input data
- 32-bit accumulator output
- Matrix A data flow from left to right
- Matrix B data flow from top to bottom
- Active-low reset
- Automated simulation checking

---

# Project Structure

```
SYSTOLIC_ARRAY_MATRIX/

├── docs/
│   └── dataflow.md
│
├── RTL_Code/
│   ├── pe.v
│   └── systolic_array_3x3.v
│
├── Testbench/
│   └── tb_systolic_array.v
│
├── README.md
│
└── .gitignore
```

---

# Systolic Array Architecture

The systolic array consists of 9 Processing Elements arranged in a 3x3 grid.

Each PE performs:

```
acc = acc + (a_in * b_in)
```

During every clock cycle:

- A input values move horizontally
- B input values move vertically
- Each PE updates its accumulator


Architecture:

```
              B flows downward

             ↓        ↓        ↓


        +-----+  +-----+  +-----+
A ----> | PE  |->| PE  |->| PE  |
        +-----+  +-----+  +-----+

        +-----+  +-----+  +-----+
A ----> | PE  |->| PE  |->| PE  |
        +-----+  +-----+  +-----+

        +-----+  +-----+  +-----+
A ----> | PE  |->| PE  |->| PE  |
        +-----+  +-----+  +-----+

              A flows horizontally
```

---

# Module Description

## pe.v

This module implements a single Processing Element.

The PE performs:

```
acc = acc + (a_in * b_in)
```

### Inputs

| Signal | Description |
|---|---|
| clk | Clock signal |
| rst_n | Active-low reset |
| a_in | A data input |
| b_in | B data input |

### Outputs

| Signal | Description |
|---|---|
| a_out | Passes A data to next PE |
| b_out | Passes B data to next PE |
| acc | Accumulated result |

The PE forwards input values while calculating the partial sum.

---

# systolic_array_3x3.v

This is the top-level module.

It creates:

```
3 × 3 = 9 Processing Elements
```

using Verilog generate loops.

Each PE produces one output element:

```
PE[0][0] → C[0][0]

PE[0][1] → C[0][1]

...

PE[2][2] → C[2][2]
```

---

# Matrix Multiplication Example

Input Matrix A:

```
| 1 2 3 |
| 4 5 6 |
| 7 8 9 |
```

Input Matrix B:

```
| 7 8 9 |
| 6 5 4 |
| 3 2 1 |
```

Expected output:

```
| 28  24  20 |
| 76  69  62 |
|124 114 104 |
```

---

# Testbench Verification

The testbench file:

```
tb_systolic_array.v
```

performs:

- Clock generation
- Reset operation
- Matrix input feeding
- Output monitoring
- Automatic result comparison


The simulation checks all 9 output values.

Successful execution displays:

```
ALL RESULTS CORRECT - PASS
```

---

# Simulation

Simulation is performed using Icarus Verilog.

## Compile

Run:

```bash
iverilog -g2012 -o systolic_sim RTL_Code/*.v Testbench/*.v
```

## Run Simulation

Run:

```bash
vvp systolic_sim
```

## View Waveform

The testbench generates:

```
systolic_array.vcd
```

Open waveform:

```bash
gtkwave systolic_array.vcd
```

---

# Design Parameters

| Parameter | Value |
|---|---|
| Architecture | 3x3 Systolic Array |
| Processing Elements | 9 |
| Input Width | 8-bit |
| Accumulator Width | 32-bit |
| Operation | Matrix Multiplication |
| Language | Verilog HDL |
| Clock Domain | Single Clock |

---

# Applications

Systolic arrays are used in:

- Matrix processing systems
- DSP hardware
- FPGA based computation
- Hardware acceleration

---

# Tools Used

- Verilog HDL
- Icarus Verilog
- GTKWave
- VS Code
- Vivado

---

# Author

**Sarth Barla**

ECE Undergraduate

Digital Design | Verilog HDL | Computer Architecture


---

# License

This project is created for educational purposes.