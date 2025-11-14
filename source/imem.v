`ifndef IMEM_V
`define IMEM_V
`include "./source/header.vh"

module imem (
    im_clk, im_rst, im_i_ce, im_i_addr_1, im_i_addr_2, im_o_instr_1, 
    im_o_instr_2, im_o_ce
);
    input im_clk, im_rst;
    input im_i_ce;
    input [`PC_WIDTH - 1 : 0] im_i_addr_1, im_i_addr_2;
    output reg [`IWIDTH - 1 : 0] im_o_instr_1, im_o_instr_2;
    output reg im_o_ce;

    reg [`IWIDTH - 1 : 0] mem_instr [`DEPTH - 1 : 0];

    always @(posedge im_clk, negedge im_rst) begin
        if (!im_rst) begin
            $readmemh("./source/imem.txt", mem_instr, 0, `DEPTH - 1);
            im_o_ce <= 1'b0;
            im_o_instr_1 <= {`IWIDTH{1'b0}};
            im_o_instr_2 <= {`IWIDTH{1'b0}};
        end
        else begin
            if (im_i_ce) begin
                im_o_ce <= 1'b1;
                im_o_instr_1 <= mem_instr[im_i_addr_1[`PC_WIDTH - 1 : 2]];
                im_o_instr_2 <= mem_instr[im_i_addr_2[`PC_WIDTH - 1 : 2]];
            end
            else begin
                im_o_ce <= 1'b0;
                im_o_instr_1 <= {`PC_WIDTH{1'b0}};
                im_o_instr_2 <= {`PC_WIDTH{1'b0}};
            end
        end
    end
endmodule
`endif