`ifndef QUEUE_INSTR_V
`define QUEUE_INSTR_V
`include "./source/header.vh"

module queue_instr (
    q_clk, q_rst, q_i_instr, q_i_we, q_i_re, q_o_instr
);
    input q_clk, q_rst;
    input q_i_we, q_i_re;
    input [`IWIDTH - 1 : 0] q_i_instr;
    output [`IWIDTH - 1 : 0] q_o_instr;

    integer i;
    reg [(2 ** `DEPTH) - 1 : 0] counter;
    reg [(2 ** `DEPTH) - 1 : 0] from_begin, from_end;
    reg [`IWIDTH - 1 : 0] data_instr [(2 ** `DEPTH) - 1 : 0];
    assign q_o_instr = data_instr[from_end];
    always @(negedge q_clk, negedge q_rst) begin
        if (!q_rst) begin
            for (i = 0; i < 2 ** `DEPTH; i = i + 1) begin
                data_instr[i] <= {`IWIDTH{1'b0}};
            end
            counter <= 0;
            from_begin <= 0;
            from_end <= 0;
        end
        else begin
            if (q_i_we) begin
                if (counter < (2 ** `DEPTH)) begin
                    data_instr[from_begin] <= q_i_instr;
                    from_begin <= (from_begin == (2 ** `DEPTH) - 1) ? 0 : from_begin + 1;
                    counter <= counter + 1;
                end
            end
            if (q_i_re) begin
                if (counter > 0) begin
                    from_end <= (from_end == (2 ** `DEPTH) - 1) ? 0 : from_end + 1;
                    counter <= counter - 1;
                end
            end
        end
    end
endmodule
`endif 
