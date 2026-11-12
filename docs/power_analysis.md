# Vivado Power Estimation Analysis

## 1. Power Estimation Fundamentals
In CMOS and FPGA devices, power is composed of two primary components:
1. **Static Power ($P_{\text{static}}$)**: Leakage current that flows through transistors simply because the chip is powered on, regardless of clock switching.
2. **Dynamic Power ($P_{\text{dynamic}}$)**: Power consumed when digital nets charge and discharge capacitive parasitics:
   $$P_{\text{dynamic}} = \alpha \cdot C \cdot V_{DD}^2 \cdot f_{\text{clk}}$$
   Where:
   - $\alpha$ is switching activity.
   - $C$ is capacitive load of wires and transistor gates.
   - $V_{DD}$ is supply voltage (1.0 V for Artix-7 core).
   - $f_{\text{clk}}$ is clock frequency (100 MHz).

---

## 2. Actual Measured Results (Version A vs. Version B)

The data below was extracted directly from `reports/version_A/post_route_power.rpt` and `reports/version_B/post_route_power.rpt`:

| Metric | Version A (Baseline) | Version B (Enhanced) | Delta ($\Delta$) | Analysis |
| :--- | :---: | :---: | :---: | :--- |
| **Total On-Chip Power** | **0.140 W (140 mW)** | **0.143 W (143 mW)** | **+3 mW (+2.1%)** | Negligible increase |
| **Device Static Power** | 0.122 W (122 mW) | 0.122 W (122 mW) | 0 mW (0.0%) | Unchanged baseline silicon leakage |
| **Dynamic Power** | 0.018 W (18 mW) | 0.021 W (21 mW) | +3 mW (+16.7%) | Added switching from ReLU & Quantizers |
| - Logic Power | 0.010 W | 0.012 W | +2 mW | Combinational switching |
| - Signals / Wires | 0.006 W | 0.007 W | +1 mW | Interconnect wire capacitance |
| - Clock Tree Power | 0.002 W | 0.002 W | 0 mW | Single clock domain |
| **Junction Temp ($T_j$)** | **$25.5^\circ\text{C}$** | **$25.5^\circ\text{C}$** | $0.0^\circ\text{C}$ | Safe and cool ($0.5^\circ\text{C}$ above ambient) |
| **Thermal Margin ($T_{\text{margin}}$)**| **$59.5^\circ\text{C}$** | **$59.5^\circ\text{C}$** | $0.0^\circ\text{C}$ | High safety factor below $85^\circ\text{C}$ limit |

---

## 3. Engineering Insights & Disclaimers

### Why Did Dynamic Power Increase by 3 mW?
Version B added 18 new combinational computing blocks (9 ReLU activation blocks + 9 saturation quantizers) and gating logic. The additional wire transitions and LUT switching naturally consume 3 mW more dynamic power during active calculation.

### Thermal Reality Check: Is It Overheating?
In Vivado reports:
- `Max Ambient: 84.5 C`: This indicates the chip could safely operate in a blistering $84.5^\circ\text{C}$ environment without overheating.
- `Junction Temperature: 25.5 C`: The chip is only $0.5^\circ\text{C}$ above room temperature ($25.0^\circ\text{C}$). The design runs exceptionally cool.

> **Important Verification Engineering Note**:
> These values are Vivado post-route mathematical estimates based on vectorless default switching activity ($\alpha = 0.125$). For physical board deployment, physical power measurements using current sense resistors or VCD/SAIF simulation activity vectors are recommended for milliwatt-accurate power profiling.
