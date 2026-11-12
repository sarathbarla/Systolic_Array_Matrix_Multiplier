// Quantizer: Converts signed 32-bit accumulated values to signed 8-bit integers
// Includes configurable arithmetic right shift, rounding to nearest integer, and saturation.

module quantizer #(
    parameter integer SHIFT = 0 // Number of bits to right-shift (scale factor)
)(
    input  wire signed [31:0] in_data,
    output reg  signed [7:0]  out_data
);

    // Rounding offset: 1 << (SHIFT - 1) for SHIFT > 0
    wire signed [31:0] rounded_val;
    generate
        if (SHIFT > 0) begin : gen_round
            assign rounded_val = (in_data + (32'sd1 <<< (SHIFT - 1))) >>> SHIFT;
        end else begin : gen_no_shift
            assign rounded_val = in_data;
        end
    endgenerate

    // Signed saturation clamp: [-128, +127]
    always @(*) begin
        if (rounded_val > 32'sd127) begin
            out_data = 8'sd127;
        end else if (rounded_val < -32'sd128) begin
            out_data = -8'sd128;
        end else begin
            out_data = rounded_val[7:0];
        end
    end

endmodule
