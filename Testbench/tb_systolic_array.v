// Self-Checking Testbench for 3x3 Signed INT8 Systolic Array Multiplier
// Includes reference model, handshake verification, signed tests,
// corner cases, accumulator clearing, and back-to-back operations.

`timescale 1ns/1ps

module tb_systolic_array;

    parameter integer QUANT_SHIFT = 4; // Shift factor for testing

    reg                       clk;
    reg                       rst_n;
    reg                       start;
    reg                       valid_in;
    reg                       clr_acc;

    reg  signed [7:0]         a_row0, a_row1, a_row2;
    reg  signed [7:0]         b_col0, b_col1, b_col2;

    wire signed [31:0]        c00, c01, c02;
    wire signed [31:0]        c10, c11, c12;
    wire signed [31:0]        c20, c21, c22;

    wire signed [31:0]        c00_relu, c01_relu, c02_relu;
    wire signed [31:0]        c10_relu, c11_relu, c12_relu;
    wire signed [31:0]        c20_relu, c21_relu, c22_relu;

    wire signed [7:0]         c00_quant, c01_quant, c02_quant;
    wire signed [7:0]         c10_quant, c11_quant, c12_quant;
    wire signed [7:0]         c20_quant, c21_quant, c22_quant;

    wire                      busy;
    wire                      valid_out;

    // Instantiate Device Under Test (DUT)
    systolic_array_3x3 #(
        .QUANT_SHIFT (QUANT_SHIFT)
    ) dut (
        .clk       (clk),
        .rst_n     (rst_n),
        .start     (start),
        .valid_in  (valid_in),
        .clr_acc   (clr_acc),
        .busy      (busy),
        .valid_out (valid_out),

        .a_row0    (a_row0), .a_row1 (a_row1), .a_row2 (a_row2),
        .b_col0    (b_col0), .b_col1 (b_col1), .b_col2 (b_col2),

        .c00(c00), .c01(c01), .c02(c02),
        .c10(c10), .c11(c11), .c12(c12),
        .c20(c20), .c21(c21), .c22(c22),

        .c00_relu(c00_relu), .c01_relu(c01_relu), .c02_relu(c02_relu),
        .c10_relu(c10_relu), .c11_relu(c11_relu), .c12_relu(c12_relu),
        .c20_relu(c20_relu), .c21_relu(c21_relu), .c22_relu(c22_relu),

        .c00_quant(c00_quant), .c01_quant(c01_quant), .c02_quant(c02_quant),
        .c10_quant(c10_quant), .c11_quant(c11_quant), .c12_quant(c12_quant),
        .c20_quant(c20_quant), .c21_quant(c21_quant), .c22_quant(c22_quant)
    );

    // 100 MHz clock generation (10 ns period)
    initial clk = 0;
    always #5 clk = ~clk;

    // Test stimulus and golden reference matrices
    reg signed [7:0]  A_mat [0:2][0:2];
    reg signed [7:0]  B_mat [0:2][0:2];
    reg signed [31:0] golden_C [0:2][0:2];
    reg signed [31:0] golden_relu [0:2][0:2];
    reg signed [7:0]  golden_quant [0:2][0:2];

    integer error_count = 0;
    integer test_id = 0;

    // Golden model calculation task
    task compute_golden;
        integer r, c, k;
        reg signed [31:0] temp_round;
        begin
            for (r = 0; r < 3; r = r + 1) begin
                for (c = 0; c < 3; c = c + 1) begin
                    // Matrix multiplication
                    golden_C[r][c] = (A_mat[r][0] * B_mat[0][c]) +
                                     (A_mat[r][1] * B_mat[1][c]) +
                                     (A_mat[r][2] * B_mat[2][c]);

                    // Golden ReLU
                    golden_relu[r][c] = (golden_C[r][c] < 0) ? 32'sd0 : golden_C[r][c];

                    // Golden Quantization (shift + round + saturate)
                    temp_round = (golden_relu[r][c] + (32'sd1 <<< (QUANT_SHIFT - 1))) >>> QUANT_SHIFT;
                    if (temp_round > 32'sd127)
                        golden_quant[r][c] = 8'sd127;
                    else if (temp_round < -32'sd128)
                        golden_quant[r][c] = -8'sd128;
                    else
                        golden_quant[r][c] = temp_round[7:0];
                end
            end
        end
    endtask

    // Matrix injection task with automatic skewing
    task run_matrix_multiply;
        input [255:0] test_name;
        integer cyc;
        begin
            test_id = test_id + 1;
            $display("\n------------------------------------------------------------");
            $display("Running Test %0d: %0s", test_id, test_name);
            $display("------------------------------------------------------------");

            compute_golden();

            // Clear accumulators before new transaction
            @(posedge clk);
            clr_acc = 1'b1;
            @(posedge clk);
            clr_acc = 1'b0;

            // Start transaction
            start = 1'b1;
            valid_in = 1'b1;

            // Stream skewed operands over 5 clock cycles
            for (cyc = 0; cyc < 5; cyc = cyc + 1) begin
                a_row0 = (cyc < 3) ? A_mat[0][cyc]     : 8'sd0;
                a_row1 = (cyc >= 1 && cyc < 4) ? A_mat[1][cyc-1] : 8'sd0;
                a_row2 = (cyc >= 2 && cyc < 5) ? A_mat[2][cyc-2] : 8'sd0;

                b_col0 = (cyc < 3) ? B_mat[cyc][0]     : 8'sd0;
                b_col1 = (cyc >= 1 && cyc < 4) ? B_mat[cyc-1][1] : 8'sd0;
                b_col2 = (cyc >= 2 && cyc < 5) ? B_mat[cyc-2][2] : 8'sd0;

                @(posedge clk);
                start = 1'b0; // start is a 1-cycle pulse
            end

            // De-assert valid_in and zero out inputs
            valid_in = 1'b0;
            a_row0 = 8'sd0; a_row1 = 8'sd0; a_row2 = 8'sd0;
            b_col0 = 8'sd0; b_col1 = 8'sd0; b_col2 = 8'sd0;

            // Wait for hardware valid_out flag
            wait(valid_out == 1'b1);
            @(posedge clk);

            // Compare hardware results with golden model
            check_results();
        end
    endtask

    // Verification check task
    task check_results;
        reg signed [31:0] hw_c [0:2][0:2];
        reg signed [31:0] hw_relu [0:2][0:2];
        reg signed [7:0]  hw_quant [0:2][0:2];
        integer r, c;
        integer local_errors;
        begin
            hw_c[0][0] = c00; hw_c[0][1] = c01; hw_c[0][2] = c02;
            hw_c[1][0] = c10; hw_c[1][1] = c11; hw_c[1][2] = c12;
            hw_c[2][0] = c20; hw_c[2][1] = c21; hw_c[2][2] = c22;

            hw_relu[0][0] = c00_relu; hw_relu[0][1] = c01_relu; hw_relu[0][2] = c02_relu;
            hw_relu[1][0] = c10_relu; hw_relu[1][1] = c11_relu; hw_relu[1][2] = c12_relu;
            hw_relu[2][0] = c20_relu; hw_relu[2][1] = c21_relu; hw_relu[2][2] = c22_relu;

            hw_quant[0][0] = c00_quant; hw_quant[0][1] = c01_quant; hw_quant[0][2] = c02_quant;
            hw_quant[1][0] = c10_quant; hw_quant[1][1] = c11_quant; hw_quant[1][2] = c12_quant;
            hw_quant[2][0] = c20_quant; hw_quant[2][1] = c21_quant; hw_quant[2][2] = c22_quant;

            local_errors = 0;
            for (r = 0; r < 3; r = r + 1) begin
                for (c = 0; c < 3; c = c + 1) begin
                    if (hw_c[r][c] !== golden_C[r][c] ||
                        hw_relu[r][c] !== golden_relu[r][c] ||
                        hw_quant[r][c] !== golden_quant[r][c]) begin
                        $display("MISMATCH at C[%0d][%0d]!", r, c);
                        $display("  Raw   : HW = %0d, Expected = %0d", hw_c[r][c], golden_C[r][c]);
                        $display("  ReLU  : HW = %0d, Expected = %0d", hw_relu[r][c], golden_relu[r][c]);
                        $display("  Quant : HW = %0d, Expected = %0d", hw_quant[r][c], golden_quant[r][c]);
                        local_errors = local_errors + 1;
                        error_count = error_count + 1;
                    end
                end
            end

            if (local_errors == 0) begin
                $display("Status: PASS (All 9 elements matched expected values)");
                $display("C[0][0]=%0d, C[0][1]=%0d, C[0][2]=%0d", hw_c[0][0], hw_c[0][1], hw_c[0][2]);
                $display("C[1][0]=%0d, C[1][1]=%0d, C[1][2]=%0d", hw_c[1][0], hw_c[1][1], hw_c[1][2]);
                $display("C[2][0]=%0d, C[2][1]=%0d, C[2][2]=%0d", hw_c[2][0], hw_c[2][1], hw_c[2][2]);
            end else begin
                $display("Status: FAIL (%0d mismatches in this test)", local_errors);
            end
        end
    endtask

    // Main test sequence
    initial begin
        // Reset initialization
        rst_n = 1'b0;
        start = 1'b0;
        valid_in = 1'b0;
        clr_acc = 1'b0;
        a_row0 = 0; a_row1 = 0; a_row2 = 0;
        b_col0 = 0; b_col1 = 0; b_col2 = 0;

        repeat(3) @(posedge clk);
        rst_n = 1'b1;
        repeat(2) @(posedge clk);

        // TEST 1: Positive matrix (original baseline test case)
        A_mat[0][0]=1; A_mat[0][1]=2; A_mat[0][2]=3;
        A_mat[1][0]=4; A_mat[1][1]=5; A_mat[1][2]=6;
        A_mat[2][0]=7; A_mat[2][1]=8; A_mat[2][2]=9;

        B_mat[0][0]=7; B_mat[0][1]=8; B_mat[0][2]=9;
        B_mat[1][0]=6; B_mat[1][1]=5; B_mat[1][2]=4;
        B_mat[2][0]=3; B_mat[2][1]=2; B_mat[2][2]=1;
        run_matrix_multiply("All Positive Matrices");

        // TEST 2: Mixed-sign matrices (verifies signed math + ReLU clipping of negative results)
        A_mat[0][0]=-2; A_mat[0][1]=3;  A_mat[0][2]=-1;
        A_mat[1][0]=5;  A_mat[1][1]=-4; A_mat[1][2]=2;
        A_mat[2][0]=-3; A_mat[2][1]=1;  A_mat[2][2]=-6;

        B_mat[0][0]=4;  B_mat[0][1]=-2; B_mat[0][2]=1;
        B_mat[1][0]=-3; B_mat[1][1]=5;  B_mat[1][2]=-2;
        B_mat[2][0]=2;  B_mat[2][1]=-1; B_mat[2][2]=3;
        run_matrix_multiply("Mixed-Sign Matrices");

        // TEST 3: All-negative matrices (Negative x Negative = Positive)
        A_mat[0][0]=-1; A_mat[0][1]=-2; A_mat[0][2]=-3;
        A_mat[1][0]=-4; A_mat[1][1]=-5; A_mat[1][2]=-6;
        A_mat[2][0]=-7; A_mat[2][1]=-8; A_mat[2][2]=-9;

        B_mat[0][0]=-7; B_mat[0][1]=-8; B_mat[0][2]=-9;
        B_mat[1][0]=-6; B_mat[1][1]=-5; B_mat[1][2]=-4;
        B_mat[2][0]=-3; B_mat[2][1]=-2; B_mat[2][2]=-1;
        run_matrix_multiply("All Negative Matrices");

        // TEST 4: Zero matrix
        A_mat[0][0]=0; A_mat[0][1]=0; A_mat[0][2]=0;
        A_mat[1][0]=0; A_mat[1][1]=0; A_mat[1][2]=0;
        A_mat[2][0]=0; A_mat[2][1]=0; A_mat[2][2]=0;

        B_mat[0][0]=10; B_mat[0][1]=20; B_mat[0][2]=30;
        B_mat[1][0]=40; B_mat[1][1]=50; B_mat[1][2]=60;
        B_mat[2][0]=70; B_mat[2][1]=80; B_mat[2][2]=90;
        run_matrix_multiply("Zero Matrix Multiplication");

        // TEST 5: Maximum positive INT8 (+127) boundary test
        A_mat[0][0]=127; A_mat[0][1]=127; A_mat[0][2]=127;
        A_mat[1][0]=127; A_mat[1][1]=127; A_mat[1][2]=127;
        A_mat[2][0]=127; A_mat[2][1]=127; A_mat[2][2]=127;

        B_mat[0][0]=127; B_mat[0][1]=127; B_mat[0][2]=127;
        B_mat[1][0]=127; B_mat[1][1]=127; B_mat[1][2]=127;
        B_mat[2][0]=127; B_mat[2][1]=127; B_mat[2][2]=127;
        run_matrix_multiply("Maximum Positive Values (+127)");

        // TEST 6: Minimum negative INT8 (-128) boundary test
        A_mat[0][0]=-128; A_mat[0][1]=0;    A_mat[0][2]=0;
        A_mat[1][0]=0;    A_mat[1][1]=-128; A_mat[1][2]=0;
        A_mat[2][0]=0;    A_mat[2][1]=0;    A_mat[2][2]=-128;

        B_mat[0][0]=-128; B_mat[0][1]=0;    B_mat[0][2]=0;
        B_mat[1][0]=0;    B_mat[1][1]=-128; B_mat[1][2]=0;
        B_mat[2][0]=0;    B_mat[2][1]=0;    B_mat[2][2]=-128;
        run_matrix_multiply("Minimum Negative Values (-128)");

        // TEST 7: Back-to-Back Consecutive Transactions (No global reset)
        A_mat[0][0]=2; A_mat[0][1]=1; A_mat[0][2]=0;
        A_mat[1][0]=0; A_mat[1][1]=2; A_mat[1][2]=1;
        A_mat[2][0]=1; A_mat[2][1]=0; A_mat[2][2]=2;

        B_mat[0][0]=1; B_mat[0][1]=2; B_mat[0][2]=3;
        B_mat[1][0]=4; B_mat[1][1]=5; B_mat[1][2]=6;
        B_mat[2][0]=7; B_mat[2][1]=8; B_mat[2][2]=9;
        run_matrix_multiply("Back-to-Back Transaction");

        // Summary
        $display("\n============================================================");
        $display("                   FINAL VERIFICATION REPORT                ");
        $display("============================================================");
        if (error_count == 0) begin
            $display("ALL TESTS PASSED SUCCESSFULLY! (Total Mismatches = 0)");
        end else begin
            $display("VERIFICATION FAILED WITH %0d TOTAL MISMATCHES!", error_count);
        end
        $display("============================================================\n");

        $finish;
    end

    // VCD waveform dump
    initial begin
        $dumpfile("systolic_array.vcd");
        $dumpvars(0, tb_systolic_array);
    end

endmodule
