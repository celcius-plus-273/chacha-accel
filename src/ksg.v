`include "src/round.v"

module ksg 
#(
    parameter NUM_ROUNDS    =   20,     // number of rounds in the KSG
    parameter WORD_SIZE     =   32      // word size in bits
)
(
    // serial input for data during initial state
    input wire [WORD_SIZE - 1 : 0]      data_in,
    // ready-valid hanshake for input data
    input wire valid_in,
    output wire ready_in,

    // output data port
    output wire [511:0] output_key, 
    // ready-valid hanshake for output data
    output reg valid_out,           // output data is ready to be sent
    input wire ready_out,           // receiver is ready to receive data

    input wire done_out,            // asserted by serializer when data
                                    // has been completely serialized

    // control signals
    input wire reset_n,     // active low reset signal
    input wire clock       // clock signal
);
    /**
     *  Key Stream Generator
     *  
     *  1) Read the input as a stream of 32 bits
     *  2) Perform 20 rounds
     *  3) Return the scrambled output
     */
    
    // local parameters / constants
    localparam KSG_CONSTANT = "expand 32-byte k";
    integer i;

    // internal states
    localparam IDLE = 0;
    localparam BUSY = 1;

    // internal counter for round and state tracking
    reg [4:0] init_counter = 0;  // initialze to 0
    reg [4:0] round_counter = 0;    // intialize to 0
    reg ksg_state = IDLE;   // initialize to IDLE

    // buffer (memory) block
    reg [WORD_SIZE - 1 : 0] ksg_buffer      [0 : (512 / WORD_SIZE) - 1];    // INITIAL MEMORY ARRAY
    reg [WORD_SIZE - 1 : 0] round_buffer    [0 : (512 / WORD_SIZE) - 1];    // COMPUTATION MEMORY ARRAY
    
    // buffer latch control signal
    wire round_buffer_we;

    // wire connection between round buffer input and round function output
    wire [127:0] buffer_in_a, buffer_in_b, buffer_in_c, buffer_in_d;

    // wire connection between round buffer output and round function input
    wire [127:0] buffer_out_a, buffer_out_b, buffer_out_c, buffer_out_d;

    // POSEDGE
    always @ (posedge clock) begin
        case (ksg_state)
            /**
            *   IDLE STAGE
            *   - read the stream of 32 bit block data
            *   - store it into the initial and computation memory arrays 
            *   - updates the init_counter
            *   - changes into BUSY stage once counter hits 12
            *   
            *   Notes:
            *   - valid_in should be appropriately de-asserted from the controller's side once
            *     all the data has been sent
            */
            IDLE: begin
                // read 32-bit stream
                if (valid_in && ready_in) begin
                    // latch data from input port
                    ksg_buffer[init_counter + 4] <= data_in;
                    round_buffer[init_counter + 4] <= data_in;

                    // update counter
                    init_counter <= init_counter + 1;

                    // de-assert valid_out?
                    valid_out <= 0;
                end 

                // hardwire constant during initial stage
                ksg_buffer[3] <= KSG_CONSTANT[31:0];
                ksg_buffer[2] <= KSG_CONSTANT[63:32];
                ksg_buffer[1] <= KSG_CONSTANT[95:64];
                ksg_buffer[0] <= KSG_CONSTANT[127:96];
        
                round_buffer[3] <= KSG_CONSTANT[31:0];
                round_buffer[2] <= KSG_CONSTANT[63:32];
                round_buffer[1] <= KSG_CONSTANT[95:64];
                round_buffer[0] <= KSG_CONSTANT[127:96];
            end

            /**
            *   BUSY STAGE (COMPUTATION STAGE)
            *   - 
            */
            BUSY: begin
                if (round_buffer_we) begin
                    // Now we simply latch the output data coming out of the round function
                    round_buffer[0] <= buffer_in_a[31:0];
                    round_buffer[1] <= buffer_in_a[63:32];
                    round_buffer[2] <= buffer_in_a[95:64];
                    round_buffer[3] <= buffer_in_a[127:96];

                    round_buffer[4] <= buffer_in_b[31:0];
                    round_buffer[5] <= buffer_in_b[63:32];
                    round_buffer[6] <= buffer_in_b[95:64];
                    round_buffer[7] <= buffer_in_b[127:96];

                    round_buffer[8]  <= buffer_in_c[31:0];
                    round_buffer[9]  <= buffer_in_c[63:32];
                    round_buffer[10] <= buffer_in_c[95:64];
                    round_buffer[11] <= buffer_in_c[127:96];

                    round_buffer[12] <= buffer_in_d[31:0];
                    round_buffer[13] <= buffer_in_d[63:32];
                    round_buffer[14] <= buffer_in_d[95:64];
                    round_buffer[15] <= buffer_in_d[127:96];

                    // increment round counter
                    round_counter <= round_counter + 1;
                end
            end

            default: begin
                // nothing
                $display("[ERROR] Invalid KSG state");
            end 
        endcase
    end

    // NEGEDGE
    always @ (negedge clock) begin
        case (ksg_state)
            /**
            *   IDLE STAGE
            *   - read the stream of 32 bit block data
            *   - store it into the initial and computation memory arrays 
            *   - updates the init_counter
            *   - changes into BUSY stage once counter hits 12
            *   
            *   Notes:
            *   - valid_in should be appropriately de-asserted from the controller's side once
            *     all the data has been sent
            */
            IDLE: begin
                // change state when counter reaches 12 :)
                if (init_counter == 12) begin
                    // change into BUSY state
                    ksg_state <= BUSY;

                    // reset init_counter
                    init_counter <= 0;
                end
            end

            /**
            *   BUSY STAGE (COMPUTATION STAGE)
            *   - 
            */
            BUSY: begin
                if (round_counter == NUM_ROUNDS) begin
                    // go back to IDLE stage
                    ksg_state <= IDLE;

                    // assert valid out to indicate that data is ready to be
                    // serialized
                    valid_out <= 1;
                end
            end

            default: 
                // nothing
                $display("[ERROR] Invalid KSG state");
        endcase
    end

    // synchronous reset
    always @ (negedge reset_n) begin
        // debug print
        $display("[INFO] Resetting KSG module...");

        // Hardwire the constant on reset
        ksg_buffer[3] <= KSG_CONSTANT[31:0];
        ksg_buffer[2] <= KSG_CONSTANT[63:32];
        ksg_buffer[1] <= KSG_CONSTANT[95:64];
        ksg_buffer[0] <= KSG_CONSTANT[127:96];
        
        round_buffer[3] <= KSG_CONSTANT[31:0];
        round_buffer[2] <= KSG_CONSTANT[63:32];
        round_buffer[1] <= KSG_CONSTANT[95:64];
        round_buffer[0] <= KSG_CONSTANT[127:96];

        // clear memory on reset
        for (i = 4; i < (512 / WORD_SIZE); i = i + 1) begin
            ksg_buffer[i] <= 0;
            round_buffer[i] <= 0;
        end

        // default state is IDLE
        ksg_state <= IDLE;  
        // reset the counter
        init_counter <= 0;
        round_counter <= 0;
    end

    // round module
    round chacha_round (
        .input_a(buffer_out_a),
        .input_b(buffer_out_b),
        .input_c(buffer_out_c),
        .input_d(buffer_out_d),

        .output_a(buffer_in_a),
        .output_b(buffer_in_b),
        .output_c(buffer_in_c),
        .output_d(buffer_in_d),

        .op_type(op_type)
    );

    // round function input assignment
    assign buffer_out_a = {round_buffer[3], round_buffer[2], round_buffer[1], round_buffer[0]};
    assign buffer_out_b = {round_buffer[7], round_buffer[6], round_buffer[5], round_buffer[4]};
    assign buffer_out_c = {round_buffer[11], round_buffer[10], round_buffer[9], round_buffer[8]};
    assign buffer_out_d = {round_buffer[15], round_buffer[14], round_buffer[13], round_buffer[12]};

    // ready_in output is asserted when counter is not 16
    assign ready_in = !ksg_state;

    // op_type is just assgined to be 0th bit of round_counter
    wire op_type;
    assign op_type = round_counter[0];

    // only allow latching from round function output if in BUSY state
    assign round_buffer_we = ksg_state;

    /**
    *   OUTPUT KEY ASSIGNMENT
    */
    // ROW A
    assign output_key[127:0] = {
        (ksg_buffer[3] + round_buffer[3]),
        (ksg_buffer[2] + round_buffer[2]),
        (ksg_buffer[1] + round_buffer[1]),
        (ksg_buffer[0] + round_buffer[0])
    };

    // ROW B
    assign output_key[255:128] = {
        (ksg_buffer[7] + round_buffer[7]),
        (ksg_buffer[6] + round_buffer[6]),
        (ksg_buffer[5] + round_buffer[5]),
        (ksg_buffer[4] + round_buffer[4])
    };

    // ROW C
    assign output_key[383:256] = {
        (ksg_buffer[11] + round_buffer[11]),
        (ksg_buffer[10] + round_buffer[10]),
        (ksg_buffer[9] + round_buffer[9]),
        (ksg_buffer[8] + round_buffer[8])
    };

    // ROW D
    assign output_key[511:384] = {
        (ksg_buffer[15] + round_buffer[15]),
        (ksg_buffer[14] + round_buffer[14]),
        (ksg_buffer[13] + round_buffer[13]),
        (ksg_buffer[12] + round_buffer[12])
    };
endmodule