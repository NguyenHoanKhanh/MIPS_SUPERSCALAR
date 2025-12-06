`ifndef MUX3_1_V
`define MUX3_1_V
`include "./source/header.vh"

module mux3_1(
    write_back_data,
    data,
    alu_value,
    cross_data,
    forwarding,
    data_out
);
    input [1 : 0] forwarding;
    input [`DWIDTH - 1 : 0] data;
    input [`DWIDTH - 1 : 0] alu_value;
    input [`DWIDTH - 1 : 0] cross_data;
    input [`DWIDTH - 1 : 0] write_back_data;
    output [`DWIDTH - 1 : 0] data_out;

    assign data_out = (forwarding == 2'd2) ? write_back_data :
                      (forwarding == 2'd1) ? alu_value :
                      (forwarding == 2'd3) ? cross_data :
                                             data;
endmodule
`endif 
