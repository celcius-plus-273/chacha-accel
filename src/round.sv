/** 
 *  ChaCha-20 Round Function Implementation
 */
module round (
    // input ports
    input wire [31:0]   input_a, 
                        input_b, 
                        input_c, 
                        input_d,

    // output ports
    output wire [31:0]  output_a, 
                        output_b, 
                        output_c, 
                        output_d
);

    // ChaCha round function is expressed as a flowchart of ARX operations

    // Based on the sequential nature of the operation flow, it seems
    // like we will need intermediate vectors

    // There is a consistent pattern:
    //      add -> xor -> rotate
    
    /**
     *  ------------------------------
     *  --- COMBINATIONAL APPROACH ---
     *  ------------------------------
     */

    // generate intermediates
    wire [31:0] inter_a, mixed_inter_b, inter_c, mixed_inter_d, rotated_inter_b, rotated_inter_d,
                mixed_output_b, mixed_output_d;

    assign inter_a = input_a + input_b;
    assign mixed_inter_d = (input_a + input_b) ^ input_d;
    assign rotated_inter_d = {mixed_inter_d[15:0], mixed_inter_d[31:16]};

    assign inter_c = input_c + rotated_inter_d;
    assign mixed_inter_b = (input_c + rotated_inter_d) ^ input_b;
    assign rotated_inter_b = {mixed_inter_b[19:0], mixed_inter_b[31:20]};

    // generate outputs
    assign output_a = inter_a + rotated_inter_b;
    assign mixed_output_d = (inter_a + rotated_inter_b) ^ rotated_inter_d;
    assign output_d = {mixed_output_d[23:0], mixed_output_d[31:24]};

    assign output_c = inter_c + output_d;
    assign mixed_output_b = (inter_c + output_d) ^ rotated_inter_b;
    assign output_b = {mixed_output_b[24:0], mixed_output_b[31:25]};
    
endmodule