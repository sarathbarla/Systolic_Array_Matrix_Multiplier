// 3x3 Systolic Array Matrix Multiplier with Activation and Quantization
// Computes C (3x3) = A (3x3) * B (3x3) with signed 8-bit inputs.
// Outputs:
//   - Raw 32-bit accumulators
//   - Post-ReLU 32-bit activations
//   - Quantized 8-bit outputs with rounding and saturation

module systolic_array_3x3 #(
    parameter integer QUANT_SHIFT = 0 // Arithmetic right shift for output quantization
)(
    input  wire                      clk,
    input  wire                      rst_n,     // Active-low asynchronous reset

    // Control and Handshake Interface
    input  wire                      start,     // Pulse high for 1 cycle to start new matrix multiply
    input  wire                      valid_in,  // Asserted while valid skewed input data is presented
    input  wire                      clr_acc,   // Synchronously clears all PE accumulators
    output reg                       busy,      // High while array is actively processing
    output reg                       valid_out, // High when all 9 matrix outputs are complete

    // Skewed Matrix A inputs (Row 0, 1, 2)
    input  wire signed [7:0]         a_row0,    
    input  wire signed [7:0]         a_row1,
    input  wire signed [7:0]         a_row2,    

    // Skewed Matrix B inputs (Col 0, 1, 2)
    input  wire signed [7:0]         b_col0,    
    input  wire signed [7:0]         b_col1,    
    input  wire signed [7:0]         b_col2,   

    // Raw 32-bit accumulated outputs
    output wire signed [31:0]        c00, c01, c02,
    output wire signed [31:0]        c10, c11, c12,
    output wire signed [31:0]        c20, c21, c22,

    // Post-ReLU 32-bit activated outputs
    output wire signed [31:0]        c00_relu, c01_relu, c02_relu,
    output wire signed [31:0]        c10_relu, c11_relu, c12_relu,
    output wire signed [31:0]        c20_relu, c21_relu, c22_relu,

    // Quantized 8-bit outputs
    output wire signed [7:0]         c00_quant, c01_quant, c02_quant,
    output wire signed [7:0]         c10_quant, c11_quant, c12_quant,
    output wire signed [7:0]         c20_quant, c21_quant, c22_quant
);

    // Internal inter-PE routing channels
    wire signed [7:0]  a_wire [0:2][0:3];  
    wire signed [7:0]  b_wire [0:3][0:2];  
    wire signed [31:0] c_out  [0:2][0:2];

    // Gate input data into the array with valid_in
    assign a_wire[0][0] = valid_in ? a_row0 : 8'sd0;
    assign a_wire[1][0] = valid_in ? a_row1 : 8'sd0;
    assign a_wire[2][0] = valid_in ? a_row2 : 8'sd0;

    assign b_wire[0][0] = valid_in ? b_col0 : 8'sd0;
    assign b_wire[0][1] = valid_in ? b_col1 : 8'sd0;
    assign b_wire[0][2] = valid_in ? b_col2 : 8'sd0;

    // 3x3 Processing Element Grid
    genvar i, j;
    generate
        for (i = 0; i < 3; i = i + 1) begin : row_gen
            for (j = 0; j < 3; j = j + 1) begin : col_gen
                pe pe_inst (
                    .clk     (clk),
                    .rst_n   (rst_n),
                    .clr_acc (clr_acc),
                    .a_in    (a_wire[i][j]),
                    .b_in    (b_wire[i][j]),
                    .a_out   (a_wire[i][j+1]),
                    .b_out   (b_wire[i+1][j]),
                    .acc     (c_out[i][j])
                );
            end
        end
    endgenerate

    // Raw 32-bit outputs
    assign c00 = c_out[0][0];  assign c01 = c_out[0][1];  assign c02 = c_out[0][2];
    assign c10 = c_out[1][0];  assign c11 = c_out[1][1];  assign c12 = c_out[1][2];
    assign c20 = c_out[2][0];  assign c21 = c_out[2][1];  assign c22 = c_out[2][2];

    // ReLU and Quantization stages for each PE output
    wire signed [31:0] c_relu_matrix  [0:2][0:2];
    wire signed [7:0]  c_quant_matrix [0:2][0:2];

    generate
        for (i = 0; i < 3; i = i + 1) begin : post_row
            for (j = 0; j < 3; j = j + 1) begin : post_col
                relu relu_inst (
                    .in_data  (c_out[i][j]),
                    .out_data (c_relu_matrix[i][j])
                );

                quantizer #(
                    .SHIFT    (QUANT_SHIFT)
                ) quant_inst (
                    .in_data  (c_relu_matrix[i][j]),
                    .out_data (c_quant_matrix[i][j])
                );
            end
        end
    endgenerate

    // Map ReLU outputs
    assign c00_relu = c_relu_matrix[0][0];  assign c01_relu = c_relu_matrix[0][1];  assign c02_relu = c_relu_matrix[0][2];
    assign c10_relu = c_relu_matrix[1][0];  assign c11_relu = c_relu_matrix[1][1];  assign c12_relu = c_relu_matrix[1][2];
    assign c20_relu = c_relu_matrix[2][0];  assign c21_relu = c_relu_matrix[2][1];  assign c22_relu = c_relu_matrix[2][2];

    // Map Quantized outputs
    assign c00_quant = c_quant_matrix[0][0];  assign c01_quant = c_quant_matrix[0][1];  assign c02_quant = c_quant_matrix[0][2];
    assign c10_quant = c_quant_matrix[1][0];  assign c11_quant = c_quant_matrix[1][1];  assign c12_quant = c_quant_matrix[1][2];
    assign c20_quant = c_quant_matrix[2][0];  assign c21_quant = c_quant_matrix[2][1];  assign c22_quant = c_quant_matrix[2][2];

    // Transaction tracking logic:
    // Takes 7 active cycles for computation across 3x3 array
    reg [3:0] cycle_cnt;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cycle_cnt <= 4'd0;
            busy      <= 1'b0;
            valid_out <= 1'b0;
        end else begin
            if (start) begin
                busy      <= 1'b1;
                valid_out <= 1'b0;
                cycle_cnt <= 4'd1;
            end else if (busy) begin
                if (cycle_cnt == 4'd7) begin
                    busy      <= 1'b0;
                    valid_out <= 1'b1;
                    cycle_cnt <= 4'd0;
                end else begin
                    cycle_cnt <= cycle_cnt + 4'd1;
                end
            end else begin
                valid_out <= 1'b0;
            end
        end
    end

endmodule
