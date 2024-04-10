module tb;

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

    // keep track of the cycle count (for debugging :))
    integer cycles = 0;    
    always begin
        #(CLOCK_PERIOD) cycles = cycles + 1;
        $display("Cycle count: %0d", cycles);
    end

    reg [4:0] counter = 0;
    reg state = 0;

    initial begin
        counter <= 0;
        state <= 0;
        clock <= 0;

        #100 $finish;
    end

    always @ (posedge clock) begin
        if (!state) begin
            $display("counter: %0d -> %0d", counter, counter + 1);
            counter <= counter + 1;

            if (counter == 5)
                $display("I also reached 5!");
        end

        if (counter == 5) begin
            $display("counter reach 5!");
            state <= 1; 
            counter <= 0;
        end
    end

endmodule