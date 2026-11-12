# Resource Utilization Analysis

## 1. AMD Xilinx Artix-7 Device Profile
- **FPGA Part**: `xc7a200tsbg484-1`
- **Total Available Slice LUTs**: 133,800
- **Total Available Slice Registers (FFs)**: 267,600
- **Total Available DSP48E1 Slices**: 740
- **Total Block RAM Tiles**: 365

---

## 2. Actual Measured Utilization (Version A vs. Version B)

The data below was extracted directly from the post-route Vivado implementation reports:

| Resource Type | Version A (Baseline) | Version B (Enhanced) | Delta ($\Delta$) | Device Utilization % |
| :--- | :---: | :---: | :---: | :---: |
| **Slice LUTs** | **766** | **1,208** | **+442** ($+57.7\%$) | **0.90%** |
| - LUT as Logic | 766 | 1,208 | +442 | 0.90% |
| - LUT as Memory | 0 | 0 | 0 | 0.00% |
| **Slice Registers (FFs)**| **384** | **390** | **+6** ($+1.6\%$) | **0.15%** |
| **DSP48E1 Blocks** | **0** | **0** | 0 | **0.00%** |
| **Block RAM (BRAM)** | **0** | **0** | 0 | **0.00%** |
| **Global Clock Buffers** | **1** | **1** | 0 | **3.12%** |

---

## 3. Engineering Breakdown: Where Did the Logic Go?

### 1. Register Count (+6 Flip-Flops)
- **Version A**: 384 FFs
  - $9 \text{ PEs} \times 32\text{-bit accumulators} = 288\text{ FFs}$
  - Systolic forwarding pipeline registers ($A$ and $B$) $= 96\text{ FFs}$
  - Total = $288 + 96 = 384\text{ FFs}$.
- **Version B**: 390 FFs
  - Exactly 6 new control registers:
    - `cycle_cnt[3:0]` (4 FFs)
    - `busy` (1 FF)
    - `valid_out` (1 FF)
  - Total = $384 + 6 = 390\text{ FFs}$.

### 2. LUT Count (+442 LUTs)
Why did Version B consume 442 additional LUTs?
- **Handshake Logic**: Input data gating with `valid_in` and cycle counter logic.
- **9x ReLU Units**: 9 units $\times$ 32-bit muxes selecting between 0 and positive numbers.
- **9x Quantizers**:
  - 32-bit adders for rounding offset ($+ 2^{\text{SHIFT}-1}$).
  - Multi-bit arithmetic barrel right-shifter.
  - Signed magnitude comparators and saturation clipping multiplexers ($[-128, +127]$).
- This equates to $\approx 49\text{ LUTs}$ per complete post-processing channel, a very compact footprint for full saturation and rounding arithmetic.

### 3. The DSP Slice Question: Why 0 DSPs?
Both versions used **0 dedicated DSP48E1 slices**. 
- In Xilinx FPGAs, a DSP48E1 slice contains a massive $25 \times 18$ signed multiplier.
- Our operations are only $8 \times 8$ bit multiplications.
- Vivado's cost-based synthesis optimizer determined that mapping an $8 \times 8$ multiplier into slice LUTs uses only ~30 LUTs. Because the XC7A200T has over 133,000 LUTs and the design uses $<1\%$, Vivado smartly saves the DSP blocks for wider floating-point or large audio/video math.
- If an engineer wishes to force DSP inference (to save LUTs), the directive `(* use_dsp = "yes" *)` can be added to the Verilog multiplier wire.
