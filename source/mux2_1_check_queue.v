`ifndef MUX2_1_CHECK_QUEUE_V
`define MUX2_1_CHECK_QUEUE_V
`include "./source/header.vh"

module mux2_1_check_queue (
    mx_i_queue_instr, mx_i_mem_instr, mx_i_check_queue, mx_o_instr
);
    input mx_i_check_queue;
    input [`IWIDTH - 1 : 0] mx_i_queue_instr, mx_i_mem_instr;
    output [`IWIDTH - 1 : 0] mx_o_instr;

    assign mx_o_instr = (mx_i_check_queue) ? mx_i_queue_instr : mx_i_mem_instr;
endmodule
`endif 