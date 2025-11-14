`ifndef REGISTER_V
`define REGISTER_V
`include "./source/header.vh"
module register (
    r_clk, r_rst, r_wr_en, r_i_addr_rd, r_i_data_rd, 
    r_i_addr_rs, r_i_addr_rt, r_o_data_rs, r_o_data_rt 
);
    input r_clk, r_rst;
    input r_wr_en;
    input [`AWIDTH - 1 : 0] r_i_addr_rd;
    input [`DWIDTH - 1 : 0] r_i_data_rd;
    input [`AWIDTH - 1 : 0] r_i_addr_rs, r_i_addr_rt;
    output [`DWIDTH - 1 : 0] r_o_data_rs, r_o_data_rt;

    integer i;
    reg [`DWIDTH - 1 : 0] data_reg [(2 ** `AWIDTH) - 1 : 0];

    always @(negedge r_clk, negedge r_rst) begin
        if (!r_rst) begin
            for (i = 0; i < 1 << `AWIDTH; i = i + 1) begin
                data_reg[i] <= i;
            end
        end
        else begin
            if (r_wr_en) begin
                data_reg[r_i_addr_rd] <= r_i_data_rd;
            end
        end
    end

    assign r_o_data_rs = data_reg[r_i_addr_rs];
    assign r_o_data_rt = data_reg[r_i_addr_rt];
endmodule
`endif 