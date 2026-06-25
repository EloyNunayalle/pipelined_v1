// Unidad de manejo de riesgos (Hazard Unit)
// Controla el forwarding, los stalls (burbujas) y los flushes del pipeline
module hazard(
  input  [4:0] Rs1D, Rs2D,
  input  [4:0] Rs1E, Rs2E, RdE,
  input  [4:0] RdM, RdW,
  input        RegWriteM, RegWriteW,
  input        IsLoadE,
  input        PCSrcE,
  output reg [1:0] ForwardAE, ForwardBE,
  output StallF, StallD, FlushD, FlushE
);

  wire lwStall;

  // Forwarding desde EX/MEM tiene prioridad sobre MEM/WB
  always @(*) begin
    if      (RegWriteM && RdM != 0 && RdM == Rs1E) ForwardAE = 2'b10;
    else if (RegWriteW && RdW != 0 && RdW == Rs1E) ForwardAE = 2'b01;
    else                                             ForwardAE = 2'b00;
  end

  always @(*) begin
    if      (RegWriteM && RdM != 0 && RdM == Rs2E) ForwardBE = 2'b10;
    else if (RegWriteW && RdW != 0 && RdW == Rs2E) ForwardBE = 2'b01;
    else                                             ForwardBE = 2'b00;
  end

  // Riesgo Load-use: detener un ciclo e insertar burbuja en EX
  assign lwStall = IsLoadE && (RdE == Rs1D || RdE == Rs2D);

  assign StallF = lwStall;
  assign StallD = lwStall;
  assign FlushD = PCSrcE;
  assign FlushE = lwStall | PCSrcE;

endmodule
