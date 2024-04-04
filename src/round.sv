/** 
 *  ChaCha-20 Round Function Implementation
 */

// ARX Operation Module
module arx 
#(
    parameter R = 0 // rotation parameter
)
(
    // Each ARX unit consists of 3 input sources
    input wire [31:0] source_X,
    input wire [31:0] source_Y,
    input wire [31:0] source_Z,

    output wire [31:0] result_A,
    output wire [31:0] result_B
);

    // we need one intermediate wire to keep track of the xor + add operation
    wire [31:0] intermediate;

    // the ARX operation for ChaCha round operation is as follows:
    //      A = ((X + Y) ^ Z) < R
    //
    // note: the '<' operator refers to a rotation instruction
    assign intermediate = (source_X + source_Y) ^ source_Z;             // add + xor
    assign result_A = (intermediate << R) | (intermediate >> (32 - R)); // rotation
    assign result_B = source_X + source_Y;                              // add

endmodule

// Quarter Round Operation
module quarter_round (
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
    // ChaCha quarter_round function is expressed as a flowchart of ARX operations

    // Based on the sequential nature of the operation flow, it seems
    // like we will need intermediate vectors

    // There is a consistent pattern:
    //      add -> xor -> rotate
    
    /**
     *  ------------------------------
     *  --- COMBINATIONAL APPROACH ---
     *  ------------------------------
     *
     *  This approach follows the ChaCha operation flowchart directly
     */

    // /**
    //  *  Define intermediate wires
    //  *  
    //  *  Some notes:
    //  *   - mixed = add + xor
    //  *   - rotated = add + xor + rotate
    //  */
    // wire [31:0] inter_a, mixed_inter_b, inter_c, mixed_inter_d, rotated_inter_b, rotated_inter_d,
    //             mixed_output_b, mixed_output_d;
    wire [31:0] inter_a, inter_b, inter_c, inter_d;

    // // First ARX (intermediate)
    // assign inter_a = input_a + input_b;                                     // add
    // assign mixed_inter_d = (input_a + input_b) ^ input_d;                   // add + xor
    // assign rotated_inter_d = {mixed_inter_d[15:0], mixed_inter_d[31:16]};   // rotate
    arx #(.R(16)) arx_module_0 (
        .source_X(input_a),
        .source_Y(input_b),
        .source_Z(input_d),

        .result_A(inter_d),
        .result_B(inter_a)
    );

    // // Second ARX (intermediate)
    // assign inter_c = input_c + rotated_inter_d;                             // add
    // assign mixed_inter_b = (input_c + rotated_inter_d) ^ input_b;           // add + xor
    // assign rotated_inter_b = {mixed_inter_b[19:0], mixed_inter_b[31:20]};   // rotate
    arx #(.R(12)) arx_module_1 (
        .source_X(input_c),
        .source_Y(inter_d),
        .source_Z(input_b),

        .result_A(inter_b),
        .result_B(inter_c)
    );

    // // Third ARX (output)
    // assign output_a = inter_a + rotated_inter_b;                            // add
    // assign mixed_output_d = (inter_a + rotated_inter_b) ^ rotated_inter_d;  // add + xor
    // assign output_d = {mixed_output_d[23:0], mixed_output_d[31:24]};        // rotate
    arx #(.R(8)) arx_module_2 (
        .source_X(inter_a),
        .source_Y(inter_b),
        .source_Z(inter_d),

        .result_A(output_d),
        .result_B(output_a)
    );

    // // Fourth ARX (output)
    // assign output_c = inter_c + output_d;                                   // add
    // assign mixed_output_b = (inter_c + output_d) ^ rotated_inter_b;         // add + xor
    // assign output_b = {mixed_output_b[24:0], mixed_output_b[31:25]};        // rotate
    arx #(.R(7)) arx_module_3 (
        .source_X(inter_c),
        .source_Y(output_d),
        .source_Z(inter_b),

        .result_A(output_b),
        .result_B(output_c)
    );
endmodule

// Full ChaCha-20 Round (4 quarter rounds)
module round (
    // input is a ksg 4x4 array
    input wire [127:0]  input_col_a, 
    input wire [127:0]  input_col_b, 
    input wire [127:0]  input_col_c, 
    input wire [127:0]  input_col_d,

    // output ports
    output wire [127:0]  output_col_a, 
    output wire [127:0]  output_col_b, 
    output wire [127:0]  output_col_c, 
    output wire [127:0]  output_col_d
);
    /**
    *   A full round simply consists of performing 4 quarter round operations
    *   across all 4 columns of the 4x4 matrix
    *   
    *   For this implementation we will generate enough modules to comptue all
    *   4 quarter round operations in parallel
    */
    quarter_round quarter_module_0 (
        .input_a(input_col_a[31:0]),
        .input_b(input_col_b[31:0]),
        .input_c(input_col_c[31:0]),
        .input_d(input_col_d[31:0]),

        .output_a(output_col_a[31:0]),
        .output_b(output_col_b[31:0]),
        .output_c(output_col_c[31:0]),
        .output_d(output_col_d[31:0])
    );

    quarter_round quarter_module_1 (
        .input_a(input_col_a[63:32]),
        .input_b(input_col_b[63:32]),
        .input_c(input_col_c[63:32]),
        .input_d(input_col_d[63:32]),

        .output_a(output_col_a[63:32]),
        .output_b(output_col_b[63:32]),
        .output_c(output_col_c[63:32]),
        .output_d(output_col_d[63:32])
    );

    quarter_round quarter_module_2 (
        .input_a(input_col_a[95:64]),
        .input_b(input_col_b[95:64]),
        .input_c(input_col_c[95:64]),
        .input_d(input_col_d[95:64]),

        .output_a(output_col_a[95:64]),
        .output_b(output_col_b[95:64]),
        .output_c(output_col_c[95:64]),
        .output_d(output_col_d[95:64])
    );

    quarter_round quarter_module_3 (
        .input_a(input_col_a[127:96]),
        .input_b(input_col_b[127:96]),
        .input_c(input_col_c[127:96]),
        .input_d(input_col_d[127:96]),

        .output_a(output_col_a[127:96]),
        .output_b(output_col_b[127:96]),
        .output_c(output_col_c[127:96]),
        .output_d(output_col_d[127:96])
    );

endmodule