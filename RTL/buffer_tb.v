`timescale 1ns / 1ps

module buffer_tb;

    // Testbench signals
    reg clk;
    reg rst_n;
    reg [31:0] in_data;
    wire [31:0] out_data;
    
    // Test data tracking
    reg [31:0] expected_out;
    integer test_num;
    integer errors;
    
    // Instantiate the buffer module
    buffer uut (
        .clk(clk),
        .rst_n(rst_n),
        .in_data(in_data),
        .out_data(out_data)
    );
    
    // Clock generation (10ns period = 100MHz)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // Test stimulus
    initial begin
        // Initialize
        test_num = 0;
        errors = 0;
        rst_n = 0;
        in_data = 32'h00000000;
        
        $display("=== Buffer Module Testbench ===");
        $display("Time\t\tTest\t\tInput\t\tOutput\t\tExpected\tStatus");
        $display("================================================================================");
        
        // Reset test
        #10;
        rst_n = 1;
        #10;
        
        // Test 1: First input after reset
        test_num = 1;
        in_data = 32'hABCD1234;
        expected_out = 32'hAB000000; // Only [31:24] should pass through immediately
        #10;
        check_output(test_num, "First input");
        
        // Test 2: Second input - delayed propagation
        test_num = 2;
        in_data = 32'h12345678;
        expected_out = 32'h12CD0000; // [31:24] immediate, [23:16] from prev cycle
        #10;
        check_output(test_num, "Second input");
        
        // Test 3: Third input
        test_num = 3;
        in_data = 32'hFEDCBA98;
        expected_out = 32'hFE341200; // Continuing propagation
        #10;
        check_output(test_num, "Third input");
        
        // Test 4: Fourth input - full pipeline
        test_num = 4;
        in_data = 32'h11223344;
        expected_out = 32'h11DC5634; // [31:24]=11(curr), [23:16]=DC(1-cyc), [15:8]=56(2-cyc), [7:0]=34(3-cyc)
        #10;
        check_output(test_num, "Fourth input");
        
        // Test 5: Hold input constant
        test_num = 5;
        in_data = 32'hAAAAAAAA;
        expected_out = 32'hAA22BA78;
        #10;
        check_output(test_num, "Hold constant 1");
        
        // Test 6: Continue holding
        test_num = 6;
        in_data = 32'hAAAAAAAA;
        expected_out = 32'hAAAA3398;
        #10;
        check_output(test_num, "Hold constant 2");
        
        // Test 7: Continue holding - fully propagated
        test_num = 7;
        in_data = 32'hAAAAAAAA;
        expected_out = 32'hAAAAAA44;
        #10;
        check_output(test_num, "Hold constant 3");
        
        // Test 8: All zeros
        test_num = 8;
        in_data = 32'h00000000;
        expected_out = 32'h00AAAAAA;
        #10;
        check_output(test_num, "All zeros 1");
        
        // Test 9: Continue zeros
        test_num = 9;
        in_data = 32'h00000000;
        expected_out = 32'h0000AAAA;
        #10;
        check_output(test_num, "All zeros 2");
        
        // Test 10: Zeros fully propagated
        test_num = 10;
        in_data = 32'h00000000;
        expected_out = 32'h000000AA;
        #10;
        check_output(test_num, "All zeros 3");
        
        // Test 11: Sequential pattern
        test_num = 11;
        in_data = 32'h01020304;
        expected_out = 32'h01000000;
        #10;
        check_output(test_num, "Sequential 1");
        
        test_num = 12;
        in_data = 32'h05060708;
        expected_out = 32'h05020000;
        #10;
        check_output(test_num, "Sequential 2");
        
        test_num = 13;
        in_data = 32'h090A0B0C;
        expected_out = 32'h09060300;
        #10;
        check_output(test_num, "Sequential 3");
        
        test_num = 14;
        in_data = 32'h0D0E0F10;
        expected_out = 32'h0D0A0704;
        #10;
        check_output(test_num, "Sequential 4");
        
        // Test 15: Reset during operation
        $display("\n--- Reset Test ---");
        test_num = 15;
        rst_n = 0;
        #10;
        if (out_data === 32'h00000000) begin
            $display("%0t\t\tTest %0d\t\t%h\t%h\t%h\tPASS", $time, test_num, in_data, out_data, 32'h00000000);
        end else begin
            $display("%0t\t\tTest %0d\t\t%h\t%h\t%h\tFAIL", $time, test_num, in_data, out_data, 32'h00000000);
            errors = errors + 1;
        end
        
        // Test 16: Recovery after reset
        test_num = 16;
        rst_n = 1;
        in_data = 32'hFFFFFFFF;
        #10;
        expected_out = 32'hFF000000;
        check_output(test_num, "After reset");
        
        // Test 17: Maximum values
        test_num = 17;
        in_data = 32'hFFFFFFFF;
        expected_out = 32'hFFFF0000;
        #10;
        check_output(test_num, "Max values 2");
        
        test_num = 18;
        in_data = 32'hFFFFFFFF;
        expected_out = 32'hFFFFFF00;
        #10;
        check_output(test_num, "Max values 3");
        
        test_num = 19;
        in_data = 32'hFFFFFFFF;
        expected_out = 32'hFFFFFFFF;
        #10;
        check_output(test_num, "Max values 4");
        
        // Test 20: Alternating pattern
        test_num = 20;
        in_data = 32'hAAAAAAAA;
        expected_out = 32'hAAFFFFFF;
        #10;
        check_output(test_num, "Alternating 1");
        
        test_num = 21;
        in_data = 32'h55555555;
        expected_out = 32'h55AAFFFF;
        #10;
        check_output(test_num, "Alternating 2");
        
        test_num = 22;
        in_data = 32'hAAAAAAAA;
        expected_out = 32'hAA55AAFF;
        #10;
        check_output(test_num, "Alternating 3");
        
        test_num = 23;
        in_data = 32'h55555555;
        expected_out = 32'h55AA55AA;
        #10;
        check_output(test_num, "Alternating 4");
        
        // Summary
        $display("\n================================================================================");
        $display("=== Test Summary ===");
        $display("Total Tests: %0d", test_num);
        $display("Errors: %0d", errors);
        if (errors == 0) begin
            $display("*** ALL TESTS PASSED ***");
        end else begin
            $display("*** %0d TESTS FAILED ***", errors);
        end
        $display("================================================================================");
        
        #20;
        $finish;
    end
    
    // Task to check output
    task check_output;
        input integer test_number;
        input [200*8-1:0] test_name;
        begin
            if (out_data === expected_out) begin
                $display("%0t\t\tTest %0d\t\t%h\t%h\t%h\tPASS - %s", 
                         $time, test_number, in_data, out_data, expected_out, test_name);
            end else begin
                $display("%0t\t\tTest %0d\t\t%h\t%h\t%h\tFAIL - %s", 
                         $time, test_number, in_data, out_data, expected_out, test_name);
                errors = errors + 1;
            end
        end
    endtask
    
    // Monitor for debugging (optional - comment out if too verbose)
    // initial begin
    //     $monitor("Time=%0t rst_n=%b in=%h out=%h", $time, rst_n, in_data, out_data);
    // end
    
    // Waveform dump
    initial begin
        $dumpfile("buffer_tb.vcd");
        $dumpvars(0, buffer_tb);
    end

endmodule
