module buffer (
    input clk,
    input rst_n,
    input [31:0] in_data,
    output reg [31:0] out_data
);

reg [7:0] r1_temp1;
reg [7:0] r2_temp1, r2_temp2;
reg [7:0] r3_temp1, r3_temp2, r3_temp3;


always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        out_data <= 32'b0;
        r1_temp1 <= 8'b0;
        r2_temp1 <= 8'b0;
        r2_temp2 <= 8'b0;
        r3_temp1 <= 8'b0;
        r3_temp2 <= 8'b0;
        r3_temp3 <= 8'b0;
        
    end else begin
        r1_temp1 <= in_data[23:16];

        r2_temp1 <= r2_temp2;
        r2_temp2 <= in_data[15:8];

        r3_temp1 <= r3_temp2;
        r3_temp2 <= r3_temp3;
        r3_temp3 <= in_data[7:0];

        out_data <= {in_data[31:24], r1_temp1, r2_temp1, r3_temp1};

    end
end 

endmodule