module systolic_array(
    rst_n,
    clk,
    in_a,
    in_b,
    out_c_r1,
    out_c_r2,
    out_c_r3,
    out_c_r4
);

input rst_n;
input clk;
input [31:0] in_a;
input [31:0] in_b;
output [63:0] out_c_r1;
output [63:0] out_c_r2;
output [63:0] out_c_r3;
output [63:0] out_c_r4;

wire [7:0] a_wire[4:0][3:0]; 
wire [7:0] b_wire[3:0][4:0];  
wire [15:0] c_wire[3:0][3:0]; 


assign a_wire[0][0] = in_a[31:24];  
assign a_wire[0][1] = in_a[23:16];  
assign a_wire[0][2] = in_a[15:8];  
assign a_wire[0][3] = in_a[7:0];   


assign b_wire[0][0] = in_b[31:24];  
assign b_wire[1][0] = in_b[23:16];  
assign b_wire[2][0] = in_b[15:8];   
assign b_wire[3][0] = in_b[7:0];    

genvar i,j;



generate
    for(i=0;i<4;i=i+1) begin:ROW
        for(j=0;j<4;j=j+1) begin:COL
            PE pe(
                .rst_n(rst_n),
                .clk(clk),
                .up_in(a_wire[i][j]),
                .left_in(b_wire[i][j]),
                .right_out(b_wire[i][j+1]),
                .down_out(a_wire[i+1][j]),
                .result_out(c_wire[i][j])
            );
        end
    end
endgenerate

assign out_c_r1 = {c_wire[0][0], c_wire[0][1], c_wire[0][2], c_wire[0][3]};
assign out_c_r2 = {c_wire[1][0], c_wire[1][1], c_wire[1][2], c_wire[1][3]};
assign out_c_r3 = {c_wire[2][0], c_wire[2][1], c_wire[2][2], c_wire[2][3]};
assign out_c_r4 = {c_wire[3][0], c_wire[3][1], c_wire[3][2], c_wire[3][3]};

endmodule