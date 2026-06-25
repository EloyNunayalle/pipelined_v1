// Testbench: Hazard de Load-Use (Stall de 1 ciclo)
// Programa: SW a mem[0]=25, luego LW desde mem[0] a x4, luego XORI x5=x4^1.
// El XORI sigue inmediatamente al LW — la unidad de hazard debe detener IF+ID por 1 ciclo
// e insertar una burbuja en EX (FlushE=1) para que x4 este listo desde el forwarding de WB.
// Esperado: mem[100] = 24
`timescale 1ns / 1ps
module tb_stall;
  reg         clk, reset;
  wire [31:0] WriteData, DataAdr;
  wire        MemWrite;

  wire [31:0] InstrF, InstrD, InstrE, InstrM, InstrW;

  top #(.MEM_FILE("test_stall.mem")) dut(
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

  wire       StallF  = dut.rvpipelined.hu.StallF;
  wire       StallD  = dut.rvpipelined.hu.StallD;
  wire       FlushE  = dut.rvpipelined.hu.FlushE;
  wire       IsLoadE = dut.rvpipelined.hu.IsLoadE;
  wire       lwStall = dut.rvpipelined.hu.lwStall;

  // (Los monitores de instruccion ahora son wires directos del dut)

  reg stall_seen;
  initial stall_seen = 0;

  always @(negedge clk) begin
    if (!reset) begin
      $display("[PIPE] t=%0t | F=%h | D=%h | E=%h | M=%h | W=%h",
               $time, InstrF, InstrD, InstrE, InstrM, InstrW);

      if (lwStall) begin
        $display("[STALL]   t=%0t  Hazard load-use detectado: StallF=%b StallD=%b FlushE=%b",
                 $time, StallF, StallD, FlushE);
        stall_seen = 1;
      end
      if (FlushE && !lwStall && $time > 30) begin // Evitar el flush inicial de reset
         $display("[BUBBLE]  t=%0t  Burbuja insertada en EX (InstrE forzada a NOP)", $time);
      end
    end
  end

  always @(negedge clk) begin
    if (MemWrite) begin
      if (DataAdr === 32'd0 && WriteData === 32'd25) begin
        $display("[INFO]  tb_stall: SW intermedio a mem[0]=25 OK");
      end else if (DataAdr === 32'd100 && WriteData === 32'd24) begin
        if (stall_seen)
          $display("[PASS]  tb_stall: mem[100]=%0d y se observo el stall load-use", WriteData);
        else
          $display("[FAIL]  tb_stall: valor correcto pero NUNCA se observo el stall");
        $finish;
      end else begin
        $display("[FAIL]  tb_stall: addr=%0d  data=%0d", DataAdr, WriteData);
        $finish;
      end
    end
  end

  initial begin #800; $display("[FAIL]  tb_stall: tiempo agotado"); $finish; end
endmodule
