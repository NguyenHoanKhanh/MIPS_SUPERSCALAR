`ifndef CHECK_DUP_V
`define CHECK_DUP_V
`include "./source/header.vh"

module check_dup (
    cd_i_addr_rd_1, cd_i_addr_rs_2, cd_i_addr_rt_2, cd_i_opcode_2, cd_o_we, cd_o_force_pipe1
);
    input [`AWIDTH - 1 : 0] cd_i_addr_rd_1;
    input [`OPCODE_WIDTH - 1 : 0] cd_i_opcode_2;
    input [`AWIDTH - 1 : 0] cd_i_addr_rs_2, cd_i_addr_rt_2;
    output cd_o_we;
    output cd_o_force_pipe1;

    wire hazard_rs = (cd_i_addr_rd_1 == cd_i_addr_rs_2);
    wire hazard_rt = (cd_i_addr_rd_1 == cd_i_addr_rt_2);
    wire rd_non_zero = |cd_i_addr_rd_1;

    assign cd_o_we = (hazard_rs && !hazard_rt) ? 1'b1 : 
                     (hazard_rt && !hazard_rs) ? 1'b1 :
                     (!hazard_rs && !hazard_rt) ? 1'b0 :
                     (cd_i_opcode_2 == `JR) ? 1'b1 : 1'b0;

    // Signal that this instruction must eventually be routed through the forwarding-capable pipe.
    assign cd_o_force_pipe1 = rd_non_zero && (hazard_rs || hazard_rt);
endmodule
`endif 
