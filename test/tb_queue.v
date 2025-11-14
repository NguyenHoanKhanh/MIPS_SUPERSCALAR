`include "./source/queue_instr.v"

module tb;
    reg q_clk, q_rst;
    reg q_i_we, q_i_re;
    reg [`IWIDTH - 1 : 0] q_i_instr;
    wire [`IWIDTH - 1 : 0] q_o_instr;

    integer i;
    queue_instr q (
        .q_clk(q_clk), 
        .q_rst(q_rst), 
        .q_i_instr(q_i_instr), 
        .q_i_we(q_i_we), 
        .q_i_re(q_i_re), 
        .q_o_instr(q_o_instr)
    );

    initial begin
        i = 0;
        q_clk = 1'b0;
        q_i_we = 1'b0;
        q_i_re = 1'b0;
        q_i_instr = {`IWIDTH{1'b0}};
    end
    always #5 q_clk = ~q_clk;

    task reset (input integer counter);
        begin
            q_rst = 1'b0;
            repeat(counter) @(posedge q_clk);
            q_rst = 1'b1;
        end
    endtask

    task load (input integer counter);
        begin
            q_i_we = 1'b1;
            for (i = 0; i < counter; i = i + 1) begin
                @(posedge q_clk);
                q_i_instr = i;
            end
            q_i_we = 1'b0;
            @(posedge q_clk);
        end
    endtask

    task display (input integer counter);
        begin
            q_i_re = 1'b1;
            for (i = 0; i < counter; i = i + 1) begin
                @(posedge q_clk);
                $display($time, " ", " q_i_re = %b, q_o_instr = %d", q_i_re, q_o_instr);
            end
            q_i_re = 1'b0;
            @(posedge q_clk);
        end
    endtask 

    initial begin
        reset(2);
        load(10);
        @(posedge q_clk);
        display(10);
        @(posedge q_clk);
        $finish;
    end
endmodule