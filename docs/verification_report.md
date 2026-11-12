# Verification & Testbench Report

## 1. Verification Strategy
Verification was conducted using an automated, self-checking SystemVerilog/Verilog testbench (`Testbench/tb_systolic_array.v`) driven by a high-level behavioral golden model.

Rather than checking only the final cycle with hardcoded numbers, the testbench computes expected results dynamically, simulates skewed wavefront feeding, waits for the hardware `valid_out` handshake flag, and verifies all 9 outputs across raw INT32, post-ReLU INT32, and quantized INT8.

---

## 2. Test Matrix & Results

| Test # | Test Name | Stimulus Description | Objective | Status |
| :---: | :--- | :--- | :--- | :---: |
| **1** | All Positive Matrices | $A, B \in [1, 9]$ | Baseline sanity check | **PASS (0 mismatches)** |
| **2** | Mixed-Sign Matrices | Mixed positive and negative values | Checks signed dot products & ReLU clamping | **PASS (0 mismatches)** |
| **3** | All Negative Matrices | $A, B < 0$ | Verifies $(-A) \times (-B) = +C$ | **PASS (0 mismatches)** |
| **4** | Zero Matrix Multiply | $A = 0$ or $B = 0$ | Ensures no spurious register leak | **PASS (0 mismatches)** |
| **5** | Max Positive Limit | All elements $= +127$ | Dynamic range test ($C_{ij} = 48{,}387$) & Saturation | **PASS (0 mismatches)** |
| **6** | Min Negative Limit | Diagonal elements $= -128$ | Multiplier boundary test ($-128 \times -128 = +16{,}384$) | **PASS (0 mismatches)** |
| **7** | Back-to-Back Operations | Consecutive matrices | Tests `clr_acc` flush without global reset | **PASS (0 mismatches)** |

---

## 3. Detailed Execution Log

```
VCD info: dumpfile systolic_array.vcd opened for output.

------------------------------------------------------------
Running Test 1: All Positive Matrices
------------------------------------------------------------
Status: PASS (All 9 elements matched expected values)
C[0][0]=28, C[0][1]=24, C[0][2]=20
C[1][0]=76, C[1][1]=69, C[1][2]=62
C[2][0]=124, C[2][1]=114, C[2][2]=104

------------------------------------------------------------
Running Test 2: Mixed-Sign Matrices
------------------------------------------------------------
Status: PASS (All 9 elements matched expected values)
C[0][0]=-19, C[0][1]=20, C[0][2]=-11
C[1][0]=36, C[1][1]=-32, C[1][2]=19
C[2][0]=-27, C[2][1]=17, C[2][2]=-23

------------------------------------------------------------
Running Test 3: All Negative Matrices
------------------------------------------------------------
Status: PASS (All 9 elements matched expected values)
C[0][0]=28, C[0][1]=24, C[0][2]=20
C[1][0]=76, C[1][1]=69, C[1][2]=62
C[2][0]=124, C[2][1]=114, C[2][2]=104

------------------------------------------------------------
Running Test 4: Zero Matrix Multiplication
------------------------------------------------------------
Status: PASS (All 9 elements matched expected values)
C[0][0]=0, C[0][1]=0, C[0][2]=0
C[1][0]=0, C[1][1]=0, C[1][2]=0
C[2][0]=0, C[2][1]=0, C[2][2]=0

------------------------------------------------------------
Running Test 5: Maximum Positive Values (+127)
------------------------------------------------------------
Status: PASS (All 9 elements matched expected values)
C[0][0]=48387, C[0][1]=48387, C[0][2]=48387
C[1][0]=48387, C[1][1]=48387, C[1][2]=48387
C[2][0]=48387, C[2][1]=48387, C[2][2]=48387

------------------------------------------------------------
Running Test 6: Minimum Negative Values (-128)
------------------------------------------------------------
Status: PASS (All 9 elements matched expected values)
C[0][0]=16384, C[0][1]=0, C[0][2]=0
C[1][0]=0, C[1][1]=16384, C[1][2]=0
C[2][0]=0, C[2][1]=0, C[2][2]=16384

------------------------------------------------------------
Running Test 7: Back-to-Back Transaction
------------------------------------------------------------
Status: PASS (All 9 elements matched expected values)
C[0][0]=6, C[0][1]=9, C[0][2]=12
C[1][0]=15, C[1][1]=18, C[1][2]=21
C[2][0]=15, C[2][1]=18, C[2][2]=21

============================================================
                   FINAL VERIFICATION REPORT                
============================================================
ALL TESTS PASSED SUCCESSFULLY! (Total Mismatches = 0)
============================================================
```
