`ifndef CHECK_ORDER_V
`define CHECK_ORDER_V
`include "./source/header.vh"
module check_order (
    co_ds1_i_addr_rd, co_ds2_i_addr_rd,
    co_i_alu_value_1, co_i_alu_value_2, co_i_wb1_data, co_i_wb2_data,
    co_o_alu_value_1, co_o_wb1_data
);  
    input [`AWIDTH - 1 : 0] co_ds1_i_addr_rd, co_ds2_i_addr_rd;
    input [`DWIDTH - 1 : 0] co_i_alu_value_1, co_i_alu_value_2;
    input [`DWIDTH - 1 : 0] co_i_wb1_data, co_i_wb2_data;
    output [`DWIDTH - 1 : 0] co_o_wb1_data;
    output [`DWIDTH - 1 : 0] co_o_alu_value_1;

    assign co_o_wb1_data = (co_ds1_i_addr_rd == co_ds2_i_addr_rd) ? co_i_wb1_data : co_i_wb2_data;
    assign co_o_alu_value_1 = (co_ds1_i_addr_rd == co_ds2_i_addr_rd) ? co_i_alu_value_1 : co_i_alu_value_2;
endmodule
`endif 