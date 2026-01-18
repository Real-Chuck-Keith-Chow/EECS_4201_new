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
 * 2) data out valid signal data_vld_o
 */

module memory #(
    // parameters
    parameter int AWIDTH = 32,
    parameter int DWIDTH = 32,
    parameter logic [31:0] BASE_ADDR = 32'h01000000
) (
    //inputs
    input logic clk,
    input logic rst,
    input logic [AWIDTH-1:0] addr_i,
    input logic [DWIDTH-1:0] data_i,
    input logic read_en_i,
    input logic write_en_i,
    //outputs
    output logic [DWIDTH-1:0] data_o
);

    `ifndef LINE_COUNT
        `define LINE_COUNT 1024  //default if not defined
    `endif
    
    `ifndef MEM_PATH
        `define MEM_PATH "test.x"  //default if not defined
    `endif

    localparam int MEM_BYTES = `LINE_COUNT * (DWIDTH/8);

    logic [DWIDTH-1:0] temp_memory [0:`LINE_COUNT - 1];
    //byte-addressable memory
    logic [7:0] main_memory [0:MEM_BYTES - 1];
    logic [AWIDTH-1:0] address;
    
    assign address = addr_i - BASE_ADDR;
    
    int i;
 
    initial begin
        $readmemh(`MEM_PATH, temp_memory);
        //load data from temp_memory into main_memory (little-endian)
        for (i = 0; i < `LINE_COUNT; i++) begin
            main_memory[4*i]     = temp_memory[i][7:0];
            main_memory[4*i + 1] = temp_memory[i][15:8];
            main_memory[4*i + 2] = temp_memory[i][23:16];
            main_memory[4*i + 3] = temp_memory[i][31:24];
        end
        $display("MEMORY: Loaded %0d 32-bit words from %s", `LINE_COUNT, `MEM_PATH);
    end

    always_comb begin
        data_o = '0; //default to zero
        if (read_en_i) begin
            if ($isunknown(addr_i)) begin
                data_o = '0;
            end else if ((addr_i >= BASE_ADDR) && (addr_i + 32'd3 < BASE_ADDR + MEM_BYTES)) begin
                //word-aligned fetch: little-endian assembly
                data_o = {
                    main_memory[address + 3],
                    main_memory[address + 2],
                    main_memory[address + 1],
                    main_memory[address]
                };
            end else begin
                data_o = 32'hDEAD_BEEF;
                $display("MEMORY: OOB read @0x%08h (mapped 0x%08h)", addr_i, address);
            end
        end
    end
	
    always_ff @(posedge clk) begin
        if (!rst && write_en_i) begin
            if ((addr_i >= BASE_ADDR) && (addr_i + 32'd3 < BASE_ADDR + MEM_BYTES)) begin
                main_memory[address] <= data_i[7:0];
                main_memory[address + 1] <= data_i[15:8];
                main_memory[address + 2] <= data_i[23:16];
                main_memory[address + 3] <= data_i[31:24];
                $display("MEMORY: Wrote 0x%08h to 0x%08h", data_i, addr_i);
            end else begin
                $display("MEMORY: OOB write @0x%08h", addr_i);
            end
        end
    end
 
endmodule : memory
