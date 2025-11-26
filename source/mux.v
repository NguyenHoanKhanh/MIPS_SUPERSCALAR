`ifndef MUX_V
`define MUX_V

module mux (
    ds1_es1_o_ce, ds2_es2_o_ce, cd1_o_we, cd2_o_we, es1_o_ce, es2_o_ce
);
    input ds1_es1_o_ce, ds2_es2_o_ce;
    input cd1_o_we, cd2_o_we;
    output reg es1_o_ce, es2_o_ce;

    always @(*) begin
        es1_o_ce = 1'b0;
        es2_o_ce = 1'b0;
        if (ds1_es1_o_ce) begin
            if (cd1_o_we) begin
                es1_o_ce = 1'b1;
                es2_o_ce = 1'b0;
            end
            else begin
                es1_o_ce = 1'b1;
                es2_o_ce = 1'b0;
            end
        end
        else if (ds2_es2_o_ce) begin
            if (cd2_o_we) begin
                es1_o_ce = 1'b0;
                es2_o_ce = 1'b1;
            end
            else begin
                es1_o_ce = 1'b0;
                es2_o_ce = 1'b1;
            end
        end
    end   
endmodule
`endif 