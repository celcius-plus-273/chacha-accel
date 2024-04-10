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
    input wire [127:0]  input_a, 
    input wire [127:0]  input_b, 
    input wire [127:0]  input_c, 
    input wire [127:0]  input_d,

    // output ports
    output wire [127:0]  output_a, 
    output wire [127:0]  output_b, 
    output wire [127:0]  output_c, 
    output wire [127:0]  output_d,

    // control signal
    input wire op_type  // 0: column, 1: diagonal
);
    /**
    *   A full round simply consists of performing 4 quarter round operations
    *   across all 4 columns of the 4x4 matrix
    *   
    *   For this implementation we will generate enough modules to comptue all
    *   4 quarter round operations in parallel
    */
    quarter_round quarter_module_0 (
        .input_a(input_a_0),
        .input_b(input_b_0),
        .input_c(input_c_0),
        .input_d(input_d_0),

        .output_a(output_a_0),
        .output_b(output_b_0),
        .output_c(output_c_0),
        .output_d(output_d_0)
    );

    quarter_round quarter_module_1 (
        .input_a(input_a_1),
        .input_b(input_b_1),
        .input_c(input_c_1),
        .input_d(input_d_1),

        .output_a(output_a_1),
        .output_b(output_b_1),
        .output_c(output_c_1),
        .output_d(output_d_1)
    );

    quarter_round quarter_module_2 (
        .input_a(input_a_2),
        .input_b(input_b_2),
        .input_c(input_c_2),
        .input_d(input_d_2),

        .output_a(output_a_2),
        .output_b(output_b_2),
        .output_c(output_c_2),
        .output_d(output_d_2)
    );

    quarter_round quarter_module_3 (
        .input_a(input_a_3),
        .input_b(input_b_3),
        .input_c(input_c_3),
        .input_d(input_d_3),

        .output_a(output_a_3),
        .output_b(output_b_3),
        .output_c(output_c_3),
        .output_d(output_d_3)
    );

    // To implement diagonal mixing we will mux the input and output of the 
    // quarter round modules
    wire [31:0] input_a_0, input_a_1, input_a_2, input_a_3;
    wire [31:0] input_b_0, input_b_1, input_b_2, input_b_3;
    wire [31:0] input_c_0, input_c_1, input_c_2, input_c_3;
    wire [31:0] input_d_0, input_d_1, input_d_2, input_d_3;

    wire [31:0] output_a_0, output_a_1, output_a_2, output_a_3;
    wire [31:0] output_b_0, output_b_1, output_b_2, output_b_3;
    wire [31:0] output_c_0, output_c_1, output_c_2, output_c_3;
    wire [31:0] output_d_0, output_d_1, output_d_2, output_d_3;
    
    // MUX input values to enable selection between column-wise and diagonal-wise mixing
    assign input_a_0 = input_a[31:0];
    assign input_b_0 = op_type ? input_b[63:32]     : input_b[31:0];
    assign input_c_0 = op_type ? input_c[95:64]     : input_c[31:0];
    assign input_d_0 = op_type ? input_d[127:96]    : input_d[31:0];

    assign input_a_1 = input_a[63:32];
    assign input_b_1 = op_type ? input_b[95:64]     : input_b[63:32];
    assign input_c_1 = op_type ? input_c[127:96]    : input_c[63:32];
    assign input_d_1 = op_type ? input_d[31:0]      : input_d[63:32];

    assign input_a_2 = input_a[95:64];
    assign input_b_2 = op_type ? input_b[127:96]    : input_b[95:64];
    assign input_c_2 = op_type ? input_c[31:0]      : input_c[95:64];
    assign input_d_2 = op_type ? input_d[63:32]     : input_d[95:64];

    assign input_a_3 = input_a[127:96];
    assign input_b_3 = op_type ? input_b[31:0]      : input_b[127:96];
    assign input_c_3 = op_type ? input_c[63:32]     : input_c[127:96];
    assign input_d_3 = op_type ? input_d[95:64]     : input_d[127:96];

    // MUX output values following the same pattern as the input
    assign output_a[31:0]   = output_a_0;
    assign output_a[63:32]  = output_a_1;
    assign output_a[95:64]  = output_a_2;
    assign output_a[127:96] = output_a_3;

    assign output_b[31:0]   = op_type ? output_b_3 : output_b_0;
    assign output_b[63:32]  = op_type ? output_b_0 : output_b_1;
    assign output_b[95:64]  = op_type ? output_b_1 : output_b_2;
    assign output_b[127:96] = op_type ? output_b_2 : output_b_3;

    assign output_c[31:0]   = op_type ? output_c_2 : output_c_0;
    assign output_c[63:32]  = op_type ? output_c_3 : output_c_1;
    assign output_c[95:64]  = op_type ? output_c_0 : output_c_2;
    assign output_c[127:96] = op_type ? output_c_1 : output_c_3;

    assign output_d[31:0]   = op_type ? output_d_1 : output_d_0;
    assign output_d[63:32]  = op_type ? output_d_2 : output_d_1;
    assign output_d[95:64]  = op_type ? output_d_3 : output_d_2;
    assign output_d[127:96] = op_type ? output_d_0 : output_d_3;

endmodule