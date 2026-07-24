// Module : pe (Processing Element)
// Description : Single cell of the systolic array.
//               Each PE does ONE multiply-accumulate (MAC).
//               Data flows: A passes RIGHT, B passes DOWN,
//               and the partial sum accumulates inside.

module pe (
    input  wire        clk,       // Clock
    input  wire        rst_n,     // Active-low reset
    input  wire [7:0]  a_in,      // A matrix data coming from LEFT
    input  wire [7:0]  b_in,      // B matrix data coming from TOP
    output reg  [7:0]  a_out,     // A matrix data going to RIGHT neighbour
    output reg  [7:0]  b_out,     // B matrix data going to BOTTOM neighbour
    output reg  [31:0] acc        // Accumulated result (partial sum)
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_out <= 8'd0;
            b_out <= 8'd0;
            acc   <= 32'd0;
        end else begin
            // Pass A to the right neighbour
            a_out <= a_in;

            // Pass B to the bottom neighbour
            b_out <= b_in;
            
            // This is the MAC operation: acc = acc + (A * B)
            acc   <= acc + (a_in * b_in);
        end
    end

endmodule