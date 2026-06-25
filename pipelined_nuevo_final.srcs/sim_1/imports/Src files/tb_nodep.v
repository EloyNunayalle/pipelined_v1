// Testbench: Sin Dependencia de Datos
// Programa: 3 ADDIs con gap de NOPs, luego XOR de valores estables, luego SW.
// Hazard esperado: NINGUNO - sin forwarding, stall o flush.
// Esperado: mem[100] = 6 (5 ^ 3)
`timescale 1ns / 1ps
module tb_nodep;
  reg         clk, reset;
  wire [31:0] WriteData, DataAdr;
  wire        MemWrite;

  wire [31:0] InstrF, InstrD, InstrE, InstrM, InstrW;

  top #(.MEM_FILE("test_nodep.mem")) dut(
    .clk(clk), .reset(reset),
    .WriteData(WriteData), .DataAdr(DataAdr), .MemWrite(MemWrite),
    .InstrF(InstrF), .InstrD(InstrD), .InstrE(InstrE),
    .InstrM(InstrM), .InstrW(InstrW)
  );

  initial clk = 1;
  always #5 clk = ~clk;

  initial begin
    reset = 1; #22; reset = 0;
  end

  // Monitor de senales de hazard
  wire [1:0] ForwardAE = dut.rvpipelined.hu.ForwardAE;
  wire [1:0] ForwardBE = dut.rvpipelined.hu.ForwardBE;
  wire       StallF    = dut.rvpipelined.hu.StallF;
  wire       FlushE    = dut.rvpipelined.hu.FlushE;

  // (Los monitores de instruccion ahora son wires directos del dut)

  always @(negedge clk) begin
    if (!reset) begin
      $display("[PIPE] t=%0t | F=%h | D=%h | E=%h | M=%h | W=%h",
               $time, InstrF, InstrD, InstrE, InstrM, InstrW);

      if (ForwardAE !== 2'b00 || ForwardBE !== 2'b00)
        $display("[INFO]  t=%0t  ForwardAE=%b  ForwardBE=%b", $time, ForwardAE, ForwardBE);
      if (StallF)
        $display("[WARN]  t=%0t  Stall inesperado en prueba sin dependencias", $time);
      if (FlushE)
        $display("[INFO]  t=%0t  FlushE=1 (burbuja insertada durante drenaje de reset)", $time);
    end
  end

  always @(negedge clk) begin
    if (MemWrite) begin
      if (DataAdr === 32'd100 && WriteData === 32'd6) begin
        $display("[PASS]  tb_nodep: mem[100]=%0d (ruta sin hazard correcta)", WriteData);
        $finish;
      end else begin
        $display("[FAIL]  tb_nodep: addr=%0d  data=%0d (esperado: data=6)", DataAdr, WriteData);
        $finish;
      end
    end
  end

  initial begin #500; $display("[FAIL]  tb_nodep: tiempo agotado"); $finish; end
endmodule
