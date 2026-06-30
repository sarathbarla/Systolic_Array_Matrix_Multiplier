# 3x3 Systolic Array Matrix Multiplier using Verilog HDL

## Overview

This project implements a **3x3 Systolic Array based Matrix Multiplier** using Verilog HDL.

A systolic array is a parallel processing architecture where multiple Processing Elements (PEs) work together to perform repeated arithmetic operations efficiently.

This design performs:


C = A × B


where:

- A is a 3×3 input matrix
- B is a 3×3 input matrix
- C is the resulting 3×3 output matrix

The design uses a grid of 9 Processing Elements, where each PE performs a Multiply-Accumulate (MAC) operation.

---

# Features

- 3×3 systolic array architecture
- Matrix multiplication using parallel Processing Elements
- MAC based computation
- Data movement through pipeline stages
- Horizontal flow of matrix A values
- Vertical flow of matrix B values
- 32-bit accumulated output
- RTL simulation verification
- Automated result checking in testbench

---

# Project Structure


SYSTOLIC_ARRAY_MATRIX/

├── docs/
│ └── dataflow.md # Systolic array data flow explanation
│
├── RTL_Code/
│ ├── pe.v # Processing Element module
│ └── systolic_array_3x3.v # 3x3 systolic array top module
│
├── Testbench/
│ └── tb_systolic_array.v # Verification testbench
│
├── README.md
│
└── .gitignore


---

# Systolic Array Architecture

The design consists of a 3×3 grid of Processing Elements.

Each PE performs:


acc = acc + (A × B)


Data movement:

- Matrix A elements move from left to right
- Matrix B elements move from top to bottom
- Partial results accumulate inside each PE

After the required number of cycles, every PE contains one element of the output matrix C.


          B flows downward

    ↓        ↓        ↓

  +----+   +----+   +----+

A --> | PE |-->| PE |-->| PE |
+----+ +----+ +----+

  +----+   +----+   +----+

A --> | PE |-->| PE |-->| PE |
+----+ +----+ +----+

  +----+   +----+   +----+

A --> | PE |-->| PE |-->| PE |
+----+ +----+ +----+

    A flows horizontally

---

# Module Description

## pe.v

Processing Element module.

Each PE performs one MAC operation.

### Inputs

| Signal | Description |
|-|-|
| clk | Clock signal |
| rst_n | Active-low reset |
| a_in | Input A value from left |
| b_in | Input B value from top |

### Outputs

| Signal | Description |
|-|-|
| a_out | Passes A value to next PE |
| b_out | Passes B value to next PE |
| acc | Partial accumulated result |

Operation:


acc = acc + (a_in × b_in)


The PE also forwards:


a_in → a_out
b_in → b_out


allowing data to travel through the array.

---

# systolic_array_3x3.v

Top-level systolic array module.

It instantiates:


3 × 3 = 9 Processing Elements


Each PE works together to compute one output element.

Example:


C[0][0] = PE(0,0)
C[0][1] = PE(0,1)
...
C[2][2] = PE(2,2)


---

# Data Flow

Matrix A:

- Rows are supplied from the left side
- Values move horizontally


Matrix B:

- Columns are supplied from the top
- Values move vertically


Inputs are skewed so that the correct A and B values arrive at the required PE during the same clock cycle.

Example:


Cycle 0:
A[0][0] meets B[0][0]

Cycle 1:
A[0][1] meets B[1][0]

Cycle 2:
A[0][2] meets B[2][0]


The partial products accumulate until the final matrix result is obtained.

---

# Testbench Verification

The testbench verifies matrix multiplication using:

Matrix A:


| 1 2 3 |
| 4 5 6 |
| 7 8 9 |


Matrix B:


| 7 8 9 |
| 6 5 4 |
| 3 2 1 |


Expected output:


| 28 24 20 |
| 76 69 62 |
|124 114 104 |


---

# Simulation Checks

The testbench performs:

- Reset operation
- Input data feeding
- Systolic array propagation
- Output comparison
- Automated PASS/FAIL reporting

Expected output:


ALL RESULTS CORRECT - PASS


---

# Running Simulation

## Compile using Icarus Verilog

```bash
iverilog -g2012 -o systolic_sim RTL_Code/*.v Testbench/*.v
Run simulation
vvp systolic_sim
View waveform
gtkwave systolic_array.vcd
Design Parameters
Parameter	Value
Architecture	3×3 Systolic Array
Processing Elements	9
Operation	Matrix Multiplication
MAC Width	32-bit
Data Width	8-bit
Language	Verilog HDL
Clock Domain	Single Clock
Applications

Systolic arrays are used in:

Neural network accelerators
AI hardware
DSP processors
Matrix computation engines
High performance computing systems
Tools Used
Verilog HDL
Icarus Verilog
GTKWave
VS Code
Vivado RTL Analysis
Author

Sarth Barla

ECE Undergraduate

Digital Design | Verilog HDL | Computer Architecture

License

This project is created for educational purposes.