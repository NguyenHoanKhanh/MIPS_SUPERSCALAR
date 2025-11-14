`ifndef MUX_DES_V
`define MUX_DES_V
`include "./source/header.vh"

module mux_des (
    md_reg_dst, md_i_addr_rd, md_i_addr_rt, md_o_addr_rd
);
    input md_reg_dst;
    input [`AWIDTH - 1 : 0] md_i_addr_rd, md_i_addr_rt;
    output [`AWIDTH - 1 : 0] md_o_addr_rd;

    assign md_o_addr_rd = (md_reg_dst == 1'b1) ? md_i_addr_rd : (md_reg_dst == 1'b0) ? md_i_addr_rt : 1'b0;
endmodule
`endif 