`ifndef TREAT_LOAD_V
`define TREAT_LOAD_V
`include "./source/header.vh"

module treatload(
    tl_i_load_data, tl_i_opcode, tl_o_load_data
);
    input [`DWIDTH - 1 : 0] tl_i_load_data;
    input [`OPCODE_WIDTH - 1 : 0] tl_i_opcode;
    output reg [`DWIDTH - 1 : 0] tl_o_load_data;

    always @(*) begin
        tl_o_load_data = {`DWIDTH{1'b0}};
        case (tl_i_opcode)
            `LOAD_BYTE : begin
                tl_o_load_data = {{24{tl_i_load_data[7]}}, tl_i_load_data[7 : 0]};
            end 
            `LOAD_BYTE_UNSIGNED : begin
                tl_o_load_data = {{24{1'b0}}, tl_i_load_data[7 : 0]};
            end
            `LOAD_HALF : begin
                tl_o_load_data = {{16{tl_i_load_data[15]}}, tl_i_load_data[15 : 0]};
            end
            `LOAD_HALF_UNSIGNED : begin
                tl_o_load_data = {{16{1'b0}}, tl_i_load_data[15 : 0]};
            end
            `LOAD_WORD : begin
                tl_o_load_data = tl_i_load_data;
            end
            default : begin
                tl_o_load_data = {`DWIDTH{1'b0}};
            end 
        endcase
    end
endmodule
`endif 