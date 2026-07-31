// Module : systolic_array_3x3
// Description : 3x3 systolic array to multiply two 3x3 matrices
//               A (3x3) * B (3x3) = C (3x3)

module systolic_array_3x3 (
    input  wire        clk,
    input  wire        rst_n,

    // Row inputs for Matrix A 
    input  wire [7:0]  a_row0,    
    input  wire [7:0]  a_row1,
    input  wire [7:0]  a_row2,    

    // Column inputs for Matrix B 
    input  wire [7:0]  b_col0,    
    input  wire [7:0]  b_col1,    
    input  wire [7:0]  b_col2,   

    // Output: 9 accumulated results = C matrix elements
    output wire [31:0] c00, c01, c02,
    output wire [31:0] c10, c11, c12,
    output wire [31:0] c20, c21, c22
);

    // Internal wires to connect PEs together
    wire [7:0] a_wire [0:2][0:3];  
    wire [7:0] b_wire [0:3][0:2];  
    // Internal accumulator wires for the generate block
    wire [31:0] c_out [0:2][0:2];

    assign a_wire[0][0] = a_row0;
    assign a_wire[1][0] = a_row1;
    assign a_wire[2][0] = a_row2;

    assign b_wire[0][0] = b_col0;
    assign b_wire[0][1] = b_col1;
    assign b_wire[0][2] = b_col2;

    genvar i, j;
    generate
        for (i = 0; i < 3; i = i + 1) begin : row_gen
            for (j = 0; j < 3; j = j + 1) begin : col_gen
                pe pe_inst (
                    .clk   (clk),
                    .rst_n (rst_n),
                    .a_in  (a_wire[i][j]),      // A comes from the left
                    .b_in  (b_wire[i][j]),      // B comes from above
                    .a_out (a_wire[i][j+1]),    // A passes to the right
                    .b_out (b_wire[i+1][j]),    // B passes downward
                    .acc   (c_out[i][j])        // Result accumulates here
                );
            end
        end
    endgenerate

    // Mapping internal results to output ports
    assign c00 = c_out[0][0];  assign c01 = c_out[0][1];  assign c02 = c_out[0][2];
    assign c10 = c_out[1][0];  assign c11 = c_out[1][1];  assign c12 = c_out[1][2];
    assign c20 = c_out[2][0];  assign c21 = c_out[2][1];  assign c22 = c_out[2][2];

endmodule
