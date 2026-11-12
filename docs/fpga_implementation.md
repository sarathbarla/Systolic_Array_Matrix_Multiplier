# FPGA Implementation Flow & Technology Mapping

## 1. Target Hardware Environment
- **FPGA Family**: AMD Xilinx Artix-7
- **Target Device**: `xc7a200tsbg484-1` (Speed grade: -1)
- **Design Mode**: Out-Of-Context (`-mode out_of_context`)
- **EDA Suite**: Vivado 2025.2 Batch Mode Flow

---

## 2. Why Out-of-Context (OOC) Mode?
A $3\times 3$ array exposing:
- Raw INT32 outputs: $9 \times 32 = 288\text{ bits}$
- ReLU INT32 outputs: $9 \times 32 = 288\text{ bits}$
- Quantized INT8 outputs: $9 \times 8 = 72\text{ bits}$
- Inputs & Controls: $48 + 5 = 53\text{ bits}$
- **Total Ports**: $> 700\text{ pins}$!

A physical Artix-7 package (SBG484) has only 285 user I/O pins. Attempting to assign every wire to an external FPGA package pin would cause pin-count overflow. In industry, accelerators and compute engines are implemented **Out-of-Context (OOC)** as IP blocks. This maps the design purely to internal silicon primitives (LUTs, FFs, DSPs, routing channels) without consuming physical package pins.

---

## 3. Implementation Flow Pipeline

The automated script (`scripts/run_vivado.tcl`) runs the following pipeline:

```
[Verilog RTL Sources]
          ↓
   `synth_design`        --> Translates Verilog AST into Artix-7 Primitives (LUTs, FFs, DSPs)
          ↓
    `opt_design`         --> Logic optimization (constant propagation, dead-logic removal)
          ↓
   `place_design`        --> Assigns LUTs and FFs to physical Slice coordinate locations
          ↓
 `phys_opt_design`       --> Physical timing optimization (inserts buffers to fix hold races)
          ↓
   `route_design`        --> Routes physical copper wires across the FPGA interconnect matrix
          ↓
  [Static Timing (STA), Resource Utilization & Power Reports]
```

---

## 4. Primitives Mapping Analysis

| Verilog Code Construct | Target Artix-7 Primitive | Purpose |
| :--- | :--- | :--- |
| `reg signed [31:0] acc` | **FDCE** (D Flip-Flop with Clock Enable & Async Clear) | Stores 32-bit accumulated sum inside each PE |
| `a_out <= a_in;` | **FDCE** | 1-cycle pipeline forwarding register |
| `a_in * b_in` + Adders | **LUT2, LUT3, LUT4, LUT6 + CARRY4** | Fast carry-chain lookahead arithmetic adders |
| `relu` (32-bit mux) | **LUT3** | Efficient 2-to-1 mux selecting 0 or data based on sign bit |
| `quantizer` saturation | **LUT4, LUT5, LUT6** | Magnitude comparator and 8-bit clipping mux |
