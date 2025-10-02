module PE(
    rst_n,
    clk,
    up_in,
    left_in,
    right_out,
    down_out,
    result_out
);

input clk;
input rst_n;
input [7:0] up_in, left_in;
output reg [7:0] right_out, down_out;
output reg [15:0] result_out;


always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        result_out <= 0;
        right_out <= 0;
        down_out <= 0;
    end
    else begin
        result_out <= result_out + up_in * left_in;
        right_out <= left_in;
        down_out <= up_in;
    end
end



endmodule