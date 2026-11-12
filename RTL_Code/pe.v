// Processing Element (PE)
// Performs signed 8-bit multiplication and 32-bit accumulation.
// Data flows horizontally (A: left to right) and vertically (B: top to bottom).

module pe (
    input  wire                      clk,
    input  wire                      rst_n,     // Active-low asynchronous reset
    input  wire                      clr_acc,   // Synchronous accumulator clear
    input  wire signed [7:0]         a_in,      // Input data from left
    input  wire signed [7:0]         b_in,      // Input data from top
    output reg  signed [7:0]         a_out,     // Forwarded data to right
    output reg  signed [7:0]         b_out,     // Forwarded data to bottom
    output reg  signed [31:0]        acc        // Accumulated output
);

    // 8-bit x 8-bit signed multiplication gives 16-bit product
    wire signed [15:0] product = a_in * b_in;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_out <= 8'sd0;
            b_out <= 8'sd0;
            acc   <= 32'sd0;
        end else begin
            // Forward inputs to neighboring PEs with 1-cycle pipeline delay
            a_out <= a_in;
            b_out <= b_in;

            // Clear accumulator when requested, otherwise accumulate partial products
            if (clr_acc) begin
                acc <= 32'sd0;
            end else begin
                acc <= acc + {{16{product[15]}}, product};
            end
        end
    end

endmodule
