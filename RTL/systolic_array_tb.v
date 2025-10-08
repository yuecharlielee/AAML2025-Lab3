`timescale 1ns / 1ps

module systolic_array_tb;

    reg rst_n;
    reg clk;
    reg [31:0] in_a;
    reg [31:0] in_b;
    wire [63:0] out_c_r1;
    wire [63:0] out_c_r2;
    wire [63:0] out_c_r3;
    wire [63:0] out_c_r4;

    // Test matrices
    reg [7:0] matrix_a [0:3][0:3]; // Original A matrix
    reg [7:0] matrix_b [0:3][0:3]; // B matrix
    
    integer i, j, cycle;

    systolic_array uut (
        .rst_n(rst_n),
        .clk(clk),
        .in_a(in_a),
        .in_b(in_b),
        .out_c_r1(out_c_r1),
        .out_c_r2(out_c_r2),
        .out_c_r3(out_c_r3),
        .out_c_r4(out_c_r4)
    );

    // Clock generation
    always #5 clk = ~clk;

    initial begin
        // Initialize
        clk = 0;
        rst_n = 0;
        in_a = 0;
        in_b = 0;
        
        // Initialize test matrices
        // Matrix A (will be transposed when fed)
        matrix_a[0][0] = 8'd1;  matrix_a[0][1] = 8'd2;  matrix_a[0][2] = 8'd3;  matrix_a[0][3] = 8'd4;
        matrix_a[1][0] = 8'd5;  matrix_a[1][1] = 8'd6;  matrix_a[1][2] = 8'd7;  matrix_a[1][3] = 8'd8;
        matrix_a[2][0] = 8'd9;  matrix_a[2][1] = 8'd10; matrix_a[2][2] = 8'd11; matrix_a[2][3] = 8'd12;
        matrix_a[3][0] = 8'd13; matrix_a[3][1] = 8'd14; matrix_a[3][2] = 8'd15; matrix_a[3][3] = 8'd16;
        
        // Matrix B
        matrix_b[0][0] = 8'd1;  matrix_b[0][1] = 8'd0;  matrix_b[0][2] = 8'd0;  matrix_b[0][3] = 8'd0;
        matrix_b[1][0] = 8'd0;  matrix_b[1][1] = 8'd1;  matrix_b[1][2] = 8'd0;  matrix_b[1][3] = 8'd0;
        matrix_b[2][0] = 8'd0;  matrix_b[2][1] = 8'd0;  matrix_b[2][2] = 8'd1;  matrix_b[2][3] = 8'd0;
        matrix_b[3][0] = 8'd0;  matrix_b[3][1] = 8'd0;  matrix_b[3][2] = 8'd0;  matrix_b[3][3] = 8'd1;

        // Reset
        #10 rst_n = 1;
        #10;

        // Feed skewed inputs for 7 cycles (4 + 3 additional cycles)
        for (cycle = 0; cycle < 7; cycle = cycle + 1) begin
            // Skewed A input (transposed) - column-wise feeding
            if (cycle < 4) begin
                in_a[31:24] = matrix_a[0][cycle];    // A[0][cycle] -> top PE
                in_a[23:16] = (cycle >= 1) ? matrix_a[1][cycle-1] : 8'd0;
                in_a[15:8]  = (cycle >= 2) ? matrix_a[2][cycle-2] : 8'd0;
                in_a[7:0]   = (cycle >= 3) ? matrix_a[3][cycle-3] : 8'd0;
            end else begin
                in_a[31:24] = 8'd0;
                in_a[23:16] = (cycle < 5) ? matrix_a[1][cycle-1] : 8'd0;
                in_a[15:8]  = (cycle < 6) ? matrix_a[2][cycle-2] : 8'd0;
                in_a[7:0]   = (cycle < 7) ? matrix_a[3][cycle-3] : 8'd0;
            end

            // Skewed B input - row-wise feeding
            if (cycle < 4) begin
                in_b[31:24] = matrix_b[cycle][0];    // B[cycle][0] -> leftmost PE
                in_b[23:16] = (cycle >= 1) ? matrix_b[cycle-1][1] : 8'd0;
                in_b[15:8]  = (cycle >= 2) ? matrix_b[cycle-2][2] : 8'd0;
                in_b[7:0]   = (cycle >= 3) ? matrix_b[cycle-3][3] : 8'd0;
            end else begin
                in_b[31:24] = 8'd0;
                in_b[23:16] = (cycle < 5) ? matrix_b[cycle-1][1] : 8'd0;
                in_b[15:8]  = (cycle < 6) ? matrix_b[cycle-2][2] : 8'd0;
                in_b[7:0]   = (cycle < 7) ? matrix_b[cycle-3][3] : 8'd0;
            end

            #10;
            $display("Cycle %0d: in_a=%h, in_b=%h", cycle, in_a, in_b);
        end

        // Additional cycles to let computation finish
        in_a = 0;
        in_b = 0;
        repeat(10) #10;

        // Display results
        $display("\nTest 1: A^T × I (Identity Matrix)");
        $display("Expected: A^T = [[1,5,9,13], [2,6,10,14], [3,7,11,15], [4,8,12,16]]");
        $display("Row 1: %h (expect: 0001 0005 0009 000d)", out_c_r1);
        $display("Row 2: %h (expect: 0002 0006 000a 000e)", out_c_r2);
        $display("Row 3: %h (expect: 0003 0007 000b 000f)", out_c_r3);
        $display("Row 4: %h (expect: 0004 0008 000c 0010)", out_c_r4);

        // Test 2: All ones matrix
        $display("\n=== Test 2: A^T × ones(4) ===");
        rst_n = 0;
        #10 rst_n = 1;
        #10;
        
        // Matrix B = all ones
        for (i = 0; i < 4; i = i + 1) begin
            for (j = 0; j < 4; j = j + 1) begin
                matrix_b[i][j] = 8'd1;
            end
        end
        
        for (cycle = 0; cycle < 7; cycle = cycle + 1) begin
            if (cycle < 4) begin
                in_a[31:24] = matrix_a[0][cycle];
                in_a[23:16] = (cycle >= 1) ? matrix_a[1][cycle-1] : 8'd0;
                in_a[15:8]  = (cycle >= 2) ? matrix_a[2][cycle-2] : 8'd0;
                in_a[7:0]   = (cycle >= 3) ? matrix_a[3][cycle-3] : 8'd0;
            end else begin
                in_a[31:24] = 8'd0;
                in_a[23:16] = (cycle < 5) ? matrix_a[1][cycle-1] : 8'd0;
                in_a[15:8]  = (cycle < 6) ? matrix_a[2][cycle-2] : 8'd0;
                in_a[7:0]   = (cycle < 7) ? matrix_a[3][cycle-3] : 8'd0;
            end

            if (cycle < 4) begin
                in_b[31:24] = matrix_b[cycle][0];
                in_b[23:16] = (cycle >= 1) ? matrix_b[cycle-1][1] : 8'd0;
                in_b[15:8]  = (cycle >= 2) ? matrix_b[cycle-2][2] : 8'd0;
                in_b[7:0]   = (cycle >= 3) ? matrix_b[cycle-3][3] : 8'd0;
            end else begin
                in_b[31:24] = 8'd0;
                in_b[23:16] = (cycle < 5) ? matrix_b[cycle-1][1] : 8'd0;
                in_b[15:8]  = (cycle < 6) ? matrix_b[cycle-2][2] : 8'd0;
                in_b[7:0]   = (cycle < 7) ? matrix_b[cycle-3][3] : 8'd0;
            end
            #10;
        end
        
        in_a = 0;
        in_b = 0;
        repeat(10) #10;
        
        $display("Expected: Each row sum = 1+2+3+4=10, 5+6+7+8=26, 9+10+11+12=42, 13+14+15+16=58");
        $display("Row 1: %h (expect: all 000a = 10)", out_c_r1);
        $display("Row 2: %h (expect: all 001a = 26)", out_c_r2);
        $display("Row 3: %h (expect: all 002a = 42)", out_c_r3);
        $display("Row 4: %h (expect: all 003a = 58)", out_c_r4);

        // Test 3: Simple 2x2 within 4x4
        $display("\n=== Test 3: 2x2 Multiplication Test ===");
        rst_n = 0;
        #10 rst_n = 1;
        #10;
        
        // Matrix A = [[1,2,0,0], [3,4,0,0], [0,0,0,0], [0,0,0,0]]
        matrix_a[0][0] = 8'd1;  matrix_a[0][1] = 8'd2;  matrix_a[0][2] = 8'd0;  matrix_a[0][3] = 8'd0;
        matrix_a[1][0] = 8'd3;  matrix_a[1][1] = 8'd4;  matrix_a[1][2] = 8'd0;  matrix_a[1][3] = 8'd0;
        matrix_a[2][0] = 8'd0;  matrix_a[2][1] = 8'd0;  matrix_a[2][2] = 8'd0;  matrix_a[2][3] = 8'd0;
        matrix_a[3][0] = 8'd0;  matrix_a[3][1] = 8'd0;  matrix_a[3][2] = 8'd0;  matrix_a[3][3] = 8'd0;
        
        // Matrix B = [[5,6,0,0], [7,8,0,0], [0,0,0,0], [0,0,0,0]]
        matrix_b[0][0] = 8'd5;  matrix_b[0][1] = 8'd6;  matrix_b[0][2] = 8'd0;  matrix_b[0][3] = 8'd0;
        matrix_b[1][0] = 8'd7;  matrix_b[1][1] = 8'd8;  matrix_b[1][2] = 8'd0;  matrix_b[1][3] = 8'd0;
        matrix_b[2][0] = 8'd0;  matrix_b[2][1] = 8'd0;  matrix_b[2][2] = 8'd0;  matrix_b[2][3] = 8'd0;
        matrix_b[3][0] = 8'd0;  matrix_b[3][1] = 8'd0;  matrix_b[3][2] = 8'd0;  matrix_b[3][3] = 8'd0;
        
        for (cycle = 0; cycle < 7; cycle = cycle + 1) begin
            if (cycle < 4) begin
                in_a[31:24] = matrix_a[0][cycle];
                in_a[23:16] = (cycle >= 1) ? matrix_a[1][cycle-1] : 8'd0;
                in_a[15:8]  = (cycle >= 2) ? matrix_a[2][cycle-2] : 8'd0;
                in_a[7:0]   = (cycle >= 3) ? matrix_a[3][cycle-3] : 8'd0;
            end else begin
                in_a[31:24] = 8'd0;
                in_a[23:16] = (cycle < 5) ? matrix_a[1][cycle-1] : 8'd0;
                in_a[15:8]  = (cycle < 6) ? matrix_a[2][cycle-2] : 8'd0;
                in_a[7:0]   = (cycle < 7) ? matrix_a[3][cycle-3] : 8'd0;
            end

            if (cycle < 4) begin
                in_b[31:24] = matrix_b[cycle][0];
                in_b[23:16] = (cycle >= 1) ? matrix_b[cycle-1][1] : 8'd0;
                in_b[15:8]  = (cycle >= 2) ? matrix_b[cycle-2][2] : 8'd0;
                in_b[7:0]   = (cycle >= 3) ? matrix_b[cycle-3][3] : 8'd0;
            end else begin
                in_b[31:24] = 8'd0;
                in_b[23:16] = (cycle < 5) ? matrix_b[cycle-1][1] : 8'd0;
                in_b[15:8]  = (cycle < 6) ? matrix_b[cycle-2][2] : 8'd0;
                in_b[7:0]   = (cycle < 7) ? matrix_b[cycle-3][3] : 8'd0;
            end
            #10;
        end
        
        in_a = 0;
        in_b = 0;
        repeat(10) #10;
        
        $display("A^T = [[1,3], [2,4]], B = [[5,6], [7,8]]");
        $display("A^T × B = [[1*5+3*7, 1*6+3*8], [2*5+4*7, 2*6+4*8]] = [[26,30], [38,44]]");
        $display("Row 1: %h (expect: 001a 001e 0000 0000 = 26,30,0,0)", out_c_r1);
        $display("Row 2: %h (expect: 0026 002c 0000 0000 = 38,44,0,0)", out_c_r2);

        // Test 4: Diagonal matrix
        $display("\n=== Test 4: Diagonal Matrix Test ===");
        rst_n = 0;
        #10 rst_n = 1;
        #10;
        
        // Matrix A = diag(2,3,4,5)
        matrix_a[0][0] = 8'd2;  matrix_a[0][1] = 8'd0;  matrix_a[0][2] = 8'd0;  matrix_a[0][3] = 8'd0;
        matrix_a[1][0] = 8'd0;  matrix_a[1][1] = 8'd3;  matrix_a[1][2] = 8'd0;  matrix_a[1][3] = 8'd0;
        matrix_a[2][0] = 8'd0;  matrix_a[2][1] = 8'd0;  matrix_a[2][2] = 8'd4;  matrix_a[2][3] = 8'd0;
        matrix_a[3][0] = 8'd0;  matrix_a[3][1] = 8'd0;  matrix_a[3][2] = 8'd0;  matrix_a[3][3] = 8'd5;
        
        // Matrix B = diag(6,7,8,9)
        matrix_b[0][0] = 8'd6;  matrix_b[0][1] = 8'd0;  matrix_b[0][2] = 8'd0;  matrix_b[0][3] = 8'd0;
        matrix_b[1][0] = 8'd0;  matrix_b[1][1] = 8'd7;  matrix_b[1][2] = 8'd0;  matrix_b[1][3] = 8'd0;
        matrix_b[2][0] = 8'd0;  matrix_b[2][1] = 8'd0;  matrix_b[2][2] = 8'd8;  matrix_b[2][3] = 8'd0;
        matrix_b[3][0] = 8'd0;  matrix_b[3][1] = 8'd0;  matrix_b[3][2] = 8'd0;  matrix_b[3][3] = 8'd9;
        
        for (cycle = 0; cycle < 7; cycle = cycle + 1) begin
            if (cycle < 4) begin
                in_a[31:24] = matrix_a[0][cycle];
                in_a[23:16] = (cycle >= 1) ? matrix_a[1][cycle-1] : 8'd0;
                in_a[15:8]  = (cycle >= 2) ? matrix_a[2][cycle-2] : 8'd0;
                in_a[7:0]   = (cycle >= 3) ? matrix_a[3][cycle-3] : 8'd0;
            end else begin
                in_a[31:24] = 8'd0;
                in_a[23:16] = (cycle < 5) ? matrix_a[1][cycle-1] : 8'd0;
                in_a[15:8]  = (cycle < 6) ? matrix_a[2][cycle-2] : 8'd0;
                in_a[7:0]   = (cycle < 7) ? matrix_a[3][cycle-3] : 8'd0;
            end

            if (cycle < 4) begin
                in_b[31:24] = matrix_b[cycle][0];
                in_b[23:16] = (cycle >= 1) ? matrix_b[cycle-1][1] : 8'd0;
                in_b[15:8]  = (cycle >= 2) ? matrix_b[cycle-2][2] : 8'd0;
                in_b[7:0]   = (cycle >= 3) ? matrix_b[cycle-3][3] : 8'd0;
            end else begin
                in_b[31:24] = 8'd0;
                in_b[23:16] = (cycle < 5) ? matrix_b[cycle-1][1] : 8'd0;
                in_b[15:8]  = (cycle < 6) ? matrix_b[cycle-2][2] : 8'd0;
                in_b[7:0]   = (cycle < 7) ? matrix_b[cycle-3][3] : 8'd0;
            end
            #10;
        end
        
        in_a = 0;
        in_b = 0;
        repeat(10) #10;
        
        $display("Diagonal matrices: diag(2,3,4,5) × diag(6,7,8,9) = diag(12,21,32,45)");
        $display("Row 1: %h (expect: 000c 0000 0000 0000 = 12,0,0,0)", out_c_r1);
        $display("Row 2: %h (expect: 0000 0015 0000 0000 = 0,21,0,0)", out_c_r2);
        $display("Row 3: %h (expect: 0000 0000 0020 0000 = 0,0,32,0)", out_c_r3);
        $display("Row 4: %h (expect: 0000 0000 0000 002d = 0,0,0,45)", out_c_r4);

        // Test 5: Zero matrix
        $display("\n=== Test 5: Zero Matrix Test ===");
        rst_n = 0;
        #10 rst_n = 1;
        #10;
        
        for (i = 0; i < 4; i = i + 1) begin
            for (j = 0; j < 4; j = j + 1) begin
                matrix_a[i][j] = 8'd0;
                matrix_b[i][j] = 8'd0;
            end
        end
        
        in_a = 0;
        in_b = 0;
        repeat(20) #10;
        
        $display("Zero matrices: All outputs should be 0");
        $display("Row 1: %h", out_c_r1);
        $display("Row 2: %h", out_c_r2);
        $display("Row 3: %h", out_c_r3);
        $display("Row 4: %h", out_c_r4);

        $display("\n=== All Tests Complete ===");
        $finish;
    end

endmodule
