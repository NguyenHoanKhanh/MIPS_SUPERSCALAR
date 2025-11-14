`ifndef EXECUTE_STAGE_V
`define EXECUTE_STAGE_V
`include "./source/alu.v"
`include "./source/header.vh"
`include "./source/alu_control.v"
`include "./source/treat_jal.v"

module execute (
    es_i_ce, es_i_jr, es_i_jal, es_i_jal_addr, es_i_pc, es_i_alu_src, es_i_imm, es_i_alu_op, es_i_alu_funct,
    es_i_data_rs, es_i_data_rt, es_o_alu_value, es_o_ce, es_o_change_pc, es_o_alu_pc, es_o_opcode
);  
    input es_i_ce;
    input es_i_jr;
    input es_i_jal;
    input es_i_alu_src;
    input [`PC_WIDTH - 1 : 0] es_i_pc;
    input [`IMM_WIDTH - 1 : 0] es_i_imm;
    input [`JUMP_WIDTH - 1 : 0] es_i_jal_addr;
    input [`OPCODE_WIDTH - 1 : 0] es_i_alu_op;
    input [`FUNCT_WIDTH - 1 : 0]  es_i_alu_funct;
    input [`DWIDTH - 1 : 0] es_i_data_rs, es_i_data_rt;
    output reg es_o_ce;
    output es_o_change_pc;
    output [`PC_WIDTH - 1 : 0] es_o_alu_pc;
    output reg [`DWIDTH - 1 : 0] es_o_alu_value;
    output reg [`OPCODE_WIDTH - 1 : 0] es_o_opcode;

    // alu_control computed combinationally from opcode/funct
    wire [4 : 0] alu_control;
    alucontrol ac (
        .ac_i_opcode(es_i_alu_op), 
        .ac_i_funct(es_i_alu_funct), 
        .ac_o_control(alu_control)
    );

    // instantiate combinational ALU
    wire change_pc;
    wire [`PC_WIDTH - 1 : 0] alu_pc;
    wire [`DWIDTH - 1 : 0] alu_value;
    alu a (
        .a_i_pc(es_i_pc), 
        .a_i_imm(es_i_imm), 
        .a_i_funct(alu_control), 
        .a_i_data_rs(es_i_data_rs), 
        .a_i_data_rt(es_i_data_rt), 
        .a_i_alu_src(es_i_alu_src), 
        .alu_pc(alu_pc), 
        .alu_value(alu_value), 
        .a_o_change_pc(change_pc)
    );

    wire [`PC_WIDTH - 1 : 0] temp_pc;
    wire [`PC_WIDTH - 1 : 0] temp_ra;
    wire temp_jal_change_pc;
    treat_jal tj (
        .tj_i_pc(es_i_pc), 
        .tj_i_jal(es_i_jal), 
        .tj_i_jal_addr(es_i_jal_addr), 
        .tj_o_ra(temp_ra),
        .tj_o_pc(temp_pc), 
        .tj_o_change_pc(temp_jal_change_pc)
    );

    wire take_jr = es_i_jr;
    wire take_jal = es_i_jal;
    assign es_o_change_pc = (take_jal & temp_jal_change_pc) 
                            || (take_jr && change_pc);
    assign es_o_alu_pc = (take_jr && change_pc) ? alu_pc 
                        : (take_jal && temp_jal_change_pc) ? temp_pc : {`PC_WIDTH{1'b0}};
    
    wire [`DWIDTH - 1 : 0] temp_alu_value;
    assign temp_alu_value = (take_jal) ? temp_ra : alu_value;
    // register outputs on clock
    always @(*) begin
        es_o_ce = 1'b0;
        es_o_alu_value = {`DWIDTH{1'b0}};
        es_o_opcode = {`OPCODE_WIDTH{1'b0}};
        if (es_i_ce) begin
            es_o_ce = 1'b1;
            es_o_opcode = es_i_alu_op;
            es_o_alu_value = temp_alu_value;
        end
        else begin
            es_o_ce = 1'b0;
            es_o_alu_value = {`DWIDTH{1'b0}};
            es_o_opcode = {`OPCODE_WIDTH{1'b0}};
        end
    end
endmodule
`endif