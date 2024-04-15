`include "src/ksg.v"
`default_nettype none
`timescale 1ns/1ns

module tb;
    // Waveform output file path
    localparam VCD_PATH = "test/ksg/ksg_test.vcd";

    // CLOCK STUFF
    localparam CLOCK_PERIOD = 10;
    reg clock = 0;
    always begin
        if (clock)
            $display("[CLOCK] Falling Edge: %0b -> %0b", clock, ~clock);
        else
            $display("[CLOCK] Rising Edge: %0b -> %0b", clock, ~clock);

        //$monitor("clock changed: %0b", clock);
        #(CLOCK_PERIOD/2) clock = ~clock;
    end    

    ///////////////////////////////////
    ///////// INPUT TEST DATA /////////
    ///////////////////////////////////

    // Secret Key
    reg [31:0] secret_key [0:7] = [
        32'h00000000,   // key_0
        32'h00000000,   // key_1
        32'h00000000,   // key_2
        32'h00000000,   // key_3
        32'h00000000,   // key_4
        32'h00000000,   // key_5    
        32'h00000000,   // key_6
        32'h00000000    // key_7
    ];

    // Block Counter
    reg [31:0] block_count = 32'h00000000;

    // nonce
    reg [31:0] nonce [0:2] = [
        32'h00000000,   // nonce_0
        32'h00000000,   // nonce_1
        32'h00000000    // nonce_2
    ];

    ///////////////////////////////////

    // init ksg module
    ksg ksg_module (
        .data_in(data_in),
        .valid_in(valid_in),
        .ready_in(ready_in),
        
        .output_key(output_key),
        .valid_out(valid_out),
        .ready_out(ready_out),
        .done_out(done_out), // potentially not necessary

        .reset_n(reset_n),
        .clock(clock)
    );

    // reset control signal
    reg reset_n = 1;

    // ksg input
    reg [31:0] data_in; // data bus port
    reg valid_in = 0;   // stream is ready to be sent
    wire ready_in;      // ksg is ready to receive

    // ksg output
    wire [511:0] output_key;  // ksg output
    wire valid_out;     // indicates when data has been succesfully computed
    reg done_out = 0;   // serializer has finished reading output key
    reg ready_out = 0;  // serializer is ready to receive data

    // array for data in!
    // contains the secret key, block counter, and nonce
    reg [31:0] data_mem [0:11];

    // data stream
    reg stream_counter = 0;
    always @ (posedge clock) begin
        // data should be ready to be received :)
        if (ready_in && valid_in) begin
            data_in <= data_mem[stream_counter];
            stream_counter <= stream_counter + 1;
        end
    end

    // integer dummy
    integer i = 0;
    initial begin
        // GTKWave files
        $dumpfile(VCD_PATH); 
        $dumpvars(0, tb);

        // populate data_mem with key_data, block_count, and nonce
        for (i = 0; i < 8; i = i + 1) begin
            data_mem[i] <= secret_key[i];
        end
        
        data_mem[8] <= block_count[i];

        for (i = 9; i < 12; i = i + 1) begin
            data_mem[i] <= nonce[i];
        end
        #10 $display("[INFO] Test data has been succesfully written");

        // TEST # 1: RESET KSG MODULE
        reset_n <= 0;
        #10;
        reset_n <= 1;

        // TEST # 2: ASSERT INPUT SIGNALS TO START KSG MODULE
        valid_in <= 1;        

        #100 $finish; // exit simulation

    end

endmodule