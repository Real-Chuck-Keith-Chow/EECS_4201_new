`include "probes.svh"

// Wrapper for our design defined in code/
// This is what the testbench connects to.
module design_wrapper (
    input  logic clk,
    input  logic reset,

    // Expose memory interface to testbench
    output logic [`DWIDTH-1:0] mem_addr,
    output logic [`DWIDTH-1:0] mem_data_out,
    input  logic [`DWIDTH-1:0] mem_data_in,
    output logic               mem_read_en,
    output logic               mem_write_en
);

    // Instantiate top-level design (pd1.sv)
    `TOP_MODULE core (
        .clk        (clk),
        .rst        (reset),

        .mem_addr   (mem_addr),
        .mem_data_in(mem_data_in),
        .mem_data_out(mem_data_out),
        .mem_read_en(mem_read_en),
        .mem_write_en(mem_write_en)
    );

endmodule
