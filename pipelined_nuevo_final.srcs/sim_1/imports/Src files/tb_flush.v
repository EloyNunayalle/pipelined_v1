// Testbench: Hazard de Control ” Flush por Branch
// Programa: BEQ x1,x1,+12 (siempre tomado) salta dos instrucciones XORI x2,x0,0x7FF.
// La unidad de hazard establece FlushD=FlushE=1 el ciclo que PCSrcE=1, descartando
// las dos instrucciones recien buscadas (las convierte en NOPs/burbujas).
// Esperado: mem[100] = 25  (x2 no es sobreescrito por los XORI descartados)
`timescale 1ns / 1ps
module tb_flush;
  reg         clk, reset;
  wire [31:0] WriteData, DataAdr;
  wire        MemWrite;

  wire [31:0] InstrF, InstrD, InstrE, InstrM, InstrW;

  top #(.MEM_FILE("test_flush.mem")) dut(
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

  wire PCSrcE = dut.rvpipelined.hu.PCSrcE;
  wire FlushD = dut.rvpipelined.hu.FlushD;
  wire FlushE = dut.rvpipelined.hu.FlushE;

  // (Los monitores de instruccion ahora son wires directos del dut)

  reg flush_seen;
  initial flush_seen = 0;

  always @(negedge clk) begin
    if (!reset) begin
      $display("[PIPE] t=%0t | F=%h | D=%h | E=%h | M=%h | W=%h",
               $time, InstrF, InstrD, InstrE, InstrM, InstrW);

      if (PCSrcE) begin
        $display("[FLUSH]   t=%0t  Branch tomado: PCSrcE=1  FlushD=%b  FlushE=%b",
                 $time, FlushD, FlushE);
        flush_seen = 1;
      end
      if ((FlushD || FlushE) && !PCSrcE && $time > 30) begin // burbuja propagada
        $display("[BUBBLE]  t=%0t  Burbuja insertada por branch (Flush activo)", $time);
      end
    end
  end

  always @(negedge clk) begin
    if (MemWrite) begin
      if (DataAdr === 32'd100 && WriteData === 32'd25) begin
        if (flush_seen)
          $display("[PASS]  tb_flush: mem[100]=%0d y se observo el flush por branch", WriteData);
        else
          $display("[FAIL]  tb_flush: valor correcto pero NUNCA se observo el flush");
        $finish;
      end else begin
        $display("[FAIL]  tb_flush: addr=%0d  data=%0d  (instrucciones invalidadas ejecutadas!)",
                 DataAdr, WriteData);
        $finish;
      end
    end
  end

  initial begin #800; $display("[FAIL]  tb_flush: tiempo agotado"); $finish; end
endmodule
