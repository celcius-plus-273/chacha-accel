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

    reg [31:0] input_a [0:3], input_b [0:3], input_c [0:3], input_d [0:3];

    wire [127:0] flatten_in_a, flatten_in_b, flatten_in_c, flatten_in_d;
    assign flatten_in_a = {input_a[3], input_a[2], input_a[1], input_a[0]};
    assign flatten_in_b = {input_b[3], input_b[2], input_b[1], input_b[0]};
    assign flatten_in_c = {input_c[3], input_c[2], input_c[1], input_c[0]};
    assign flatten_in_d = {input_d[3], input_d[2], input_d[1], input_d[0]};

    wire [127:0] flatten_out_a, flatten_out_b, flatten_out_c, flatten_out_d;
    wire [31:0] output_a [0:3], output_b [0:3], output_c [0:3], output_d [0:3];

    assign output_a[0] = flatten_out_a[31:0];
    assign output_a[1] = flatten_out_a[63:32];
    assign output_a[2] = flatten_out_a[95:64];
    assign output_a[3] = flatten_out_a[127:96];

    assign output_b[0] = flatten_out_b[31:0];
    assign output_b[1] = flatten_out_b[63:32];
    assign output_b[2] = flatten_out_b[95:64];
    assign output_b[3] = flatten_out_b[127:96];

    assign output_c[0] = flatten_out_c[31:0];
    assign output_c[1] = flatten_out_c[63:32];
    assign output_c[2] = flatten_out_c[95:64];
    assign output_c[3] = flatten_out_c[127:96];

    assign output_d[0] = flatten_out_d[31:0];
    assign output_d[1] = flatten_out_d[63:32];
    assign output_d[2] = flatten_out_d[95:64];
    assign output_d[3] = flatten_out_d[127:96];

    round chacha_round (
        .input_col_a(flatten_in_a),
        .input_col_b(flatten_in_b),
        .input_col_c(flatten_in_c),
        .input_col_d(flatten_in_d),
        .output_col_a(flatten_out_a),
        .output_col_b(flatten_out_b),
        .output_col_c(flatten_out_c),
        .output_col_d(flatten_out_d)
    );

    integer i = 0;

    initial begin
        $dumpfile(VCD_PATH); 
        $dumpvars(0, tb);

        for (i = 0; i < 4; i = i + 1) begin
            input_a[i] = 32'h0012DFFA;
            input_b[i] = 32'hAAFB4CD5;
            input_c[i] = 32'h18769012;
            input_d[i] = 32'hAFF22300;
        end

        #10 $display("simulating... :)");

        #10 $display("round function output");
        // check if output gets propagated
        for (i = 0; i < 4; i = i + 1) begin
            $display("Round: %0d", i);
            $display("A_out: %0x", output_a[i]);
            $display("B_out: %0x", output_b[i]);
            $display("C_out: %0x", output_c[i]);
            $display("D_out: %0x", output_d[i]);
        end

        #10 $finish; // exit simulation

    end

endmodule