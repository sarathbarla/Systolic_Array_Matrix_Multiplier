// ============================================================
// Testbench : tb_systolic_array
// Description : Feeds two 3x3 matrices into the systolic array
//               and checks the output against expected results.
//
// Test Case:
//   A = | 1 2 3 |    B = | 7 8 9 |
//       | 4 5 6 |        | 6 5 4 |
//       | 7 8 9 |        | 3 2 1 |
//
//   Expected C = A * B:
//   C[0][0] = 1*7 + 2*6 + 3*3 = 7+12+9   = 28
//   C[0][1] = 1*8 + 2*5 + 3*2 = 8+10+6   = 24
//   C[0][2] = 1*9 + 2*4 + 3*1 = 9+8+3    = 20
//   C[1][0] = 4*7 + 5*6 + 6*3 = 28+30+18 = 76
//   C[1][1] = 4*8 + 5*5 + 6*2 = 32+25+12 = 69
//   C[1][2] = 4*9 + 5*4 + 6*1 = 36+20+6  = 62
//   C[2][0] = 7*7 + 8*6 + 9*3 = 49+48+27 = 124
//   C[2][1] = 7*8 + 8*5 + 9*2 = 56+40+18 = 114
//   C[2][2] = 7*9 + 8*4 + 9*1 = 63+32+9  = 104
// ============================================================

`timescale 1ns/1ps

module tb_systolic_array;

    // -------------------------------------------------------
    // DUT (Device Under Test) signal declarations
    // -------------------------------------------------------
    reg        clk;
    reg        rst_n;

    reg [7:0]  a_row0, a_row1, a_row2;
    reg [7:0]  b_col0, b_col1, b_col2;

    wire [31:0] c00, c01, c02;
    wire [31:0] c10, c11, c12;
    wire [31:0] c20, c21, c22;

    // -------------------------------------------------------
    // Instantiate the DUT
    // -------------------------------------------------------
    systolic_array_3x3 dut (
        .clk    (clk),
        .rst_n  (rst_n),
        .a_row0 (a_row0), .a_row1 (a_row1), .a_row2 (a_row2),
        .b_col0 (b_col0), .b_col1 (b_col1), .b_col2 (b_col2),
        .c00(c00), .c01(c01), .c02(c02),
        .c10(c10), .c11(c11), .c12(c12),
        .c20(c20), .c21(c21), .c22(c22)
    );

    // -------------------------------------------------------
    // Clock generation: 10ns period
    // -------------------------------------------------------
    initial clk = 0;
    always #5 clk = ~clk;   // Toggle every 5ns => 10ns period

    // -------------------------------------------------------
    // Matrix A values (rows fed left to right, element by element)
    // A = | 1 2 3 |
    //     | 4 5 6 |
    //     | 7 8 9 |
    //
    // Matrix B values (columns fed top to bottom, element by element)
    // B = | 7 8 9 |
    //     | 6 5 4 |
    //     | 3 2 1 |
    //
    // KEY CONCEPT - SKEWING:
    // Cycle 0: Feed A[0][0], B[0][0] to PE[0][0] — first elements meet here
    // Cycle 1: Feed A[0][1], B[1][0] to PE[0][0] — second elements meet here
    //          Feed A[1][0], B[0][1] to PE[1][0] and PE[0][1] — delayed start
    // And so on...
    //
    // To implement skewing: row1 starts 1 cycle after row0,
    //                       row2 starts 2 cycles after row0
    //                       (same for columns)
    // We do this by feeding 0s initially then the real values
    // -------------------------------------------------------

    // A matrix rows (each row is 3 elements, fed one per cycle)
    // Row 0: 1, 2, 3
    // Row 1: 4, 5, 6  (skewed: starts 1 cycle late)
    // Row 2: 7, 8, 9  (skewed: starts 2 cycles late)
    reg [7:0] A [0:2][0:2];
    reg [7:0] B [0:2][0:2];

    integer cycle;

    initial begin
        // Initialize matrices
        A[0][0]=1; A[0][1]=2; A[0][2]=3;
        A[1][0]=4; A[1][1]=5; A[1][2]=6;
        A[2][0]=7; A[2][1]=8; A[2][2]=9;

        B[0][0]=7; B[0][1]=8; B[0][2]=9;
        B[1][0]=6; B[1][1]=5; B[1][2]=4;
        B[2][0]=3; B[2][1]=2; B[2][2]=1;

        // Apply reset
        rst_n = 0;
        a_row0 = 0; a_row1 = 0; a_row2 = 0;
        b_col0 = 0; b_col1 = 0; b_col2 = 0;

        @(posedge clk); #1;  // Wait one clock then release reset
        rst_n = 1;

        // ---------------------------------------------------
        // Feed data with skewing over 5 cycles
        // Cycle 0: row0[0], col0[0]         (only first PE gets real data)
        // Cycle 1: row0[1], row1[0]         (row1 starts, col skewing same)
        // Cycle 2: row0[2], row1[1], row2[0] (all rows active)
        // Cycle 3: row1[2], row2[1]
        // Cycle 4: row2[2]
        // After 5 cycles of feeding + propagation delay, results are valid
        // ---------------------------------------------------

        for (cycle = 0; cycle < 7; cycle = cycle + 1) begin
            @(posedge clk); #1;

            // Feed A rows with skewing
            // Row 0: elements at index 'cycle' (valid for cycle 0,1,2)
            a_row0 = (cycle < 3) ? A[0][cycle]     : 8'd0;
            // Row 1: skewed by 1, so reads A[1][cycle-1] (valid for cycle 1,2,3)
            a_row1 = (cycle >= 1 && cycle < 4) ? A[1][cycle-1] : 8'd0;
            // Row 2: skewed by 2, so reads A[2][cycle-2] (valid for cycle 2,3,4)
            a_row2 = (cycle >= 2 && cycle < 5) ? A[2][cycle-2] : 8'd0;

            // Feed B columns with skewing (same logic, applied to columns)
            b_col0 = (cycle < 3) ? B[cycle][0]     : 8'd0;
            b_col1 = (cycle >= 1 && cycle < 4) ? B[cycle-1][1] : 8'd0;
            b_col2 = (cycle >= 2 && cycle < 5) ? B[cycle-2][2] : 8'd0;
        end

        // Wait a few more cycles for accumulation to complete
        repeat(5) @(posedge clk);

        // ---------------------------------------------------
        // Display and verify results
        // ---------------------------------------------------
        $display("======================================");
        $display("  Systolic Array 3x3 Results");
        $display("======================================");
        $display("C[0][0] = %0d (expected 28)",  c00);
        $display("C[0][1] = %0d (expected 24)",  c01);
        $display("C[0][2] = %0d (expected 20)",  c02);
        $display("C[1][0] = %0d (expected 76)",  c10);
        $display("C[1][1] = %0d (expected 69)",  c11);
        $display("C[1][2] = %0d (expected 62)",  c12);
        $display("C[2][0] = %0d (expected 124)", c20);
        $display("C[2][1] = %0d (expected 114)", c21);
        $display("C[2][2] = %0d (expected 104)", c22);
        $display("======================================");

        // Automated pass/fail check
        if (c00==28 && c01==24 && c02==20 &&
            c10==76 && c11==69 && c12==62 &&
            c20==124 && c21==114 && c22==104)
            $display("ALL RESULTS CORRECT - PASS");
        else
            $display("MISMATCH DETECTED - FAIL");

        $finish;
    end

    // Optional: dump waveform for GTKWave
    initial begin
        $dumpfile("systolic_array.vcd");
        $dumpvars(0, tb_systolic_array);
    end

endmodule