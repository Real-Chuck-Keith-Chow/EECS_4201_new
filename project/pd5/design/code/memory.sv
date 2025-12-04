/*
 * Module: memory
 *
 * Description: Memory implementation for RV32I CPU.
 * Uses word-based storage for $readmemh compatibility.
 * Supports byte, halfword, and word access.
 *
 * Inputs:
 * 1) clk
 * 2) rst signal
 * 3) AWIDTH address addr_i
 * 4) DWIDTH data to write data_i
 * 5) read enable signal read_en_i
 * 6) write enable signal write_en_i
 * 7) size_i - 2'b00=byte, 2'b01=half, 2'b10=word
 *
 * Outputs:
 * 1) DWIDTH data output data_o
 */
`include "constants.svh"

module memory #(
    parameter int DWIDTH = 32,
    parameter int AWIDTH = 32,
    parameter int DEPTH = `MEM_DEPTH
)(
    input logic clk,
    input logic rst,
    input logic [AWIDTH-1:0] addr_i,
    input logic [DWIDTH-1:0] data_i,
    input logic read_en_i,
    input logic write_en_i,
    input logic [1:0] size_i,       // 00=byte, 01=half, 10=word
    input logic sign_extend_i,      // Sign extend for loads
    output logic [DWIDTH-1:0] data_o
);

    // Calculate the number of words and required index width
    localparam int NUM_WORDS = DEPTH / 4;
    localparam int INDEX_WIDTH = $clog2(NUM_WORDS);

    // Memory array - word addressable (each entry is 32 bits)
    reg [31:0] mem [0:NUM_WORDS-1];

    // Load memory from file at initialization
    initial begin
        $readmemh(`MEM_PATH, mem);
    end

    // Calculate word address (subtract base, then divide by 4)
    wire [AWIDTH-1:0] byte_offset = addr_i - PC_START;
    wire [INDEX_WIDTH-1:0] word_addr = byte_offset[INDEX_WIDTH+1:2];  // Divide by 4, properly sized
    wire [1:0] byte_sel = byte_offset[1:0];  // Byte within word
    
    // Read the word from memory
    wire [31:0] mem_word = mem[word_addr];
    
    // combinational read path, handles sign extension per access size
    always_comb begin
        data_o = 32'b0;
        if (read_en_i) begin
            case (size_i)
                2'b00: begin // Byte
                    case (byte_sel)
                        2'b00: data_o = sign_extend_i ? {{24{mem_word[7]}}, mem_word[7:0]} : {24'b0, mem_word[7:0]};
                        2'b01: data_o = sign_extend_i ? {{24{mem_word[15]}}, mem_word[15:8]} : {24'b0, mem_word[15:8]};
                        2'b10: data_o = sign_extend_i ? {{24{mem_word[23]}}, mem_word[23:16]} : {24'b0, mem_word[23:16]};
                        2'b11: data_o = sign_extend_i ? {{24{mem_word[31]}}, mem_word[31:24]} : {24'b0, mem_word[31:24]};
                    endcase
                end
                2'b01: begin // Halfword
                    case (byte_sel[1])
                        1'b0: data_o = sign_extend_i ? {{16{mem_word[15]}}, mem_word[15:0]} : {16'b0, mem_word[15:0]};
                        1'b1: data_o = sign_extend_i ? {{16{mem_word[31]}}, mem_word[31:16]} : {16'b0, mem_word[31:16]};
                    endcase
                end
                2'b10: begin // Word
                    data_o = mem_word;
                end
                default: begin
                    data_o = mem_word;
                end
            endcase
        end
    end

    // sequential write path, byte/half/word aware
    always_ff @(posedge clk) begin
        if (write_en_i && !rst) begin
            case (size_i)
                2'b00: begin // Byte
                    case (byte_sel)
                        2'b00: mem[word_addr][7:0]   <= data_i[7:0];
                        2'b01: mem[word_addr][15:8]  <= data_i[7:0];
                        2'b10: mem[word_addr][23:16] <= data_i[7:0];
                        2'b11: mem[word_addr][31:24] <= data_i[7:0];
                    endcase
                end
                2'b01: begin // Halfword
                    case (byte_sel[1])
                        1'b0: mem[word_addr][15:0]  <= data_i[15:0];
                        1'b1: mem[word_addr][31:16] <= data_i[15:0];
                    endcase
                end
                2'b10: begin // Word
                    mem[word_addr] <= data_i;
                end
                default: begin
                    mem[word_addr] <= data_i;
                end
            endcase
        end
    end

endmodule : memory
