`include "src/round.sv"

module key_stream_generator (
    input wire [255:0] input_key, // is this a good idea? or should we split the key into multiple ports...?
    input wire [95:0] nonce,
    input wire [31:0] b_count,

    output reg [511:0] output_key, // ... I doubt this is a good idea
    output reg is_ready, 

    input wire clock
);

    /**
     *  Key Stream Generator
     *  
     *  1) Latch the given inputs
     *  2) Perform 20 rounds
     *  3) Return the scrambled output
     */



endmodule