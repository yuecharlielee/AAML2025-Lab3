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
output reg       busy;

output reg          A_wr_en;
output reg [15:0]   A_index;
output reg [31:0]   A_data_in;
input  [31:0]       A_data_out;

output reg          B_wr_en;
output reg [15:0]   B_index;
output reg [31:0]   B_data_in;
input  [31:0]       B_data_out;

output reg          C_wr_en;
output reg [15:0]   C_index;
output reg [127:0]  C_data_in;
input  [127:0]      C_data_out;

reg [31:0] A_buffer_in, B_buffer_in;
reg [31:0] A_buffer_out, B_buffer_out;

wire [127:0] c_out[3:0];

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

reg systolic_valid;

systolic_array SA (
    .rst_n(rst_n),
    .in_valid(systolic_valid),
    .clk(clk),
    .in_a(A_buffer_out),
    .in_b(B_buffer_out),
    .out_c_r1(c_out[0]),
    .out_c_r2(c_out[1]),
    .out_c_r3(c_out[2]),
    .out_c_r4(c_out[3])
);

reg [7:0] M_reg, N_reg, K_reg;
reg [7:0] tile_m, tile_n, tile_k;
reg [7:0] max_tile_m, max_tile_n, max_tile_k;

reg [31:0] c_reg [0:3][0:3];

wire [127:0] c_row0 = {c_reg[0][0], c_reg[0][1], c_reg[0][2], c_reg[0][3]};
wire [127:0] c_row1 = {c_reg[1][0], c_reg[1][1], c_reg[1][2], c_reg[1][3]};
wire [127:0] c_row2 = {c_reg[2][0], c_reg[2][1], c_reg[2][2], c_reg[2][3]};
wire [127:0] c_row3 = {c_reg[3][0], c_reg[3][1], c_reg[3][2], c_reg[3][3]};

integer i, j;

localparam IDLE = 2'd0;
localparam LOAD = 2'd1;
localparam CALC = 2'd2;
localparam WRITEBACK = 2'd3;

reg [1:0] state, next_state;
reg [7:0] load_cnt, calc_cnt, wb_cnt;

wire [15:0] A_addr = tile_k * 4 * max_tile_m + tile_m * 4 + load_cnt;
wire [15:0] B_addr = tile_k * 4 * max_tile_n + tile_n * 4 + load_cnt;  
wire [15:0] C_addr = tile_m * 4 * max_tile_n + tile_n * 4 + wb_cnt;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        M_reg <= 0;
        N_reg <= 0;
        K_reg <= 0;
        max_tile_m <= 0;
        max_tile_n <= 0; 
        max_tile_k <= 0;
        tile_m <= 0;
        tile_n <= 0;
        tile_k <= 0;
    end
    else if(in_valid) begin
        M_reg <= M;
        N_reg <= N;
        K_reg <= K;
        max_tile_m <= (M + 3) >> 2;  
        max_tile_n <= (N + 3) >> 2; 
        max_tile_k <= (K + 3) >> 2; 
        tile_m <= 0;
        tile_n <= 0;
        tile_k <= 0;
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
            if(load_cnt > 3) 
                next_state = CALC;
            else
                next_state = LOAD;
        end
        CALC: begin
            if(calc_cnt >= 8)  
                next_state = WRITEBACK;
            else
                next_state = CALC;
        end
        WRITEBACK: begin
            if(wb_cnt > 3) begin
                if(tile_k < max_tile_k - 1 || tile_n < max_tile_n - 1 || tile_m < max_tile_m - 1)
                    next_state = LOAD;
                else
                    next_state = IDLE;
            end
            else
                next_state = WRITEBACK;
        end
        default: next_state = IDLE;
    endcase
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        busy <= 0;
        A_wr_en <= 0;
        B_wr_en <= 0;
        C_wr_en <= 0;
        A_index <= 0;
        B_index <= 0;
        C_index <= 0;
        load_cnt <= 0;
        calc_cnt <= 0;
        wb_cnt <= 0;
        state <= IDLE;
        systolic_valid <= 0;

        for(i = 0; i < 4; i = i + 1) begin
            for(j = 0; j < 4; j = j + 1) begin
                c_reg[i][j] <= 0;
            end
        end
    end
    else begin
        state <= next_state;
        systolic_valid <= (state == IDLE && in_valid) || (state == WRITEBACK && wb_cnt > 3 && next_state == LOAD);
        
        case(state)
            IDLE: begin
                if(in_valid) begin
                    busy <= 1;
                    load_cnt <= 0;
                    calc_cnt <= 0;
                    wb_cnt <= 0;
                    for(i = 0; i < 4; i = i + 1) begin
                        for(j = 0; j < 4; j = j + 1) begin
                            c_reg[i][j] <= 0;
                        end
                    end
                end
                else begin
                    busy <= 0;
                end
                A_buffer_in <= 0;
                B_buffer_in <= 0;
                C_wr_en <= 0;
            end
            
            LOAD: begin
                A_index <= A_addr;
                B_index <= B_addr;
                
                if(tile_k * 4 + load_cnt > K_reg) begin
                    A_buffer_in <= 0; 
                    B_buffer_in <= 0;
                end
                else if(load_cnt == 0) begin
                    A_buffer_in <= 0; 
                    B_buffer_in <= 0;
                end
                else begin
                    A_buffer_in <= A_data_out;
                    B_buffer_in <= B_data_out;
                end
                
                load_cnt <= load_cnt + 1;
                
                if(load_cnt > 3) begin
                    calc_cnt <= 0;
                end
            end
            
            CALC: begin
                A_buffer_in <= 0;
                B_buffer_in <= 0;
                calc_cnt <= calc_cnt + 1;
                
                if(calc_cnt == 8) begin
                    for(i = 0; i < 4; i = i + 1) begin
                        c_reg[i][0] <= c_out[i][127:96] + c_reg[i][0];
                        c_reg[i][1] <= c_out[i][95:64] + c_reg[i][1];
                        c_reg[i][2] <= c_out[i][63:32] + c_reg[i][2];
                        c_reg[i][3] <= c_out[i][31:0] + c_reg[i][3];
                    end
                    wb_cnt <= 0;
                end
            end
            
            WRITEBACK: begin
                if(tile_k >= max_tile_k - 1) begin
                    C_wr_en <= 1;
                    C_index <= C_addr;
                    C_data_in <= {c_reg[wb_cnt][0], c_reg[wb_cnt][1], c_reg[wb_cnt][2], c_reg[wb_cnt][3]};
                end
                else begin
                    C_wr_en <= 0;
                end
                
                wb_cnt <= wb_cnt + 1;
                if(wb_cnt > 3) begin
                    load_cnt <= 0;
                    
                    if(tile_k < max_tile_k - 1) begin
                        tile_k <= tile_k + 1;
                    end
                    else begin
                        tile_k <= 0;
                        
                        for(i = 0; i < 4; i = i + 1) begin
                            for(j = 0; j < 4; j = j + 1) begin
                                c_reg[i][j] <= 0;
                            end
                        end
                        
                        if(tile_n < max_tile_n - 1) begin
                            tile_n <= tile_n + 1;
                        end
                        else begin
                            tile_n <= 0;
                            if(tile_m < max_tile_m - 1) begin
                                tile_m <= tile_m + 1;
                            end
                            else begin
                                tile_m <= 0;
                                busy <= 0;
                            end
                        end
                    end
                end
            end
        endcase
    end
end

endmodule