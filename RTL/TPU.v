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

localparam IDLE = 3'd0;
localparam LOAD = 3'd1;
localparam CALC = 3'd2;
localparam WRITEBACK = 3'd3;

reg [2:0] state, next_state;
reg [7:0] load_cnt;
reg [7:0] calc_cnt;
reg [7:0] wb_cnt;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        state <= IDLE;
    end
    else begin
        state <= next_state;
    end
end

always @(*) begin
    case(state)
        IDLE: begin
            if(in_valid)
                next_state = LOAD;
            else
                next_state = IDLE;
        end
        LOAD: begin
            if(load_cnt >= K_reg - 1)
                next_state = CALC;
            else
                next_state = LOAD;
        end
        CALC: begin
            if(calc_cnt >= 6)
                next_state = WRITEBACK;
            else
                next_state = CALC;
        end
        WRITEBACK: begin
            if(wb_cnt >= 3)
                next_state = IDLE;
            else
                next_state = WRITEBACK;
        end
        default: next_state = IDLE;
    endcase
end

// Counter and control logic
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        busy <= 0;
        A_wr_en <= 0;
        A_index <= 0;
        A_data_in <= 0;
        B_wr_en <= 0;
        B_index <= 0;
        B_data_in <= 0;
        C_wr_en <= 0;
        C_index <= 0;
        A_buffer_in <= 0;
        B_buffer_in <= 0;
        M_reg <= 0;
        N_reg <= 0;
        K_reg <= 0;
        load_cnt <= 0;
        calc_cnt <= 0;
        wb_cnt <= 0;
    end
    else begin
        case(state)
            IDLE: begin

                if(in_valid) begin
                    M_reg <= M;
                    N_reg <= N;
                    K_reg <= K;
                    busy <= 1;
                    A_index <= 0;
                    B_index <= 0;
                end
                else begin
                    busy <= 0;
                    C_wr_en <= 0;
                    load_cnt <= 0;
                    calc_cnt <= 0;
                    wb_cnt <= 0;
                    A_buffer_in <= 0;
                    B_buffer_in <= 0;
                end
            end
            LOAD: begin
                A_index <= A_index + 1;
                B_index <= B_index + 1;
                A_buffer_in <= A_data_out;
                B_buffer_in <= B_data_out;
                load_cnt <= load_cnt + 1;
            end
            CALC: begin
                A_buffer_in <= 0;
                B_buffer_in <= 0;
                calc_cnt <= calc_cnt + 1;
            end
            WRITEBACK: begin
                C_wr_en <= 1;
                C_index <= wb_cnt;
                C_data_in <= c_out[wb_cnt];
                wb_cnt <= wb_cnt + 1;
                if(wb_cnt >= 3) begin
                    load_cnt <= 0;
                    calc_cnt <= 0;
                    wb_cnt <= 0;
                end
            end
        endcase
    end
end


endmodule