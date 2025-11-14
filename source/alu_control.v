`ifndef ALU_CONTROL_V
`define ALU_CONTROL_V
`include "./source/header.vh"

module alucontrol (
    ac_i_opcode, ac_i_funct, ac_o_control
);
    input [`OPCODE_WIDTH - 1 : 0] ac_i_opcode;
    input [`FUNCT_WIDTH - 1 : 0] ac_i_funct;
    output reg [`ALU_CONTROL - 1 : 0] ac_o_control;

    always @(*) begin
        ac_o_control = {`ALU_CONTROL{1'b0}};
        if (ac_i_opcode == `RTYPE) begin
            case (ac_i_funct)
                `ADD:  ac_o_control = 5'd0;
                `SUB:  ac_o_control = 5'd1;
                `AND:  ac_o_control = 5'd2;
                `OR:   ac_o_control = 5'd3;
                `NOR : ac_o_control = 5'd4;
                `SLT:  ac_o_control = 5'd5;
                `SLTU: ac_o_control = 5'd6;
                `SLL:  ac_o_control = 5'd7;
                `SRL:  ac_o_control = 5'd8;
                `SRA:  ac_o_control = 5'd9;
                `EQ:   ac_o_control = 5'd10;
                `NEQ:  ac_o_control = 5'd11;
                `GE:   ac_o_control = 5'd12;
                `GEU:  ac_o_control = 5'd13;
                `ADDU : ac_o_control = 5'd14;
                `SUBU : ac_o_control = 5'd17;
                `JR : ac_o_control = 5'd19;
                default: ac_o_control = 5'd0;
            endcase
        end
        else if (ac_i_opcode == `ADDI) begin
            ac_o_control = 5'd0;
        end
        else if (ac_i_opcode == `ADDIU) begin
            ac_o_control = 5'd14;
        end
        else if (ac_i_opcode == `SLTI) begin
            ac_o_control = 5'd5;
        end
        else if (ac_i_opcode == `SLTIU) begin
            ac_o_control = 5'd6;
        end
        else if (ac_i_opcode == `ANDI) begin
            ac_o_control = 5'd2;
        end
        else if (ac_i_opcode == `ORI) begin
            ac_o_control = 5'd3;
        end
        else if (ac_i_opcode == `LUI) begin
            ac_o_control = 5'd18;
        end
        else if (ac_i_opcode == `LOAD_WORD || ac_i_opcode == `LOAD_BYTE || ac_i_opcode == `LOAD_HALF || 
                ac_i_opcode == `LOAD_BYTE_UNSIGNED || ac_i_opcode == `LOAD_HALF_UNSIGNED || 
                ac_i_opcode == `STORE_WORD || ac_i_opcode == `STORE_BYTE || ac_i_opcode == `STORE_HALF) begin
            ac_o_control = 5'd0;
        end
    end
endmodule
`endif 