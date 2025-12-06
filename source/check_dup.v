`ifndef CHECK_DUP_V
`define CHECK_DUP_V
`include "./source/header.vh"

module check_dup (
    cd_i_addr_rd_1, cd_i_addr_rs_2, cd_i_addr_rt_2, cd_i_opcode_2, cd_o_we
);
    input [`AWIDTH - 1 : 0] cd_i_addr_rd_1;
    input [`OPCODE_WIDTH - 1 : 0] cd_i_opcode_2;
    input [`AWIDTH - 1 : 0] cd_i_addr_rs_2, cd_i_addr_rt_2;
    output cd_o_we;

    assign cd_o_we = ((cd_i_addr_rd_1 == cd_i_addr_rs_2) && (cd_i_addr_rd_1 != cd_i_addr_rt_2)) ? 1'b1 : 
                            ((cd_i_addr_rd_1 == cd_i_addr_rt_2) && (cd_i_addr_rd_1 != cd_i_addr_rs_2)) ? 1'b1 :
                            ((cd_i_addr_rd_1 != cd_i_addr_rt_2) && (cd_i_addr_rd_1 != cd_i_addr_rs_2)) ? 1'b0 : 
                            (cd_i_opcode_2 == `JR) ? 1'b1 : 1'b0;
endmodule
`endif 