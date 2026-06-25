// Testbench: Shift Instructions
// Verifica:
//   sll, slli
//   srl, srli
//   sra, srai
//
// Esperado:
//   mem[100] = 0xFFFFFFFC (-4)

`timescale 1ns / 1ps

module tb_shift;

  reg         clk, reset;
  wire [31:0] WriteData, DataAdr;
  wire        MemWrite;

  wire [31:0] InstrF, InstrD, InstrE, InstrM, InstrW;

  top #(.MEM_FILE("test_shift.mem")) dut(
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

  always @(negedge clk) begin
    if (!reset) begin
      $display(
        "[PIPE] t=%0t | F=%h | D=%h | E=%h | M=%h | W=%h",
        $time,
        InstrF,
        InstrD,
        InstrE,
        InstrM,
        InstrW
      );
    end
  end

  always @(negedge clk) begin
    if (MemWrite) begin

      if (DataAdr === 32'd100 &&
          WriteData === 32'hFFFFFFFC) begin

        $display(
          "[PASS] tb_shift: mem[100]=%h (-4)",
          WriteData
        );

        $finish;

      end else begin

        $display(
          "[FAIL] tb_shift: addr=%0d data=%h (esperado FFFFFFFC)",
          DataAdr,
          WriteData
        );

        $finish;
      end
    end
  end

  initial begin
    #1000;
    $display("[FAIL] tb_shift: tiempo agotado");
    $finish;
  end

endmodule