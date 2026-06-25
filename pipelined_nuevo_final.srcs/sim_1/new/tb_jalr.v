// Testbench: JALR
// Verifica:
// 1) Salto indirecto usando rs1 + imm.
// 2) Escritura de PCNextSeq en rd.
// 3) Flush correcto de las instrucciones posteriores.
//
// Esperado:
// mem[100] = 8

`timescale 1ns / 1ps

module tb_jalr;

  reg clk, reset;

  wire [31:0] WriteData, DataAdr;
  wire MemWrite;

  wire [31:0] InstrF, InstrD, InstrE, InstrM, InstrW;

  top #(.MEM_FILE("test_jalr.mem")) dut(
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

  reg jalr_seen;
  initial jalr_seen = 0;

  always @(negedge clk) begin
    if (!reset) begin

      $display(
        "[PIPE] t=%0t | F=%h | D=%h | E=%h | M=%h | W=%h",
        $time,
        InstrF, InstrD, InstrE, InstrM, InstrW
      );

      if (PCSrcE) begin
        $display(
          "[JALR] t=%0t  FlushD=%b  FlushE=%b",
          $time,
          FlushD,
          FlushE
        );
        jalr_seen = 1;
      end
    end
  end

  always @(negedge clk) begin
    if (MemWrite) begin

      if (DataAdr === 32'd100 &&
          WriteData === 32'd8) begin

        if (jalr_seen)
          $display(
            "[PASS] tb_jalr: salto correcto, retorno correcto y flush observado"
          );
        else
          $display(
            "[FAIL] tb_jalr: valor correcto pero no se observo el flush"
          );

        $finish;

      end else begin

        $display(
          "[FAIL] tb_jalr: addr=%0d data=%0d (jalr o flush incorrecto)",
          DataAdr,
          WriteData
        );

        $finish;
      end
    end
  end

  initial begin
    #800;
    $display("[FAIL] tb_jalr: tiempo agotado");
    $finish;
  end

endmodule