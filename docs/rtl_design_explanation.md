# RTL Design Explanation: Under the Hood

## 1. Modular Hierarchy

```
systolic_array_3x3 (Top-Level Accelerator Core)
 ├── row_gen[0..2].col_gen[0..2].pe_inst (9x Processing Elements)
 ├── post_row[0..2].post_col[0..2].relu_inst (9x Combinational ReLU Units)
 └── post_row[0..2].post_col[0..2].quant_inst (9x Parameterized Quantizers)
```

---

## 2. Deep Dive: Processing Element (`pe.v`)

### Signed Math & Sign Extension
A classic trap in Verilog is accidental signed/unsigned mixing. If any operand in an expression is unsigned, Verilog treats the entire operation as unsigned!

In `pe.v`, we guarantee signed arithmetic:
```verilog
wire signed [15:0] product = a_in * b_in;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        a_out <= 8'sd0;
        b_out <= 8'sd0;
        acc   <= 32'sd0;
    end else begin
        a_out <= a_in;
        b_out <= b_in;

        if (clr_acc) begin
            acc <= 32'sd0;
        end else begin
            acc <= acc + {{16{product[15]}}, product};
        end
    end
end
```
- **Explicit Sign Extension**: `{{16{product[15]}}, product}` replicates the sign bit (bit 15) sixteen times, guaranteeing that a negative product (e.g., $-50$) properly accumulates into a 32-bit two's-complement accumulator.
- **Dedicated Clear (`clr_acc`)**: Allows restarting back-to-back matrix streams without clearing `a_out` and `b_out`, preventing data loss for overlapping workloads.

---

## 3. Deep Dive: ReLU Activation (`relu.v`)

The Rectified Linear Unit is implemented as a clean, single-gate-delay combinational check:
```verilog
assign out_data = in_data[31] ? 32'sd0 : in_data;
```
If bit 31 (sign bit) is 1, the number is negative and immediately forced to `0`. If 0, the full 32-bit positive value passes untouched.

---

## 4. Deep Dive: INT32-to-INT8 Quantization (`quantizer.v`)

Truncating lower bits introduces systematic negative round-off error (bias). To achieve neural network inference accuracy, our quantizer implements **convergent rounding and saturation**:

```verilog
wire signed [31:0] rounded_val;
generate
    if (SHIFT > 0) begin : gen_round
        assign rounded_val = (in_data + (32'sd1 <<< (SHIFT - 1))) >>> SHIFT;
    end else begin : gen_no_shift
        assign rounded_val = in_data;
    end
endgenerate

always @(*) begin
    if (rounded_val > 32'sd127) begin
        out_data = 8'sd127;     // Positive saturation clamp
    end else if (rounded_val < -32'sd128) begin
        out_data = -8'sd128;    // Negative saturation clamp
    end else begin
        out_data = rounded_val[7:0];
    end
end
```
1. **Half-LSB Addition**: Adds $2^{\text{SHIFT}-1}$ prior to right-shifting to achieve true mathematical round-to-nearest integer.
2. **Arithmetic Shift**: Uses `>>>` so the sign bit is preserved during division by $2^{\text{SHIFT}}$.
3. **Clamping**: Prevents overflow wrap-around (where $+128$ wraps to $-128$) by clipping to $[-128, +127]$.

---

## 5. Latency Tracker & FSM

To signal when the entire array has finished:
- Injection takes **5 cycles** ($0$ to $4$).
- Corner element $\text{PE}_{22}$ finishes its last multiplication on **Cycle 7**.
- An internal 4-bit synchronous counter (`cycle_cnt`) raises `valid_out` on Cycle 7 and drops `busy`, giving upstream masters a clean handshake interface.
