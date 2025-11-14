`ifndef ALU_V
`define ALU_V
`include "./source/header.vh"
module alu (
    a_i_data_rs, a_i_data_rt, a_i_imm, a_i_funct, a_i_alu_src, a_i_pc, 
    alu_value, alu_pc, a_o_change_pc
);
    input a_i_alu_src;
    input [4 : 0] a_i_funct;
    input [`PC_WIDTH - 1 : 0] a_i_pc;
    input [`IMM_WIDTH - 1 : 0] a_i_imm;
    input [`DWIDTH - 1 : 0] a_i_data_rs;
    input [`DWIDTH - 1 : 0] a_i_data_rt;
    output reg a_o_change_pc;
    output reg [`PC_WIDTH - 1 : 0] alu_pc;
    output reg [`DWIDTH - 1 : 0] alu_value;
    // sign-extend immediate (parameterized)
    wire [`DWIDTH - 1 : 0] a_imm = {{(`DWIDTH - `IMM_WIDTH){a_i_imm[`IMM_WIDTH - 1]}}, a_i_imm};
    wire [`DWIDTH - 1 : 0] a_o_data_2 = (a_i_alu_src) ? a_imm : a_i_data_rt;

    // funct signals (optional, for readability)
    wire funct_add  = a_i_funct == 5'd0;
    wire funct_sub  = a_i_funct == 5'd1;
    wire funct_and  = a_i_funct == 5'd2;
    wire funct_or   = a_i_funct == 5'd3;
    wire funct_nor  = a_i_funct == 5'd4;
    wire funct_slt  = a_i_funct == 5'd5;
    wire funct_sltu = a_i_funct == 5'd6;
    wire funct_sll  = a_i_funct == 5'd7;
    wire funct_srl  = a_i_funct == 5'd8;
    wire funct_sra  = a_i_funct == 5'd9;
    wire funct_eq   = a_i_funct == 5'd10;
    wire funct_neq  = a_i_funct == 5'd11;
    wire funct_ge   = a_i_funct == 5'd12;
    wire funct_geu  = a_i_funct == 5'd13;
    wire funct_addu = a_i_funct == 5'd14;
    wire funct_subu = a_i_funct == 5'd17;
    wire funct_lui  = a_i_funct == 5'd18;
    wire funct_jr = a_i_funct == 5'd19;
    // combinational ALU: always @*
    always @(*) begin
        alu_value = {`DWIDTH{1'b0}};
        alu_pc = {`PC_WIDTH{1'b0}};
        a_o_change_pc = 1'b0;
        if (funct_add) begin
            alu_value = a_i_data_rs + a_o_data_2;
        end
        else if (funct_addu) begin
            alu_value = $unsigned(a_i_data_rs) + $unsigned(a_o_data_2);
        end
        else if (funct_sub) begin
            alu_value = a_i_data_rs - a_o_data_2;
        end
        else if (funct_subu) begin
            alu_value = $unsigned(a_i_data_rs) - $unsigned(a_o_data_2); 
        end
        else if (funct_and) begin
            alu_value = a_i_data_rs & a_o_data_2;
        end
        else if (funct_or) begin
            alu_value = a_i_data_rs | a_o_data_2;
        end
        else if (funct_nor) begin
            alu_value = ~(a_i_data_rs | a_o_data_2);
        end
        else if (funct_slt) begin
            if (($signed(a_i_data_rs) < $signed(a_o_data_2))) begin
                alu_value = {{(`DWIDTH - 1){1'b0}}, 1'b1};
            end
            else begin
                alu_value = {`DWIDTH{1'b0}};
            end
        end
        else if (funct_sltu) begin
            if (($unsigned(a_i_data_rs) < $unsigned(a_o_data_2))) begin
                alu_value ={{(`DWIDTH - 1){1'b0}}, 1'b1};
            end
            else begin
                alu_value = {`DWIDTH{1'b0}};
            end
        end
        else if (funct_sll) begin
            alu_value = a_i_data_rs << a_o_data_2[4 : 0];
        end
        else if (funct_srl) begin
            alu_value = a_i_data_rs >> a_o_data_2[4 : 0];
        end
        else if (funct_sra) begin
            alu_value = $signed(a_i_data_rs) >>> a_o_data_2[4 : 0];
        end
        else if (funct_eq) begin
            alu_value = (a_i_data_rs == a_o_data_2) ? 32'd1 : 32'd0;
        end
        else if (funct_neq) begin
            alu_value = (a_i_data_rs == a_o_data_2) ? 32'd0 : 32'd1;
        end
        else if (funct_ge) begin
            if (($signed(a_i_data_rs) >= $signed(a_o_data_2))) begin
                alu_value = {{(`DWIDTH - 1){1'b0}},1'b1};
            end
            else begin
                alu_value = {`DWIDTH{1'b0}};
            end
        end
        else if (funct_geu) begin
            if (($unsigned(a_i_data_rs) >= $unsigned(a_o_data_2))) begin
                alu_value = {{(`DWIDTH - 1){1'b0}},1'b1};
            end
            else begin
                alu_value = {`DWIDTH{1'b0}};
            end
        end
        else if (funct_lui) begin
            alu_value = {a_i_imm, 16'b0};
        end
        else if (funct_jr) begin
            alu_pc = a_i_data_rs;
            a_o_change_pc = 1'b1;
        end
        else begin
            alu_pc = {`PC_WIDTH{1'b0}};
            alu_value = {`DWIDTH{1'b0}};
            a_o_change_pc = 1'b0;
        end
    end
endmodule
`endif