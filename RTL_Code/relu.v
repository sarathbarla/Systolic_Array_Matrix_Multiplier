// Rectified Linear Unit (ReLU) Activation
// Sets negative values to 0 and passes non-negative values unchanged.

module relu (
    input  wire signed [31:0] in_data,
    output wire signed [31:0] out_data
);

    // If sign bit is 1 (negative), output 0; otherwise pass in_data
    assign out_data = in_data[31] ? 32'sd0 : in_data;

endmodule
