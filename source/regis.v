`ifndef REGIS_V
`define REGIS_V
`include "./source/header.vh"
module regis (
    r_clk, r_rst, r_wr_en_1, r_wr_en_2, r_i_addr_rd_1, r_i_addr_rd_2, r_i_data_rd_1, r_i_data_rd_2, 
    r_i_addr_rs_1, r_i_addr_rt_1, r_i_addr_rs_2, r_i_addr_rt_2,
    r_i_addr_q1_rs, r_i_addr_q1_rt, r_i_addr_q2_rs, r_i_addr_q2_rt,
    r_o_data_rs_1, r_o_data_rs_2, r_o_data_rt_1, r_o_data_rt_2,
    r_o_data_q1_rs, r_o_data_q1_rt, r_o_data_q2_rs, r_o_data_q2_rt
);
    input r_clk, r_rst;
    input r_wr_en_1, r_wr_en_2;
    input [`AWIDTH - 1 : 0] r_i_addr_rd_1, r_i_addr_rd_2;
    input [`DWIDTH - 1 : 0] r_i_data_rd_1, r_i_data_rd_2;
    input [`AWIDTH - 1 : 0] r_i_addr_rs_1, r_i_addr_rs_2;
    input [`AWIDTH - 1 : 0] r_i_addr_rt_1, r_i_addr_rt_2;
    input [`AWIDTH - 1 : 0] r_i_addr_q1_rs, r_i_addr_q1_rt;
    input [`AWIDTH - 1 : 0] r_i_addr_q2_rs, r_i_addr_q2_rt;
    output [`DWIDTH - 1 : 0] r_o_data_rs_1, r_o_data_rs_2;
    output [`DWIDTH - 1 : 0] r_o_data_rt_1, r_o_data_rt_2;
    output [`DWIDTH - 1 : 0] r_o_data_q1_rs, r_o_data_q1_rt;
    output [`DWIDTH - 1 : 0] r_o_data_q2_rs, r_o_data_q2_rt;

    integer i;
    reg [`DWIDTH - 1 : 0] data_reg [(2 ** `AWIDTH) - 1 : 0];

    always @(negedge r_clk, negedge r_rst) begin
        if (!r_rst) begin
            for (i = 0; i < 1 << `AWIDTH; i = i + 1) begin
                data_reg[i] <= i;
            end
        end
        else begin
            if (r_wr_en_1) begin
                data_reg[r_i_addr_rd_1] <= r_i_data_rd_1;
            end
            if (r_wr_en_2) begin
                data_reg[r_i_addr_rd_2] <= r_i_data_rd_2;
            end
        end
    end

    assign r_o_data_rs_1 = data_reg[r_i_addr_rs_1];
    assign r_o_data_rt_1 = data_reg[r_i_addr_rt_1];
    assign r_o_data_rs_2 = data_reg[r_i_addr_rs_2];
    assign r_o_data_rt_2 = data_reg[r_i_addr_rt_2];
    assign r_o_data_q1_rs = data_reg[r_i_addr_q1_rs];
    assign r_o_data_q1_rt = data_reg[r_i_addr_q1_rt];
    assign r_o_data_q2_rs = data_reg[r_i_addr_q2_rs];
    assign r_o_data_q2_rt = data_reg[r_i_addr_q2_rt];
endmodule
`endif 
