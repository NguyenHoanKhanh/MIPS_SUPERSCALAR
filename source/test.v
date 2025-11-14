`ifndef QUEUE_V
`define QUEUE_V
`timescale 1ns/1ps

module queue (
    clk, rst, reading, writing, register_to_queue, queue_to_register
);
    input clk, rst;
    input reading, writing;
    input [255 : 0] register_to_queue;
    output reg [255 : 0] queue_to_register;
    reg [15 : 0] size = 16'b0;
    reg [15 : 0] from_begin = 16'b0, from_end = 16'b0;
    reg [255 : 0] data [16'hFFFF : 0];
    assign size_queue = size;
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            queue_to_register <= 256'd0;
        end
        else if (writing == 1'b1 ) begin
            if(size < 16'hFFFe) begin
                data[from_begin] <= register_to_queue;
                from_begin <= from_begin + 1;
                size <= size + 1;
            end
        end
        else if (reading == 1'b1) begin
            if (size > 0) begin
                queue_to_register <= data[from_end];
                from_end <= from_end + 1;
                size <= size - 1;
            end
        end
    end
endmodule
`endif