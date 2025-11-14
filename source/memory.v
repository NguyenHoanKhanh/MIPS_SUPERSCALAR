`ifndef MEMORY_V
`define MEMORY_V
`include "./source/header.vh"

module memory (
    m_clk, m_rst, m_i_ce_1, m_i_ce_2, m_i_wr_en_1, m_i_mask_1, m_i_alu_value_1, m_i_data_rs_1, m_o_load_data_1,
    m_i_wr_en_2, m_i_mask_2, m_i_alu_value_2, m_i_data_rs_2, m_o_load_data_2
);
    input m_i_wr_en_1;
    input m_i_wr_en_2;
    input m_clk, m_rst;
    input m_i_ce_1, m_i_ce_2;
    input [3 : 0] m_i_mask_1;
    input [3 : 0] m_i_mask_2;
    input [`DWIDTH - 1 : 0] m_i_data_rs_1;
    input [`DWIDTH - 1 : 0] m_i_data_rs_2;
    input [`AWIDTH_MEM - 1 : 0] m_i_alu_value_1;
    input [`AWIDTH_MEM - 1 : 0] m_i_alu_value_2;
    output [`DWIDTH - 1 : 0] m_o_load_data_1;
    output [`DWIDTH - 1 : 0] m_o_load_data_2;

    reg [`DWIDTH - 1 : 0] data_mem_1 [`AWIDTH_MEM - 1 : 0];
    reg [`DWIDTH - 1 : 0] data_mem_2 [`AWIDTH_MEM - 1 : 0];
    integer i;

    always @(negedge m_clk, negedge m_rst) begin
        if (!m_rst) begin
            for (i = 0; i < `AWIDTH_MEM; i = i + 1) begin
                data_mem_1[i] <= i;
                data_mem_2[i] <= i;
            end
        end
        else begin
            if (m_i_ce_1) begin
                if (m_i_wr_en_1) begin
                    if (m_i_mask_1[0]) begin
                        data_mem_1[m_i_alu_value_1][7 : 0] <= m_i_data_rs_1[7 : 0];
                    end
                    else if (m_i_mask_1[1]) begin
                        data_mem_1[m_i_alu_value_1][15 : 8] <= m_i_data_rs_1[15 : 8];
                    end
                    else if (m_i_mask_1[2]) begin
                        data_mem_1[m_i_alu_value_1][23 : 16] <= m_i_data_rs_1[23 : 16];
                    end
                    else if (m_i_mask_1[3]) begin
                        data_mem_1[m_i_alu_value_1][31 : 24] <= m_i_data_rs_1[31 : 24];
                    end
                end
            end
            if (m_i_ce_2) begin
                if (m_i_wr_en_2) begin
                    if (m_i_mask_2[0]) begin
                        data_mem_2[m_i_alu_value_2][7 : 0] <= m_i_data_rs_2[7 : 0];
                    end 
                    else if (m_i_mask_2[1]) begin
                        data_mem_2[m_i_alu_value_2][15 : 8] <= m_i_data_rs_2[15 : 8];
                    end
                    else if (m_i_mask_2[2]) begin
                        data_mem_2[m_i_alu_value_2][23 : 16] <= m_i_data_rs_2[23 : 16];
                    end
                    else if (m_i_mask_2[3]) begin
                        data_mem_2[m_i_alu_value_2][31 : 24] <= m_i_data_rs_2[31 : 24];
                    end
                end
            end
        end
    end
    assign m_o_load_data_1 = data_mem_1[m_i_alu_value_1];
    assign m_o_load_data_2 = data_mem_2[m_i_alu_value_2];
endmodule
`endif 