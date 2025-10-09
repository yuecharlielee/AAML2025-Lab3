`include "systolic_array.v"
`include "buffer.v"
`include "PE.v"

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

reg [15:0] data_out_counter;

reg start;


reg [31:0] A_buffer_in, B_buffer_in;
reg [31:0] A_buffer_out, B_buffer_out;

wire [127:0] c_out[3:0];

reg start_data_out;

buffer weight_buffer_A (
    .clk(clk),
    .rst_n(rst_n),
    .data_in(A_buffer_in),
    .data_out(A_buffer_out)
);

buffer input_buffer_B (
    .clk(clk),
    .rst_n(rst_n),
    .data_in(B_buffer_in),
    .data_out(B_buffer_out)
);


systolic_array SA (
    .rst_n(rst_n),
    .in_valid(in_valid),
    .clk(clk),
    .in_a(A_buffer_out),
    .in_b(B_buffer_out),
    .out_c_r1(c_out[0]),
    .out_c_r2(c_out[1]),
    .out_c_r3(c_out[2]),
    .out_c_r4(c_out[3])
);

reg [7:0] M_reg, N_reg, K_reg;

always @(posedge clk or rst_n) begin
    if(!rst_n) begin
        counter <= 0;
        busy <= 0;
        C_wr_en <= 1'b0;

        A_data_in <= 127'b0;
        A_wr_en <= 1'b0;
        A_index <= 1'b0;


        B_data_in <= 127'b0;
        B_wr_en <= 1'b0;
        B_index <= 1'b0;

        start <= 1'b0;

        A_buffer_in <= 32'b0;
        B_buffer_in <= 32'b0;

        data_out_counter <= 1'b0;
        start_data_out <= 1'b0;
        M_reg <= 8'b0;
        N_reg <= 8'b0;
        K_reg <= 8'b0;

    end
    else begin
        if(in_valid) begin
            M_reg <= M;
            N_reg <= N;
            K_reg <= K;
            start <= 1'b1;
            busy <= 1'b1;
            A_index <= 0;
            B_index <= 0;
        end

        if(start) begin
            if(counter < K_reg) begin
                A_index <= A_index + 1;
                B_index <= B_index + 1;
                A_buffer_in <= A_data_out;
                B_buffer_in <= B_data_out;
            end
            else begin
                A_buffer_in <= 32'b0;
                B_buffer_in <= 32'b0;
            end
            counter <= counter + 1;
        end
        else begin
            A_buffer_in <= 32'b0;
            B_buffer_in <= 32'b0;
        end


        if(counter >= K_reg + 6) begin
            start <= 1'b0;
            start_data_out <= 1'b1;
            C_wr_en <= 1'b1;
        end
        else begin
            C_wr_en <= 1'b0;
        end

        if(start_data_out) begin
            if(data_out_counter == 4) begin
                busy <= 0;
                data_out_counter <= 0;
                start_data_out <= 0;
                counter <= 0;
            end
            else begin
                data_out_counter <= data_out_counter + 1;
            end
        end
        else begin
            data_out_counter <= 0;
        end
    end
end

always @(*) begin
    C_index = data_out_counter;
    C_data_in = c_out[data_out_counter];
end


endmodule