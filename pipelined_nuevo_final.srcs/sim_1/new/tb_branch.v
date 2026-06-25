`timescale 1ns / 1ps

module tb_branch;

  reg clk, reset;

  wire [31:0] WriteData, DataAdr;
  wire MemWrite;

  wire [31:0] InstrF, InstrD, InstrE, InstrM, InstrW;

  top #(.MEM_FILE("test_branch.mem")) dut(
    .clk(clk),
    .reset(reset),

    .WriteData(WriteData),
    .DataAdr(DataAdr),
    .MemWrite(MemWrite),

    .InstrF(InstrF),
    .InstrD(InstrD),
    .InstrE(InstrE),
    .InstrM(InstrM),
    .InstrW(InstrW)
  );

  initial clk = 1;
  always #5 clk = ~clk;

  initial begin
    reset = 1;
    #22;
    reset = 0;
  end

  wire PCSrcE = dut.rvpipelined.hu.PCSrcE;
  wire FlushD = dut.rvpipelined.hu.FlushD;
  wire FlushE = dut.rvpipelined.hu.FlushE;

  always @(negedge clk) begin
    if(!reset) begin

      $display(
        "[PIPE] t=%0t | F=%h | D=%h | E=%h | M=%h | W=%h",
        $time,
        InstrF, InstrD, InstrE, InstrM, InstrW
      );

      if(PCSrcE)
        $display(
          "[BRANCH] t=%0t FlushD=%b FlushE=%b",
          $time,
          FlushD,
          FlushE
        );
    end
  end

  always @(negedge clk) begin
    if(MemWrite) begin

      if(DataAdr == 32'd100 &&
         WriteData == 32'd25) begin

        $display(
          "[PASS] tb_branch: BEQ y BNE funcionando"
        );

        $finish;

      end else begin

        $display(
          "[FAIL] tb_branch addr=%0d data=%0d",
          DataAdr,
          WriteData
        );

        $finish;
      end
    end
  end

  initial begin
    #800;
    $display("[FAIL] tb_branch timeout");
    $finish;
  end

endmodule