# 3×3 Signed INT8 Systolic Array Matrix Multiplier & Neural Network Accelerator

![Verilog](https://img.shields.io/badge/Language-Verilog-blue.svg)
![Target](https://img.shields.io/badge/FPGA-AMD%20Artix--7%20XC7A200T-red.svg)
![EDA](https://img.shields.io/badge/EDA-Vivado%202025.2-orange.svg)
![Status](https://img.shields.io/badge/Verification-100%25%20PASS-brightgreen.svg)

An open-source, production-grade **3×3 Signed INT8 Systolic Array Matrix Multiplier and Neural Network Datapath Core**, modeled in Verilog, verified with a self-checking testbench, and implemented on an **AMD Xilinx Artix-7 FPGA (`xc7a200tsbg484-1`)**.

---

## 📌 Project Overview: Baseline vs. Enhanced Architecture

This project documents the complete architectural transformation of a basic matrix multiplier into an AI inference datapath accelerator. Both versions are fully preserved in this repository for clear comparative study.

```
+--------------------------------------------------------------------------------------------------+
|                                      PROJECT DIRECTORY STRUCTURE                                 |
+--------------------------------------------------------------------------------------------------+
|                                                                                                  |
|   📁 baseline_vA/                         📁 RTL_Code/                                           |
|   ├── pe.v                                ├── pe.v (Signed INT8 MAC + clr_acc)                   |
|   ├── systolic_array_3x3.v                ├── relu.v (Combinational Activation)                  |
|   ├── Testbench/tb_systolic_array.v       ├── quantizer.v (INT32->INT8 Rounding & Saturation)     |
|   └── docs/dataflow.md                    └── systolic_array_3x3.v (Handshake FSM & Top-Level)   |
|                                                                                                  |
|   [Version A: Unsigned Reference]          [Version B: Enhanced AI Accelerator]                  |
+--------------------------------------------------------------------------------------------------+
```

### 1. What is the Baseline (Version A)? Located in `baseline_vA/`
The baseline implementation serves as the foundational reference model:
- **Purely Unsigned Arithmetic**: Computes $A \times B = C$ where matrix elements are strictly unsigned 8-bit integers ($[0, 255]$).
- **Free-Running Architecture**: No transaction handshaking, no `start` or `valid_out` flags. Downstream logic must blindly count clock cycles.
- **Destructive Global Reset**: Accumulators inside each PE can only be cleared by pulling the global chip-wide asynchronous reset (`rst_n`), which wipes out pipeline forwarding registers and kills continuous throughput.
- **Raw Integer Output**: Exposes unquantized 32-bit accumulators directly.

### 2. What is the Enhanced Design (Version B)? Located in `RTL_Code/`
The enhanced design upgrades the core into a neural-network-ready matrix multiplier:
- **Signed INT8 Two's Complement Math**: Operands span $[-128, +127]$. Features explicit 16-bit intermediate signed product sizing and 32-bit sign-extension to avoid Verilog unsigned conversion bugs.
- **Transaction Handshake Interface**:
  - `start`: 1-cycle initiation pulse.
  - `valid_in`: Gates input data; automatically zero-pads idle cycles to prevent unintended product accumulations.
  - `clr_acc`: Synchronously flushes all 9 accumulators without disturbing data propagating through systolic pipeline registers.
  - `busy`: Asserted during the 7-cycle active computation window.
  - `valid_out`: 1-cycle completion pulse asserted when all 9 matrix outputs ($C_{00}$ to $C_{22}$) are mathematically complete and stable.
- **Modular AI Post-Processing Pipeline**:
  - **ReLU Activation Unit (`relu.v`)**: Pure combinational $\max(0, x)$ clamping of negative values to zero.
  - **INT32-to-INT8 Quantizer (`quantizer.v`)**: Parameterized arithmetic right-shift (`SHIFT`), unbiased round-to-nearest integer ($+0.5\text{ LSB}$), and signed saturation clamping to $[-128, +127]$ to prepare data directly for the next neural network layer.

---

## 📊 Post-Routing Implementation Comparison (Real Measured Data)

Every metric in the table below was measured after full physical placement and copper routing using **AMD Xilinx Vivado 2025.2** targeting the **Artix-7 `xc7a200tsbg484-1`** at a **100 MHz (10.0 ns)** clock constraint:

| Parameter / Metric | Baseline Core (`baseline_vA`) | Enhanced AI Core (`RTL_Code`) | Delta ($\Delta$) | Technical Justification |
| :--- | :---: | :---: | :---: | :--- |
| **Arithmetic Type** | Unsigned 8-bit | **Signed INT8 (Two's Complement)** | Upgraded | Enables signed neural network weights & activations |
| **Accumulator Width** | Unsigned 32-bit | **Signed INT32 (Two's Complement)** | Upgraded | Prevents sign-extension wrap-around |
| **Handshake Protocol** | None (Free-Running) | **`start`, `valid_in`, `busy`, `valid_out`** | +Handshake | Synchronous master-slave interface |
| **Accumulator Clear** | Global Reset (`rst_n`) | **Synchronous Clear (`clr_acc`)** | Added | Allows seamless back-to-back matrix streaming |
| **Activation Unit** | None | **9x Combinational ReLU Units** | +9 Units | Computes $\max(0, x)$ at 0-cycle latency |
| **Quantization Unit** | None | **9x Rounding + Saturation Quantizers** | +9 Units | Scales 32-bit sums to INT8 for the next layer |
| **Slice LUT Utilization** | 766 LUTs (0.57%) | **1,208 LUTs (0.90%)** | +442 LUTs | Silicon footprint of 18 post-processing blocks |
| **Slice Registers (FFs)** | 384 FFs (0.14%) | **390 FFs (0.15%)** | +6 FFs | `cycle_cnt[3:0]`, `busy`, `valid_out` |
| **DSP48E1 Slices** | 0 DSPs | **0 DSPs** | 0 DSPs | Multipliers efficiently packed into slice LUTs |
| **Block RAM (BRAM)** | 0 Tiles | **0 Tiles** | 0 Tiles | Pure register-based systolic mesh |
| **Worst Setup Slack (100 MHz)**| +1.038 ns | **+0.528 ns** | -0.510 ns | Timing closed with positive safety margin |
| **Worst Hold Slack (WHS)** | +0.213 ns | **+0.166 ns** | -0.047 ns | Timing closed with zero hold races |
| **Maximum Frequency ($F_{\max}$)**| ~111 MHz | **~106 MHz (Post-Route) / ~110 MHz (Synth)** | -5 MHz | Added logic depth of control gating |
| **Dynamic Power** | 0.018 W (18 mW) | **0.021 W (21 mW)** | +3 mW | Switching activity from 18 arithmetic blocks |
| **Device Static Power** | 0.122 W (122 mW) | **0.122 W (122 mW)** | 0 mW | Baseline Artix-7 transistor leakage |
| **Total On-Chip Power** | **0.140 W (140 mW)** | **0.143 W (143 mW)** | **+3 mW (+2.1%)** | Exceptionally low thermal footprint |
| **Junction Temperature** | $25.5^\circ\text{C}$ | **$25.5^\circ\text{C}$** | $0.0^\circ\text{C}$ | Safe and cool ($0.5^\circ\text{C}$ above ambient) |

---

## 🏗️ Repository Layout

```
├── RTL_Code/                       # Enhanced Synthesizable Hardware Modules (Version B)
│   ├── pe.v                        # Processing Element (Signed MAC + Forwarding + clr_acc)
│   ├── relu.v                      # Zero-latency Combinational ReLU Unit
│   ├── quantizer.v                 # Signed INT32-to-INT8 Quantization (Shift + Round + Clamp)
│   └── systolic_array_3x3.v        # Top-Level 3x3 Array & Handshake FSM
│
├── baseline_vA/                    # Original Baseline Reference Modules (Version A)
│   ├── pe.v                        # Original unsigned PE
│   ├── systolic_array_3x3.v        # Original unsigned 3x3 array
│   ├── Testbench/tb_systolic_array.v # Baseline testbench
│   └── docs/dataflow.md            # Original dataflow reference
│
├── Testbench/                      # Comprehensive Verification Suite
│   └── tb_systolic_array.v         # Automated Self-Checking Multi-Scenario Testbench
│
├── constraints/                    # Physical & Timing Constraints
│   └── timing.xdc                  # 100 MHz Clock & Out-of-Context I/O delay constraints
│
├── scripts/                        # Automated Vivado Non-Project Batch Flow Tcl Scripts
│   ├── run_vivado.tcl              # Full Synthesis + Route + Report for Enhanced Version B
│   ├── run_version_comparison.tcl  # Full Synthesis + Route + Report for Baseline Version A
│   └── run_timing_sweep.tcl        # 4-Point STA Frequency Sweep (50, 100, 125, 200 MHz)
│
├── reports/                        # Implementation Signoff Artifacts
│   ├── version_B/                  # Post-route utilization, timing, power, clock reports
│   ├── version_A/                  # Baseline comparison reports
│   └── timing_sweep/               # Multi-frequency STA reports (50, 100, 125, 200 MHz)
│
├── docs/                           # In-Depth Engineering Documentation Package
│   ├── architecture.md             # Theoretical architecture & systolic flow analysis
│   ├── rtl_design_explanation.md   # RTL code walkthrough & micro-architecture details
│   ├── verification_report.md      # Testbench results & corner-case coverage
│   ├── fpga_implementation.md      # Vivado flow & Artix-7 technology mapping
│   ├── timing_analysis.md          # Static timing analysis & multi-frequency sweep
│   ├── resource_utilization.md     # In-depth LUT/FF/DSP slice breakdown
│   ├── power_analysis.md           # Thermal & power dissipation characterization
│   └── dataflow.md                 # Cycle-by-cycle systolic data propagation matrix
│
├── .gitignore                      # Professional git filter for CAD logs & temp builds
└── README.md                       # Master Repository Documentation
```

---

## 🚀 Quickstart: Simulation & Vivado Implementation

### 1. Functional Simulation with Icarus Verilog (`iverilog`)
Compile and run the self-checking testbench:
```bash
iverilog -o sim.vvp RTL_Code/pe.v RTL_Code/relu.v RTL_Code/quantizer.v RTL_Code/systolic_array_3x3.v Testbench/tb_systolic_array.v
vvp sim.vvp
```
*Expected Result:*
```
ALL TESTS PASSED SUCCESSFULLY! (Total Mismatches = 0)
```

### 2. FPGA Implementation in AMD Xilinx Vivado (Non-Project Batch Mode)
Launch Vivado and paste the following commands into the Tcl Console:
```tcl
cd "<project-directory>"
source ./scripts/run_vivado.tcl
source ./scripts/run_version_comparison.tcl
source ./scripts/run_timing_sweep.tcl
```
All implementation reports will be generated automatically in `reports/version_B/`, `reports/version_A/`, and `reports/timing_sweep/`.
