# 3×3 Signed INT8 Systolic Array Matrix Multiplier & AI Accelerator

![Verilog](https://img.shields.io/badge/Language-Verilog-blue.svg)
![Target](https://img.shields.io/badge/FPGA-AMD%20Artix--7%20XC7A200T-red.svg)
![EDA](https://img.shields.io/badge/EDA-Vivado%202025.2-orange.svg)
![Status](https://img.shields.io/badge/Verification-100%25%20PASS-brightgreen.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)

An open-source, production-grade **3×3 Signed INT8 Systolic Array Matrix Multiplier and Neural Network Datapath Core**, modeled in Verilog, verified with a self-checking testbench, and implemented on an **AMD Xilinx Artix-7 FPGA (`xc7a200tsbg484-1`)**.

---

## ⚡ Highlights & Key Features

- **2D Mesh Systolic Architecture**: 9 Processing Elements (PEs) using an **Output Stationary (OS)** dataflow to maximize local data reuse and minimize inter-PE wire routing capacitance.
- **Signed INT8 Two's Complement Math**: Signed $8\text{-bit} \times 8\text{-bit}$ multiplier with explicit sign-extension and signed 32-bit accumulation.
- **Integrated Neural Network Post-Processing**:
  - **ReLU Activation**: Pure combinational, zero-latency $\max(0, x)$ clamping.
  - **INT32-to-INT8 Quantization**: Arithmetic right shift (configurable `SHIFT` factor), unbiased round-to-nearest-integer, and signed saturation clamping to $[-128, +127]$.
- **Robust Control Interface**: 1-cycle `start` pulse, `valid_in` gating, synchronous `clr_acc` accumulator flush, `busy` indicator, and a cycle-accurate `valid_out` completion flag.
- **Full FPGA Implementation**: Synthesized, placed, and routed at **100 MHz** with closed setup and hold timing, zero DSP/BRAM consumption, and detailed static timing, utilization, and power characterization.

---

## 📊 Comprehensive Engineering Comparison: Baseline vs. Enhanced

Every metric below is an **actual, measured post-route Vivado implementation result** targeting the AMD Artix-7 (`xc7a200tsbg484-1`):

| Parameter / Metric | Baseline Core (Version A) | Enhanced AI Accelerator (Version B) | Delta ($\Delta$) | Design Justification |
| :--- | :---: | :---: | :---: | :--- |
| **Arithmetic** | Unsigned 8-bit | **Signed INT8 (Two's Complement)** | Upgraded | Supports negative weights & activations |
| **Accumulator** | Unsigned 32-bit | **Signed INT32 (Two's Complement)** | Upgraded | Prevents sign-extension wrap-around |
| **Handshake Protocol** | None (Blind Free-Run) | **`start`, `valid_in`, `busy`, `valid_out`** | +Handshake | Downstream master synchronization |
| **Accumulator Clear** | Destructive Global `rst_n` | **Synchronous `clr_acc`** | Added | Allows back-to-back matrix streaming |
| **Activation Unit** | None | **9x Combinational ReLU Units** | +9 Blocks | $\max(0, x)$ for neural network inference |
| **Quantization Unit** | None | **9x Rounding + Saturation Quantizers**| +9 Blocks | Scales 32-bit sums down to INT8 for next layer |
| **LUT Utilization** | 766 LUTs (0.57%) | **1,208 LUTs (0.90%)** | +442 LUTs | Footprint for 18 post-processing blocks |
| **Flip-Flop Utilization**| 384 FFs (0.14%) | **390 FFs (0.15%)** | +6 FFs | `cycle_cnt[3:0]`, `busy`, `valid_out` |
| **DSP48E1 Slices** | 0 DSPs | **0 DSPs** | 0 DSPs | Efficiently packed into slice LUTs |
| **Block RAM (BRAM)** | 0 Tiles | **0 Tiles** | 0 Tiles | Register-based systolic mesh |
| **Worst Setup Slack (100 MHz)**| +1.038 ns | **+0.528 ns** | -0.510 ns | Timing closed with safety margin |
| **Worst Hold Slack (WHS)** | +0.213 ns | **+0.166 ns** | -0.047 ns | Timing closed with zero hold races |
| **Maximum Frequency ($F_{\max}$)**| ~111 MHz | **~106 MHz (Post-Route) / ~110 MHz (Synth)** | -5 MHz | Additional logic depth of control gating |
| **Dynamic Power** | 0.018 W (18 mW) | **0.021 W (21 mW)** | +3 mW | Added switching from 18 arithmetic blocks |
| **Device Static Power** | 0.122 W (122 mW) | **0.122 W (122 mW)** | 0 mW | Constant Artix-7 baseline leakage |
| **Total On-Chip Power** | **0.140 W (140 mW)** | **0.143 W (143 mW)** | **+3 mW (+2.1%)** | Exceptionally low power envelope |
| **Junction Temperature** | $25.5^\circ\text{C}$ | **$25.5^\circ\text{C}$** | $0.0^\circ\text{C}$ | Runs virtually cold ($0.5^\circ\text{C}$ above ambient) |

---

## 🏗️ Repository Architecture & File Organization

```
├── RTL_Code/                       # Synthesizable Hardware Modules
│   ├── pe.v                        # Processing Element (Signed MAC + Forwarding + clr_acc)
│   ├── relu.v                      # Zero-latency Combinational ReLU Unit
│   ├── quantizer.v                 # Signed INT32-to-INT8 Quantization (Shift + Round + Clamp)
│   └── systolic_array_3x3.v        # Top-Level 3x3 Array & Handshake FSM
│
├── baseline_vA/                    # Preserved Original Baseline Version A (For comparison)
│   ├── pe.v
│   ├── systolic_array_3x3.v
│   ├── Testbench/tb_systolic_array.v
│   └── docs/dataflow.md
│
├── Testbench/                      # Verification Suite
│   └── tb_systolic_array.v         # Automated Self-Checking Multi-Test Benchmark
│
├── constraints/                    # Physical & Timing Constraints
│   └── timing.xdc                  # 100 MHz Clock & Out-of-Context I/O delay constraints
│
├── scripts/                        # Automated Vivado Non-Project Batch Flow Tcl Scripts
│   ├── run_vivado.tcl              # Full Synthesis + Route + Report for Version B
│   ├── run_version_comparison.tcl  # Full Synthesis + Route + Report for Baseline Version A
│   └── run_timing_sweep.tcl        # 4-Point STA Frequency Sweep (50, 100, 125, 200 MHz)
│
├── reports/                        # Implementation Signoff Artifacts
│   ├── version_B/                  # Post-route utilization, timing, power, clock reports
│   ├── version_A/                  # Baseline comparison reports
│   └── timing_sweep/               # Multi-frequency STA reports
│
├── docs/                           # Technical Specifications & Engineering Reports
│   ├── architecture.md             # Theoretical architecture & systolic flow analysis
│   ├── rtl_design_explanation.md   # RTL code walkthrough & micro-architecture details
│   ├── verification_report.md      # Testbench results & corner case coverage
│   ├── fpga_implementation.md      # Vivado flow & Artix-7 technology mapping
│   ├── timing_analysis.md          # Static timing analysis & multi-frequency sweep
│   ├── resource_utilization.md     # In-depth LUT/FF/DSP slice breakdown
│   ├── power_analysis.md           # Thermal & power dissipation characterization
│   └── dataflow.md                 # Cycle-by-cycle systolic data propagation matrix
│
├── .gitignore                      # Professional git filter for CAD logs & temp builds
└── README.md                       # Master Documentation
```

---

## 🚀 Quickstart: Simulation & Vivado Implementation

### 1. Fast Simulation with Icarus Verilog (`iverilog`)
Compile and run the self-checking testbench:
```bash
iverilog -o sim.vvp RTL_Code/pe.v RTL_Code/relu.v RTL_Code/quantizer.v RTL_Code/systolic_array_3x3.v Testbench/tb_systolic_array.v
vvp sim.vvp
```
*Expected Result:*
```
ALL TESTS PASSED SUCCESSFULLY! (Total Mismatches = 0)
```

### 2. FPGA Implementation in AMD Xilinx Vivado (Batch Mode)
Open Vivado and run the Tcl script from the console:
```tcl
cd "<project-directory>"
source ./scripts/run_vivado.tcl
source ./scripts/run_version_comparison.tcl
source ./scripts/run_timing_sweep.tcl
```
All implementation reports will be neatly generated in `reports/`.

---

## 📜 License
This project is released under the **MIT License**. Feel free to use, modify, and reference in academic research, portfolio reviews, and hardware accelerator projects.
