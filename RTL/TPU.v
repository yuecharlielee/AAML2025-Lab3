
module TPU(
    clk,
    rst_n,

    in_valid,
    K,
    M,
    N,
    busy,

    A_wr_en,
    A_index,
    A_data_in,
    A_data_out,

    B_wr_en,
    B_index,
    B_data_in,
    B_data_out,

    C_wr_en,
    C_index,
    C_data_in,
    C_data_out
);


input clk;
input rst_n;
input            in_valid;
input [7:0]      K;
input [7:0]      M;
input [7:0]      N;
output  reg      busy;

output reg          A_wr_en;
output reg [15:0]    A_index;
output reg [31:0]    A_data_in;
input  [31:0]    A_data_out;

output reg          B_wr_en;
output reg [15:0]    B_index;
output reg [31:0]    B_data_in;
input  [31:0]    B_data_out;

output reg            C_wr_en;
output reg [15:0]    C_index;
output reg [127:0]   C_data_in;
input  [127:0]   C_data_out;

reg [127:0] counter;

always @(posedge clk or rst_n) begin
    if(!rst_n) begin
        counter <= 0;
        busy <= 0;
        C_data_in <= 127'b0;
        C_wr_en <= 1'b0;
        C_index <= 1'b0;

        A_data_in <= 127'b0;
        A_wr_en <= 1'b0;
        A_index <= 1'b0;


        B_data_in <= 127'b0;
        B_wr_en <= 1'b0;
        B_index <= 1'b0;

    end
    else begin
        counter <= counter + 1;
        
        C_data_in <= 127'b1;
        C_wr_en <= 1'b1;
        C_index <= 1'b1;

        A_data_in <= 127'b0;
        A_wr_en <= 1'b0;
        A_index <= A_index + 1;


        B_data_in <= 127'b0;
        B_wr_en <= 1'b0;
        B_index <= B_index + 1;

        if(counter <= 100) begin
            busy <= 1;
        end
        else begin
            busy <= 0;
        end
    end
end




endmodule