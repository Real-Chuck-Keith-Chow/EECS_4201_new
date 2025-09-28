/*
 * Module: memory
 *
 * Description: Byte-addressable memory implementation. Supports both read and write operations.
 *              Reads are combinational and writes are performed on the rising clock edge.
 *
 * Inputs:
 *   1) clk
 *   2) rst
 *   3) AWIDTH address addr_i          (absolute CPU address)
 *   4) DWIDTH data to write data_i    (only [7:0] used in PD1 writes)
 *   5) read enable signal  read_en_i
 *   6) write enable signal write_en_i
 *
 * Outputs:
 *   1) DWIDTH data output data_o
 */

module memory #(
  // parameters
  parameter int AWIDTH    = 32,
  parameter int DWIDTH    = 32,
  parameter logic [31:0] BASE_ADDR = 32'h0100_0000
)(
  // inputs
  input  logic                  clk,
  input  logic                  rst,
  input  logic [AWIDTH-1:0]     addr_i,
  input  logic [DWIDTH-1:0]     data_i,
  input  logic                  read_en_i,
  input  logic                  write_en_i,
  // outputs
  output logic [DWIDTH-1:0]     data_o
);

  // ---------------------------------------------------------------------------
  // Storage
  // ---------------------------------------------------------------------------
  // Loader staging (word array used only by $readmemh at time 0)
  logic [DWIDTH-1:0] temp_memory [0:`MEM_DEPTH];

  // The actual byte-addressable RAM used during simulation
  logic [7:0]        main_memory [0:`MEM_DEPTH];

  // Translate absolute address -> local byte index
  logic [AWIDTH-1:0] address;
  assign address = addr_i - BASE_ADDR;

  // ---------------------------------------------------------------------------
  // Initial load from hex file (word -> bytes, little-endian)
  // ---------------------------------------------------------------------------
  initial begin
    $readmemh(`MEM_PATH, temp_memory);

    // Unpack each 32-bit word into 4 bytes (little-endian)
    for (int i = 0; i < `LINE_COUNT; i++) begin
      main_memory[4*i + 0] = temp_memory[i][7:0];     // LSB at lowest address
      main_memory[4*i + 1] = temp_memory[i][15:8];
      main_memory[4*i + 2] = temp_memory[i][23:16];
      main_memory[4*i + 3] = temp_memory[i][31:24];   // MSB at highest address
    end

    $display("[MEMORY] Loaded %0d 32-bit words from %s", `LINE_COUNT, `MEM_PATH);
  end

  // ---------------------------------------------------------------------------
  // Combinational READ path (assemble 32-bit word, little-endian)
  // ---------------------------------------------------------------------------
  always_comb begin
    if (read_en_i) begin
      data_o = {
        main_memory[address + 32'd3],   // MSB
        main_memory[address + 32'd2],
        main_memory[address + 32'd1],
        main_memory[address + 32'd0]    // LSB
      };
    end else begin
      data_o = '0;
    end
  end

  // ---------------------------------------------------------------------------
  // Sequential WRITE path (byte-wide write on posedge)
  // PD1 tests write one byte per address; only data_i[7:0] is stored.
  // ---------------------------------------------------------------------------
  always_ff @(posedge clk) begin
    if (write_en_i) begin
      main_memory[address] <= data_i[7:0];
    end
  end

endmodule : memory
