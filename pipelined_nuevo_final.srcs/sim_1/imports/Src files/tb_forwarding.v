// Testbench: Forwarding de Datos (Rutas EX/MEM y MEM/WB)
// Programa: Instrucciones ALU consecutivas que producen y consumen valores
//   inmediatamente -> requiere ForwardAE=10 (EX/MEM) y ForwardBE=01 (MEM/WB).
// Esperado: mem[100] = 13

`timescale 1ns / 1ps

module tb_forwarding;
  reg         clk, reset;
  wire [31:0] WriteData, DataAdr;
  wire        MemWrite;

  wire [31:0] InstrF, InstrD, InstrE, InstrM, InstrW;

  top #(.MEM_FILE("test_forwarding.mem")) dut(
    .clk(clk), .reset(reset),
    .WriteData(WriteData), .DataAdr(DataAdr), .MemWrite(MemWrite),
    .InstrF(InstrF), .InstrD(InstrD), .InstrE(InstrE),
    .InstrM(InstrM), .InstrW(InstrW)
  );

  initial clk = 1;
  always #5 clk = ~clk;

  initial begin
    reset = 1;
    #22;
    reset = 0;
  end

  wire [1:0] ForwardAE = dut.rvpipelined.hu.ForwardAE;
  wire [1:0] ForwardBE = dut.rvpipelined.hu.ForwardBE;
  wire       StallF    = dut.rvpipelined.hu.StallF;

  // Registrar cada evento de forwarding
  always @(negedge clk) begin
    if (!reset) begin
      $display("[PIPE] t=%0t | F=%h | D=%h | E=%h | M=%h | W=%h",
               $time, InstrF, InstrD, InstrE, InstrM, InstrW);

      if (ForwardAE == 2'b10)
        $display("[FWD-MEM] t=%0t  Forwarding EX/MEM -> SrcA", $time);
      if (ForwardAE == 2'b01)
        $display("[FWD-WB]  t=%0t  Forwarding MEM/WB -> SrcA", $time);
      if (ForwardBE == 2'b10)
        $display("[FWD-MEM] t=%0t  Forwarding EX/MEM -> SrcB", $time);
      if (ForwardBE == 2'b01)
        $display("[FWD-WB]  t=%0t  Forwarding MEM/WB -> SrcB", $time);

      if (StallF)
        $display("[WARN]    t=%0t  Stall inesperado", $time);
    end
  end

  always @(negedge clk) begin
    if (MemWrite) begin
      if (DataAdr === 32'd100 && WriteData === 32'd13) begin
        $display("[PASS]  tb_forwarding: mem[100]=%0d (forwarding correcto)", WriteData);
        $finish;
      end else begin
        $display("[FAIL]  tb_forwarding: addr=%0d  data=%0d (esperado addr=100 data=13)",
                 DataAdr, WriteData);
        $finish;
      end
    end
  end

  initial begin
    #800;
    $display("[FAIL]  tb_forwarding: tiempo agotado");
    $finish;
  end

endmodule