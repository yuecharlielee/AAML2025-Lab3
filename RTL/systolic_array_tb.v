`timescale 1ns/1ps

module systolic_array_tb();

reg rst_n;
reg clk;
reg [31:0] in_a;
reg [31:0] in_b;
wire [127:0] out_c;

// Extract individual result elements for easier verification
wire [15:0] c00 = out_c[127:112];
wire [15:0] c01 = out_c[111:96];
wire [15:0] c02 = out_c[95:80];
wire [15:0] c03 = out_c[79:64];
wire [15:0] c10 = out_c[63:48];
wire [15:0] c11 = out_c[47:32];
wire [15:0] c12 = out_c[31:16];
wire [15:0] c13 = out_c[15:0];

// Instantiate the systolic array
systolic_array dut (
    .rst_n(rst_n),
    .clk(clk),
    .in_a(in_a),
    .in_b(in_b),
    .out_c(out_c)
);

// Clock generation
initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

wire [15:0] debug_c00 = dut.c_wire[0][0];
wire [15:0] debug_c01 = dut.c_wire[0][1];
wire [15:0] debug_c10 = dut.c_wire[1][0];
wire [15:0] debug_c11 = dut.c_wire[1][1];

// Also add debug for PE results directly
wire [15:0] pe00_result = dut.ROW[0].COL[0].pe.result_out;
wire [15:0] pe01_result = dut.ROW[0].COL[1].pe.result_out;
wire [15:0] pe10_result = dut.ROW[1].COL[0].pe.result_out;
wire [15:0] pe11_result = dut.ROW[1].COL[1].pe.result_out;

initial begin
    $dumpfile("systolic_array_tb.vcd");
    $dumpvars(0, systolic_array_tb);
    $dumpvars(0, debug_c00, debug_c01, debug_c10, debug_c11);
    $dumpvars(0, pe00_result, pe01_result, pe10_result, pe11_result);
    
    // Initialize
    rst_n = 0;
    in_a = 32'h00000000;
    in_b = 32'h00000000;
    
    // Reset phase
    #20;
    rst_n = 1;
    #10;
    
    $display("=== Simple Single PE Test First ===");
    // Test just PE[0][0] with simple values
    in_a = {8'd2, 8'd0, 8'd0, 8'd0};  // Just 2 for PE[0][0]
    in_b = {8'd3, 8'd0, 8'd0, 8'd0};  // Just 3 for PE[0][0]
    #10;
    
    $display("After 1 cycle:");
    $display("  PE[0][0] result_out = %d", pe00_result);
    $display("  c_wire[0][0] = %d", debug_c00);
    $display("  out_c[127:112] = %d", c00);
    $display("  Full out_c = %h", out_c);
    
    // RESET INPUTS to prevent continuous accumulation
    in_a = 32'h00000000;
    in_b = 32'h00000000;
    #10;
    
    $display("After 2 cycles (inputs reset):");
    $display("  PE[0][0] result_out = %d (expected 6)", pe00_result);
    $display("  c_wire[0][0] = %d", debug_c00);
    $display("  out_c[127:112] = %d", c00);
    
    #10;
    $display("After 3 cycles:");
    $display("  PE[0][0] result_out = %d", pe00_result);
    $display("  c_wire[0][0] = %d", debug_c00);
    $display("  out_c[127:112] = %d", c00);
    
    // Reset and try matrix test
    $display("\n=== Matrix Multiplication Test ===");
    rst_n = 0;
    #20;
    rst_n = 1;
    #10;
    
    // Your existing matrix test...
    // (Keep your existing test code here)
    
    $finish;
end

// Monitor for debugging
initial begin
    $monitor("Time=%0t rst_n=%b clk=%b a_in=%h b_in=%h", 
             $time, rst_n, clk, in_a, in_b);
end

endmodule