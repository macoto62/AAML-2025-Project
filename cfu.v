module Cfu (
    input               cmd_valid,
    output              cmd_ready,
    input      [9:0]    cmd_payload_function_id,
    input      [31:0]   cmd_payload_inputs_0,
    input      [31:0]   cmd_payload_inputs_1,
    output reg          rsp_valid,
    input               rsp_ready,
    output reg [31:0]   rsp_payload_outputs_0,
    input               reset,
    input               clk
);

    // State Registers
    reg signed [31:0] InputOffset, FilterOffset;
    reg signed [31:0] accumulator; // Legacy accumulator

    // New Registers for 4-way SIMD
    reg signed [31:0] acc0, acc1, acc2, acc3;
    reg [31:0] global_input;

    // Memory Interface Wires
    // Legacy: inputs_0 is input, inputs_1 is filter
    // New: global_input is input, inputs_0 is filter
    
    wire [31:0] simd_input = (cmd_payload_function_id[9:3] == 7'd0) ? cmd_payload_inputs_0 : global_input;
    wire [31:0] simd_filter = (cmd_payload_function_id[9:3] == 7'd0) ? cmd_payload_inputs_1 : cmd_payload_inputs_0;

    // SIMD Multiplication (4 bytes)
    wire signed [31:0] prod_0, prod_1, prod_2, prod_3;
    
    assign prod_0 = ($signed(simd_input[7 : 0]) + InputOffset) * ($signed(simd_filter[7 : 0]) + FilterOffset);
    assign prod_1 = ($signed(simd_input[15: 8]) + InputOffset) * ($signed(simd_filter[15: 8]) + FilterOffset);
    assign prod_2 = ($signed(simd_input[23:16]) + InputOffset) * ($signed(simd_filter[23:16]) + FilterOffset);
    assign prod_3 = ($signed(simd_input[31:24]) + InputOffset) * ($signed(simd_filter[31:24]) + FilterOffset);

    wire signed [31:0] sum_prods;
    assign sum_prods = prod_0 + prod_1 + prod_2 + prod_3;

    assign cmd_ready = ~rsp_valid;

    always @(posedge clk) begin
        if (reset) begin
            rsp_payload_outputs_0 <= 32'b0;
            rsp_valid <= 1'b0;
            InputOffset <= 32'd0;
            FilterOffset <= 32'd0;
            accumulator <= 32'd0;
            acc0 <= 32'd0;
            acc1 <= 32'd0;
            acc2 <= 32'd0;
            acc3 <= 32'd0;
            global_input <= 32'd0;
        end else if (rsp_valid) begin
            if (rsp_ready) rsp_valid <= 1'b0;
        end else if (cmd_valid) begin
            rsp_valid <= 1'b1;
            
            case (cmd_payload_function_id[9:3])
                
                // ID 0: ACCUMULATE VIA POINTERS (Legacy)
                7'd0: begin
                    accumulator <= accumulator + sum_prods;
                    rsp_payload_outputs_0 <= accumulator;
                end

                // ID 1: RESET ACCUMULATOR (Legacy)
                7'd1: begin
                    accumulator <= 32'd0;
                    rsp_payload_outputs_0 <= 32'd0;
                end

                // ID 2: SET INPUT OFFSET
                7'd2: begin
                    InputOffset <= $signed(cmd_payload_inputs_0);
                    rsp_payload_outputs_0 <= $signed(cmd_payload_inputs_0);
                end

                // ID 3: SET FILTER OFFSET
                7'd3: begin
                    FilterOffset <= $signed(cmd_payload_inputs_0);
                    rsp_payload_outputs_0 <= $signed(cmd_payload_inputs_0);
                end

                // ID 4: GET RESULT (Legacy)
                7'd4: begin
                    rsp_payload_outputs_0 <= accumulator;
                end

                // --- NEW OPCODES ---

                // ID 5: SET GLOBAL INPUT
                7'd5: begin
                    global_input <= cmd_payload_inputs_0;
                end

                // ID 6: MACC ACC0
                7'd6: begin
                    acc0 <= acc0 + sum_prods;
                end

                // ID 7: MACC ACC1
                7'd7: begin
                    acc1 <= acc1 + sum_prods;
                end

                // ID 8: MACC ACC2
                7'd8: begin
                    acc2 <= acc2 + sum_prods;
                end

                // ID 9: MACC ACC3
                7'd9: begin
                    acc3 <= acc3 + sum_prods;
                end

                // ID 10: RESET ALL ACC
                7'd10: begin
                    acc0 <= 32'd0;
                    acc1 <= 32'd0;
                    acc2 <= 32'd0;
                    acc3 <= 32'd0;
                end

                // ID 11: GET ACC0
                7'd11: rsp_payload_outputs_0 <= acc0;

                // ID 12: GET ACC1
                7'd12: rsp_payload_outputs_0 <= acc1;

                // ID 13: GET ACC2
                7'd13: rsp_payload_outputs_0 <= acc2;

                // ID 14: GET ACC3
                7'd14: rsp_payload_outputs_0 <= acc3;

                default: rsp_payload_outputs_0 <= 32'b0;
            endcase
        end
    end
endmodule
