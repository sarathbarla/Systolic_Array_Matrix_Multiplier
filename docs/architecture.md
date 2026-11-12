# Architecture Specification: 3×3 Systolic Array Accelerator

## 1. Executive Summary & Philosophy
Matrix multiplication ($C = A \times B$) forms $>90\%$ of the compute workload in deep neural networks (Transformers, CNNs, MLPs). In standard von Neumann architectures (CPUs/GPUs), repeatedly fetching activations and weights from memory to arithmetic units burns huge amounts of energy.

A **systolic array** mimics the human circulatory system: data pulses through a rhythmic network of Processing Elements (PEs), reusing operands multiple times before returning them to memory. 

This project implements an **Output Stationary (OS)** 2D mesh systolic array designed for INT8 neural network inference with integrated **ReLU activation** and **INT32-to-INT8 quantization**.

```
                        Matrix B (Columns)
                          b_col0  b_col1  b_col2
                            ↓       ↓       ↓
   Matrix A (Rows)       +------+------+------+
      a_row0 ----------> | PE00 | PE01 | PE02 |
                         +------+------+------+
      a_row1 ----------> | PE10 | PE11 | PE12 |
                         +------+------+------+
      a_row2 ----------> | PE20 | PE21 | PE22 |
                         +------+------+------+
                            ↓       ↓       ↓
                           (Boundary Drains)
```

---

## 2. Structural Breakdown

### 2.1 The Core Processing Element (PE)
Each PE contains:
1. **Registered Horizontal Forwarding**: Passes $A_{in} \to A_{out}$ on the rising clock edge.
2. **Registered Vertical Forwarding**: Passes $B_{in} \to B_{out}$ on the rising clock edge.
3. **Signed Multiply-Accumulate Engine**: Computes $A_{in} \times B_{in}$ (16-bit signed product) and accumulates into a 32-bit signed accumulator (`acc`).
4. **Synchronous Clear (`clr_acc`)**: Allows wiping the accumulator for the next matrix multiply without destroying pipeline registers carrying data across the array.

### 2.2 Why Output Stationary (OS)?
In hardware, reading memory costs $10\times$ to $100\times$ more energy than an arithmetic MAC.
- In **Output Stationary**, the heavy 32-bit accumulator stays parked inside the PE.
- Only narrow 8-bit inputs stream through the network.
- This minimizes inter-PE wiring congestion and eliminates high-capacitance 32-bit routing lines.

---

## 3. Data Wavefront & Skewing Mechanics

Operands travel across the array at a rate of 1 PE hop per clock cycle. To ensure that Row $i$ of Matrix $A$ meets Column $j$ of Matrix $B$ at $\text{PE}_{ij}$ at the exact moment their indices match, **inputs must be skewed in time**.

$$\text{Arrival Cycle at PE}(i, j) = k + i + j$$

Where:
- $i \in \{0, 1, 2\}$ is the row index.
- $j \in \{0, 1, 2\}$ is the column index.
- $k \in \{0, 1, 2\}$ is the dot-product sequence index.

```
Cycle:      0       1       2       3       4
a_row0:  A[0][0]  A[0][1]  A[0][2]    0       0
a_row1:    0      A[1][0]  A[1][1]  A[1][2]   0
a_row2:    0        0      A[2][0]  A[2][1]  A[2][2]

b_col0:  B[0][0]  B[1][0]  B[2][0]    0       0
b_col1:    0      B[0][1]  B[1][1]  B[2][1]   0
b_col2:    0        0      B[0][2]  B[1][2]  B[2][2]
```

---

## 4. Post-Processing Pipeline: AI Features

Modern deep learning layers do not emit raw 32-bit accumulators directly into the next layer. This accelerator integrates two modular post-processing stages for each output:

```
[Raw Accumulator (INT32)] 
          ↓
  [ReLU Activation]       --> Clamps negative numbers to 0: max(0, x)
          ↓
 [Quantization Unit]      --> Arithmetic Right Shift (SCALE)
                              + Rounding to nearest integer (+0.5 LSB)
                              + Signed Saturation Clamping ([-128, +127])
          ↓
[Quantized Output (INT8)] --> Direct input for next neural network layer!
```

---

## 5. Transaction Control Interface

The design features a complete handshake interface:
- **`start`**: 1-cycle pulse that triggers a matrix computation transaction.
- **`valid_in`**: High during cycles where valid skewed matrix elements are present.
- **`clr_acc`**: Synchronously flushes all 9 accumulators to zero.
- **`busy`**: Asserted throughout the 7-cycle systolic computation window.
- **`valid_out`**: 1-cycle flag asserted at Cycle 7 signaling that all 9 matrix outputs ($C_{00}$ to $C_{22}$) are mathematically final and stable.
