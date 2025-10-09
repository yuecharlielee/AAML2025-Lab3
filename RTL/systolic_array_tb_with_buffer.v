`timescale 1ns / 1ps

module systolic_array_tb_with_buffer;

    reg rst_n;
    reg clk;
    reg [31:0] in_a_raw;
    reg [31:0] in_b_raw;
    wire [31:0] in_a_skewed;
    wire [31:0] in_b_skewed;
    wire [63:0] out_c_r1;
    wire [63:0] out_c_r2;
    wire [63:0] out_c_r3;
    wire [63:0] out_c_r4;

    // Test matrices
    reg [7:0] matrix_a [0:3][0:3];
    reg [7:0] matrix_b [0:3][0:3];
    
    integer i, j, cycle;

    // Buffer modules
    buffer buffer_a (
        .clk(clk),
        .rst_n(rst_n),
        .in_data(in_a_raw),
        .out_data(in_a_skewed)
    );

    buffer buffer_b (
        .clk(clk),
        .rst_n(rst_n),
        .in_data(in_b_raw),
        .out_data(in_b_skewed)
    );

    systolic_array uut (
        .rst_n(rst_n),
        .clk(clk),
        .in_a(in_a_skewed),
        .in_b(in_b_skewed),
        .out_c_r1(out_c_r1),
        .out_c_r2(out_c_r2),
        .out_c_r3(out_c_r3),
        .out_c_r4(out_c_r4)
    );

    // Clock generation
    always #5 clk = ~clk;

    initial begin
        $dumpfile("systolic_array_tb.vcd");
        $dumpvars(0, systolic_array_tb_with_buffer);
        
        // Initialize
        clk = 0;
        rst_n = 0;
        in_a_raw = 0;
        in_b_raw = 0;
        
        // Initialize test matrices
        matrix_a[0][0] = 8'd1;  matrix_a[0][1] = 8'd2;  matrix_a[0][2] = 8'd3;  matrix_a[0][3] = 8'd4;
        matrix_a[1][0] = 8'd5;  matrix_a[1][1] = 8'd6;  matrix_a[1][2] = 8'd7;  matrix_a[1][3] = 8'd8;
        matrix_a[2][0] = 8'd9;  matrix_a[2][1] = 8'd10; matrix_a[2][2] = 8'd11; matrix_a[2][3] = 8'd12;
        matrix_a[3][0] = 8'd13; matrix_a[3][1] = 8'd14; matrix_a[3][2] = 8'd15; matrix_a[3][3] = 8'd16;
        
        // Matrix B (Identity)
        matrix_b[0][0] = 8'd1;  matrix_b[0][1] = 8'd0;  matrix_b[0][2] = 8'd0;  matrix_b[0][3] = 8'd0;
        matrix_b[1][0] = 8'd0;  matrix_b[1][1] = 8'd1;  matrix_b[1][2] = 8'd0;  matrix_b[1][3] = 8'd0;
        matrix_b[2][0] = 8'd0;  matrix_b[2][1] = 8'd0;  matrix_b[2][2] = 8'd1;  matrix_b[2][3] = 8'd0;
        matrix_b[3][0] = 8'd0;  matrix_b[3][1] = 8'd0;  matrix_b[3][2] = 8'd0;  matrix_b[3][3] = 8'd1;

        // Reset
        #10 rst_n = 1;
        #10;

        $display("=== Test 1: A^T × I (Identity Matrix) ===");
        $display("Feeding columns of A (= rows of A^T) and columns of B");
        
        // Feed 4 cycles: columns of A and columns of B
        for (cycle = 0; cycle < 4; cycle = cycle + 1) begin
            // Feed column of A (this becomes row of A^T)
            in_a_raw[31:24] = matrix_a[0][cycle];
            in_a_raw[23:16] = matrix_a[1][cycle];
            in_a_raw[15:8]  = matrix_a[2][cycle];
            in_a_raw[7:0]   = matrix_a[3][cycle];

            // Feed column of B
            in_b_raw[31:24] = matrix_b[0][cycle];
            in_b_raw[23:16] = matrix_b[1][cycle];
            in_b_raw[15:8]  = matrix_b[2][cycle];
            in_b_raw[7:0]   = matrix_b[3][cycle];

            #10;
            $display("Cycle %0d: A col %0d, B col %0d", cycle, cycle, cycle);
            $display("  in_a_raw=%h, in_b_raw=%h", in_a_raw, in_b_raw);
            $display("  in_a_skewed=%h, in_b_skewed=%h", in_a_skewed, in_b_skewed);
        end

        // Let data propagate and compute
        in_a_raw = 0;
        in_b_raw = 0;
        repeat(10) #10;

        $display("\nExpected: A^T = [[1,5,9,13], [2,6,10,14], [3,7,11,15], [4,8,12,16]]");
        $display("Row 1: %h (expect: 0001 0005 0009 000d)", out_c_r1);
        $display("Row 2: %h (expect: 0002 0006 000a 000e)", out_c_r2);
        $display("Row 3: %h (expect: 0003 0007 000b 000f)", out_c_r3);
        $display("Row 4: %h (expect: 0004 0008 000c 0010)", out_c_r4);

        $display("\n=== All Tests Complete ===");
        $finish;
    end

endmodule
