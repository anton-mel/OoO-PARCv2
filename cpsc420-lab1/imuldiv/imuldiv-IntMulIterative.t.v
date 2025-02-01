//========================================================================
// Test for Muldiv Unit
//========================================================================

`include "imuldiv-MulDivReqMsg.v"
`include "imuldiv-IntMulIterative.v"
`include "vc-TestSource.v"
`include "vc-TestSink.v"
`include "vc-Test.v"

//------------------------------------------------------------------------
// Helper Module
//------------------------------------------------------------------------

module imuldiv_IntMulIterative_helper
(
  input       clk,
  input       reset,
  output      done
);

  wire [66:0] src_msg;
  wire [31:0] src_msg_a;
  wire [31:0] src_msg_b;
  wire        src_val;
  wire        src_rdy;
  wire        src_done;

  wire [63:0] sink_msg;
  wire        sink_val;
  wire        sink_rdy;
  wire        sink_done;

  assign done = src_done && sink_done;

  vc_TestSource#(67,3) src
  (
    .clk   (clk),
    .reset (reset),
    .bits  (src_msg),
    .val   (src_val),
    .rdy   (src_rdy),
    .done  (src_done)
  );

  imuldiv_MulDivReqMsgFromBits msgfrombits
  (
    .bits (src_msg),
    .func (),
    .a    (src_msg_a),
    .b    (src_msg_b)
  );

  imuldiv_IntMulIterative imul
  (
    .clk                (clk),
    .reset              (reset),
    .mulreq_msg_a       (src_msg_a),
    .mulreq_msg_b       (src_msg_b),
    .mulreq_val         (src_val),
    .mulreq_rdy         (src_rdy),
    .mulresp_msg_result (sink_msg),
    .mulresp_val        (sink_val),
    .mulresp_rdy        (sink_rdy)
  );

  vc_TestSink#(64,3) sink
  (
    .clk   (clk),
    .reset (reset),
    .bits  (sink_msg),
    .val   (sink_val),
    .rdy   (sink_rdy),
    .done  (sink_done)
  );

endmodule

//------------------------------------------------------------------------
// Main Tester Module
//------------------------------------------------------------------------

module tester;

  // VCD Dump
  initial begin
    $dumpfile("imuldiv-IntMulIterative.vcd");
    $dumpvars;
  end

  `VC_TEST_SUITE_BEGIN( "imuldiv-IntMulIterative" )

  reg  t0_reset = 1'b1;
  wire t0_done;

  imuldiv_IntMulIterative_helper t0
  (
    .clk   (clk),
    .reset (t0_reset),
    .done  (t0_done)
  );

  `VC_TEST_CASE_BEGIN( 1, "mul" )
  begin

    t0.src.m[0] = 67'h0_00000000_00000000; t0.sink.m[0] = 64'h00000000_00000000;
    t0.src.m[1] = 67'h0_00000001_00000001; t0.sink.m[1] = 64'h00000000_00000001;
    t0.src.m[2] = 67'h0_ffffffff_00000001; t0.sink.m[2] = 64'hffffffff_ffffffff;
    t0.src.m[3] = 67'h0_00000001_ffffffff; t0.sink.m[3] = 64'hffffffff_ffffffff;
    t0.src.m[4] = 67'h0_ffffffff_ffffffff; t0.sink.m[4] = 64'h00000000_00000001;
    t0.src.m[5] = 67'h0_00000008_00000003; t0.sink.m[5] = 64'h00000000_00000018;
    t0.src.m[6] = 67'h0_fffffff8_00000008; t0.sink.m[6] = 64'hffffffff_ffffffc0;
    t0.src.m[7] = 67'h0_fffffff8_fffffff8; t0.sink.m[7] = 64'h00000000_00000040;
    t0.src.m[8] = 67'h0_0deadbee_10000000; t0.sink.m[8] = 64'h00deadbe_e0000000;
    t0.src.m[9] = 67'h0_deadbeef_10000000; t0.sink.m[9] = 64'hfdeadbee_f0000000;

    #5;   t0_reset = 1'b1;
    #20;  t0_reset = 1'b0;
    #10000; `VC_TEST_CHECK( "Is sink finished?", t0_done )

  end
  `VC_TEST_CASE_END

  //----------------------------------------------------------------------
  // Add Unsigned Test Case Here
  //----------------------------------------------------------------------
  
  `VC_TEST_CASE_BEGIN( 2, "mul (my private cases)" )
  begin

    // Large number multiplications
    t0.src.m[0] = 67'h0_7fffffff_7fffffff; t0.sink.m[0] = 64'h3fffffff_00000001;
    t0.src.m[1] = 67'h0_80000000_80000000; t0.sink.m[1] = 64'h40000000_00000000;
    t0.src.m[2] = 67'h0_00001000_00100000; t0.sink.m[2] = 64'h00000001_00000000;

    // Multiplication by power of two
    t0.src.m[3] = 67'h0_00000001_00000010; t0.sink.m[3] = 64'h00000000_00000010;
    t0.src.m[4] = 67'h0_00000002_00000020; t0.sink.m[4] = 64'h00000000_00000040;
    t0.src.m[5] = 67'h0_fffffffe_00000004; t0.sink.m[5] = 64'hffffffff_fffffff8;

    // Edge cases with small and large values
    t0.src.m[6] = 67'h0_00000001_ffffffff; t0.sink.m[6] = 64'hffffffff_ffffffff;
    t0.src.m[7] = 67'h0_00010000_00010000; t0.sink.m[7] = 64'h00000001_00000000;

    // Extreme case: Largest signed 32-bit * Smallest signed 32-bit
    t0.src.m[8] = 67'h0_7fffffff_80000000; t0.sink.m[8] = 64'hc0000000_80000000;
    t0.src.m[9] = 67'h0_6ff147af_11abcdef; t0.sink.m[9] = 64'h07ba25fa_398e0f61;

    #5;   t0_reset = 1'b1;
    #20;  t0_reset = 1'b0;
    #10000; `VC_TEST_CHECK( "Is sink finished?", t0_done )

  end
  `VC_TEST_CASE_END

  //----------------------------------------------------------------------
  // Test Case 3: "mul: Special Cases"
  //----------------------------------------------------------------------
  `VC_TEST_CASE_BEGIN( 3, "mul: Special Cases" )
  begin
    // T1: Square of 0x12345678
    // 0x12345678 * 0x12345678 = 0x014B66DC5B7E3B40 (precomputed)
    t0.src.m[0] = 67'h0_12345678_12345678;
    t0.sink.m[0] = 64'h014b66dc_1df4d840;

    // T2: Multiply smallest negative by -1:
    // 0x80000000 represents -2147483648 and 0xFFFFFFFF represents -1.
    // Their product should be 2147483648 = 0x0000000080000000.
    t0.src.m[1] = 67'h0_80000000_FFFFFFFF;
    t0.sink.m[1] = 64'h00000000_80000000;

    // T3: Multiply 0x40000000 by 0x40000000.
    // Since 0x40000000 = 2^30, (2^30)*(2^30) = 2^60 = 0x1000000000000000.
    t0.src.m[2] = 67'h0_40000000_40000000;
    t0.sink.m[2] = 64'h1000000000000000;

    #5;   t0_reset = 1'b1;
    #20;  t0_reset = 1'b0;
    #10000; `VC_TEST_CHECK( "mul: Special Cases finished", t0_done );
  end
  `VC_TEST_CASE_END

  `VC_TEST_SUITE_END( 3 )

endmodule
