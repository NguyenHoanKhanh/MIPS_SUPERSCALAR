`ifndef MUX21_V
`define MUX21_V

module mux (
    a, b, c
);
    input a, b;
    output c;

    assign c = (!b) ? a : 1'b0; 
endmodule
`endif 