`include "src/round.sv"
`default_nettype none
`timescale 1ns/1ns

module tb;
    // Waveform output file path
    localparam VCD_PATH = "test/round/round_test.vcd";

    // CLOCK STUFF
    localparam CLOCK_PERIOD = 10;
    reg clock = 0;
    always begin
        if (clock)
            $display("Falling Edge: %0b -> %0b", clock, ~clock);
        else
            $display("Rising Edge: %0b -> %0b", clock, ~clock);

        //$monitor("clock changed: %0b", clock);
        #(CLOCK_PERIOD/2) clock = ~clock;
    end

    reg [31:0] input_a, input_b, input_c, input_d = 0;
    wire [31:0] output_a, output_b, output_c, output_d;

    quarter_round chacha_round (
        .input_a(input_a),
        .input_b(input_b),
        .input_c(input_c),
        .input_d(input_d),
        .output_a(output_a),
        .output_b(output_b),
        .output_c(output_c),
        .output_d(output_d)
    );

    initial begin
        $dumpfile(VCD_PATH); 
        $dumpvars(0, tb);

        // assign 0 input
        input_a <= 32'h0012DFFA;
        input_b <= 32'hAAFB4CD5;
        input_c <= 32'h18769012;
        input_d <= 32'hAFF22300;

        #10 $display("initializing...");

        // check if output gets propagated
        $display("A_out: %x", output_a);
        $display("B_out: %x", output_b);
        $display("C_out: %x", output_c);
        $display("D_out: %x", output_d);

        #10 $finish; // exit simulation

    end

endmodule