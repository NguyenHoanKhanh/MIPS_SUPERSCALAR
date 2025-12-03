`ifndef FORWARDING_V
`define FORWARDING_V
`include "./source/header.vh"

module forwarding (
    ds_es_i_addr_rs1,
    ds_es_i_addr_rs2,
    self_ex_i_addr_rd,
    self_ex_i_regwrite,
    self_ex_i_memread,
    self_wb_i_addr_rd,
    self_wb_i_regwrite,
    cross_ex_i_addr_rd,
    cross_ex_i_regwrite,
    cross_ex_i_memread,
    cross_wb_i_addr_rd,
    cross_wb_i_regwrite,
    f_o_control_rs1,
    f_o_control_rs2,
    f_o_stall
);
    input [`AWIDTH - 1 : 0] ds_es_i_addr_rs1;
    input [`AWIDTH - 1 : 0] ds_es_i_addr_rs2;

    input [`AWIDTH - 1 : 0] self_ex_i_addr_rd;
    input self_ex_i_regwrite;
    input self_ex_i_memread;

    input [`AWIDTH - 1 : 0] self_wb_i_addr_rd;
    input self_wb_i_regwrite;

    input [`AWIDTH - 1 : 0] cross_ex_i_addr_rd;
    input cross_ex_i_regwrite;
    input cross_ex_i_memread;

    input [`AWIDTH - 1 : 0] cross_wb_i_addr_rd;
    input cross_wb_i_regwrite;

    output reg [1 : 0] f_o_control_rs1, f_o_control_rs2;
    output reg f_o_stall;

    wire rs1_nonzero = |ds_es_i_addr_rs1;
    wire rs2_nonzero = |ds_es_i_addr_rs2;

    always @(*) begin
        f_o_control_rs1 = 2'd0;
        if (rs1_nonzero) begin
            if ((ds_es_i_addr_rs1 == self_ex_i_addr_rd) && self_ex_i_regwrite && !self_ex_i_memread) begin
                f_o_control_rs1 = 2'd1;
            end
            else if ((ds_es_i_addr_rs1 == cross_ex_i_addr_rd) && cross_ex_i_regwrite && !cross_ex_i_memread) begin
                f_o_control_rs1 = 2'd3;
            end
            else if ((ds_es_i_addr_rs1 == self_wb_i_addr_rd) && self_wb_i_regwrite) begin
                f_o_control_rs1 = 2'd2;
            end
        end

        f_o_control_rs2 = 2'd0;
        if (rs2_nonzero) begin
            if ((ds_es_i_addr_rs2 == self_ex_i_addr_rd) && self_ex_i_regwrite && !self_ex_i_memread) begin
                f_o_control_rs2 = 2'd1;
            end
            else if ((ds_es_i_addr_rs2 == cross_ex_i_addr_rd) && cross_ex_i_regwrite && !cross_ex_i_memread) begin
                f_o_control_rs2 = 2'd3;
            end
            else if ((ds_es_i_addr_rs2 == self_wb_i_addr_rd) && self_wb_i_regwrite) begin
                f_o_control_rs2 = 2'd2;
            end
        end
    end

    wire hazard_self_rs1 = self_ex_i_memread && self_ex_i_regwrite && rs1_nonzero &&
                            (ds_es_i_addr_rs1 == self_ex_i_addr_rd);
    wire hazard_self_rs2 = self_ex_i_memread && self_ex_i_regwrite && rs2_nonzero &&
                            (ds_es_i_addr_rs2 == self_ex_i_addr_rd);
    wire hazard_cross_rs1 = cross_ex_i_memread && cross_ex_i_regwrite && rs1_nonzero &&
                            (ds_es_i_addr_rs1 == cross_ex_i_addr_rd);
    wire hazard_cross_rs2 = cross_ex_i_memread && cross_ex_i_regwrite && rs2_nonzero &&
                            (ds_es_i_addr_rs2 == cross_ex_i_addr_rd);

    always @(*) begin
        f_o_stall = hazard_self_rs1 || hazard_self_rs2 ||
                    hazard_cross_rs1 || hazard_cross_rs2;
    end
endmodule
`endif 
