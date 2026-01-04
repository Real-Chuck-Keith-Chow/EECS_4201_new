import constants_pkg::*;
/*
 * -------- REPLACE THIS FILE WITH THE MEMORY MODULE DEVELOPED IN PD1 -----------
 * Module: memory
 *
 * Description: Byte-addressable memory implementation. Supports both read and write.
 *
 * Inputs:
 * 1) clk
 * 2) rst signal
 * 3) AWIDTH address addr_i
 * 4) DWIDTH data to write data_i
 * 5) read enable signal read_en_i
 * 6) write enable signal write_en_i
 *
 * Outputs:
 * 1) DWIDTH data output data_o
 * 2) probe_data_o (debug/trace: current addressed word, little-endian)
 */

module memory #(
    //parameters
    parameter int AWIDTH = ADDR_WIDTH,
    parameter int DWIDTH = DATA_WIDTH,
    parameter logic [31:0] BASE_ADDR = MEM_BASE_ADDR
) (
    //inputs
    input  logic                 clk,
    input  logic                 rst,
    input  logic [AWIDTH-1:0]    addr_i,
    input  logic [DWIDTH-1:0]    data_i,
    input  logic                 read_en_i,
    input  logic                 write_en_i,
    input  logic [1:0]           size_i,
    input  logic                 unsigned_load_i,
    //outputs
    output logic [DWIDTH-1:0]    data_o,
    output logic [DWIDTH-1:0]    probe_data_o
);

    `ifndef LINE_COUNT
        `define LINE_COUNT 1024  //default if not defined
    `endif

    `ifndef MEM_PATH
        `define MEM_PATH "test.x"  //default if not defined
    `endif

    `ifndef MEM_DEPTH
        `define MEM_DEPTH (`LINE_COUNT * 4)
    `endif

    localparam int WORD_BYTES  = (DWIDTH/8);
    localparam int MEM_BYTES   = `MEM_DEPTH;
    localparam int MEM_WORDS   = MEM_BYTES / WORD_BYTES;
    localparam int INIT_WORDS  = (`LINE_COUNT < MEM_WORDS) ? `LINE_COUNT : MEM_WORDS;

    logic [DWIDTH-1:0] temp_memory [0:`LINE_COUNT - 1];

    // byte-addressable memory
    logic [7:0] main_memory [0:MEM_BYTES - 1];

    localparam logic [AWIDTH-1:0] MEM_ADDR_MASK     = MEM_BYTES - 1;
    localparam int unsigned       MEM_ADDR_MASK_INT = MEM_BYTES - 1;

    int i;

    //initialization
    initial begin
        //zero entire byte array
        for (i = 0; i < MEM_BYTES; i++) begin
            main_memory[i] = '0;
        end

        //little-endian
        $readmemh(`MEM_PATH, temp_memory);
        for (i = 0; i < INIT_WORDS; i++) begin
            main_memory[WORD_BYTES*i + 0] = temp_memory[i][7:0];
            main_memory[WORD_BYTES*i + 1] = temp_memory[i][15:8];
            main_memory[WORD_BYTES*i + 2] = temp_memory[i][23:16];
            main_memory[WORD_BYTES*i + 3] = temp_memory[i][31:24];
        end
        $display("MEMORY: Loaded %0d 32-bit words from %s", INIT_WORDS, `MEM_PATH);
    end

    //read path + probe
    always_comb begin
        automatic int unsigned       access_bytes;
        automatic logic              addr_valid;
        automatic logic              word_addr_valid;
        automatic logic [AWIDTH-1:0] addr_offset;
        automatic int unsigned       addr_base;
        automatic logic [DWIDTH-1:0] raw_data;
        automatic logic [DWIDTH-1:0] word_data;
        automatic logic [7:0]        byte_val;
        automatic logic [15:0]       half_val;

        data_o         = '0;
        probe_data_o   = '0;
        addr_valid     = 1'b0;
        word_addr_valid= 1'b0;
        raw_data       = '0;
        word_data      = '0;
        byte_val       = '0;
        half_val       = '0;
        addr_offset    = '0;
        addr_base      = '0;

        access_bytes = size_to_bytes(size_i);

        //derive masked base address when valid
        if (!$isunknown(addr_i)) begin
            addr_offset     = compute_offset(addr_i);
            addr_base       = addr_offset & MEM_ADDR_MASK_INT;
            addr_valid      = 1'b1;
            word_addr_valid = 1'b1;
        end

        //gather requested number of bytes into raw_data
        if (addr_valid) begin
            for (int idx = 0; idx < access_bytes; idx++) begin
                automatic int unsigned byte_index;
                byte_index = (addr_base + idx) & MEM_ADDR_MASK_INT;
                raw_data[idx*8 +: 8] = main_memory[byte_index];
            end
        end

        //gather full word for probing regardless of size
        if (word_addr_valid) begin
            for (int idx = 0; idx < WORD_BYTES; idx++) begin
                automatic int unsigned byte_index;
                byte_index = (addr_base + idx) & MEM_ADDR_MASK_INT;
                word_data[idx*8 +: 8] = main_memory[byte_index];
            end
        end

        byte_val      = raw_data[7:0];
        half_val      = raw_data[15:0];
        probe_data_o  = word_addr_valid ? word_data : '0;

        unique case (size_i)
            MEM_SIZE_BYTE: begin
                data_o = unsigned_load_i
                       ? {{DWIDTH-8{1'b0}},        byte_val}
                       : {{DWIDTH-8{byte_val[7]}}, byte_val};
            end
            MEM_SIZE_HALF: begin
                data_o = unsigned_load_i
                       ? {{DWIDTH-16{1'b0}},          half_val}
                       : {{DWIDTH-16{half_val[15]}},  half_val};
            end
            default: begin
                data_o = raw_data;
            end
        endcase

        //OOB
        if (!addr_valid && read_en_i && !$isunknown(addr_i)) begin
            data_o = 32'hDEAD_BEEF;
            $display("MEMORY: OOB read @0x%08h", addr_i);
        end
    end

 
    //synchronous write path
    always @(posedge clk) begin
        if (!rst && write_en_i) begin
            automatic int unsigned access_bytes;
            automatic int unsigned addr_base;

            access_bytes = size_to_bytes(size_i);
            addr_base    = compute_offset(addr_i) & MEM_ADDR_MASK_INT;

            if (!$isunknown(addr_i)) begin
                unique case (size_i)
                    MEM_SIZE_BYTE: begin
                        main_memory[addr_base] <= data_i[7:0];
                    end
                    MEM_SIZE_HALF: begin
                        main_memory[addr_base]                               <= data_i[7:0];
                        main_memory[(addr_base + 1) & MEM_ADDR_MASK_INT]     <= data_i[15:8];
                    end
                    default: begin
                        for (int idx = 0; idx < WORD_BYTES; idx++) begin
                            automatic int unsigned byte_index;
                            byte_index = (addr_base + idx) & MEM_ADDR_MASK_INT;
                            main_memory[byte_index] <= data_i[idx*8 +: 8];
                        end
                    end
                endcase
                $display("MEMORY: Wrote 0x%08h to 0x%08h (size=%0d)", data_i, addr_i, access_bytes);
            end
        end
    end

    //helpers
    function automatic int unsigned size_to_bytes(input logic [1:0] size);
        case (size)
            MEM_SIZE_BYTE: return 1;
            MEM_SIZE_HALF: return 2;
            default:       return WORD_BYTES;
        endcase
    endfunction

    function automatic logic [AWIDTH-1:0] compute_offset(input logic [AWIDTH-1:0] addr);
        compute_offset = (addr - BASE_ADDR) & MEM_ADDR_MASK;
    endfunction

endmodule : memory
