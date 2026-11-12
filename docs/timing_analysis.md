# Static Timing Analysis (STA) & Frequency Sweep

## 1. Fundamentals of Timing Closure
In digital synchronous hardware:
- **Setup Time ($T_{\text{setup}}$)**: Signals must arrive at the destination register before the next clock edge.
  $$\text{Slack}_{\text{setup}} = \text{Data Required Time} - \text{Data Arrival Time} \ge 0$$
- **Hold Time ($T_{\text{hold}}$)**: Signals must stay stable after the clock edge so they aren't accidentally overwritten by the next wavefront.
  $$\text{Slack}_{\text{hold}} = \text{Data Arrival Time} - \text{Data Required Time} \ge 0$$

A negative slack means timing failed. A positive slack means timing closed with safety margin.

---

## 2. Multi-Frequency Timing Sweep

Using our automated timing sweep script (`scripts/run_timing_sweep.tcl`), we evaluated Version B across four clock frequencies on the AMD Artix-7 (`-1` speed grade):

| Clock Target | Target Period ($T_{\text{clk}}$) | Worst Setup Slack (WNS) | Failing Endpoints (TNS) | Hold Slack (WHS) | Outcome |
| :---: | :---: | :---: | :---: | :---: | :---: |
| **50 MHz** | 20.000 ns | **+10.899 ns** | 0 | +0.224 ns | **MET (Very Safe)** |
| **100 MHz** | 10.000 ns | **+0.899 ns** | 0 | +0.224 ns | **MET (Target Closed)** |
| **125 MHz** | 8.000 ns | **-1.101 ns** | 94 | +0.224 ns | **VIOLATED (Too Fast)** |
| **200 MHz** | 5.000 ns | **-4.101 ns** | 285 | +0.224 ns | **VIOLATED (Too Fast)** |

---

## 3. Estimating Maximum Operating Frequency ($F_{\max}$)

The synthesized critical path delay represents the slowest register-to-register logic path:
$$T_{\text{crit}} = T_{\text{clk}} - \text{WNS} = 10.000\text{ ns} - 0.899\text{ ns} = \mathbf{9.101\text{ ns}}$$

Therefore, the theoretical maximum frequency on Artix-7 (-1) is:
$$F_{\max} = \frac{1}{T_{\text{crit}}} = \frac{1}{9.101\text{ ns}} \approx \mathbf{109.87\text{ MHz}}$$

This explains why **100 MHz** operates comfortably with $+0.899\text{ ns}$ margin, while **125 MHz** exceeds the delay budget by $1.1\text{ ns}$.

---

## 4. Post-Routing Timing Signoff (Version B at 100 MHz)

After full physical placement and copper wire routing (`reports/version_B/post_route_timing_summary.rpt`):
- **Worst Negative Slack (WNS)**: **+0.528 ns**
- **Total Negative Slack (TNS)**: **0.000 ns** (0 failing endpoints out of 1,425)
- **Worst Hold Slack (WHS)**: **+0.166 ns** (0 hold violations)
- **Timing Status**: **ALL CONSTRAINTS FULLY MET**

### Critical Path Breakdown
The critical path in the design starts from the `a_wire` / `b_wire` pipeline register outputs, traverses through the 8-bit multiplier logic and 32-bit CARRY4 adder chain, and ends at the D-input of the `acc` accumulator register. At 100 MHz, this total delay including routing is $9.472\text{ ns}$, safely below our 10.0 ns clock period.
