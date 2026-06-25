// Procesador RISC-V monociclo/segmentado 
// Modulo principal que conecta el datapath y el controlador
module riscvsingle(
  input  clk, reset,
  output [31:0] PC,        // PC de la etapa IF -> imem
  input  [31:0] Instr,     // Instruccion desde imem (etapa IF)
  output        MemWrite,  // Habilitacion de escritura en etapa MEM -> dmem
  output [31:0] DataAdr,   // Resultado ALU de la etapa MEM -> direccion dmem
  output [31:0] WriteData, // Datos a escribir en etapa MEM -> dmem
  input  [31:0] ReadData,  // Datos leidos desde dmem (etapa MEM)
  
  // ---- Instrucciones propagadas para depuracion ----
  output [31:0] InstrF,
  output [31:0] InstrD,
  output [31:0] InstrE,
  output [31:0] InstrM,
  output [31:0] InstrW
);

  // ---- Salidas del controlador (etapa ID, segmentadas en el datapath) ----
  wire        RegWriteD, ALUSrcD, MemWriteD, JumpD, BranchD;
  wire [1:0]  ResultSrcD;
  wire [2:0]  ImmSrcD;
  wire [2:0]  ALUControlD;

  // ---- Senales de etapa EX (hacia unidad de hazard) ----
  wire [4:0]  Rs1E, Rs2E, RdE;
  wire        PCSrcE, IsLoadE;

  // ---- Senales de etapa MEM ----
  wire        RegWriteM, MemWriteM;
  wire [4:0]  RdM;
  wire [31:0] ALUResultM, WriteDataM;

  // ---- Senales de etapa WB ----
  wire        RegWriteW;
  wire [4:0]  RdW;

  // ---- Salidas de la unidad de hazard ----
  wire [1:0]  ForwardAE, ForwardBE;
  wire        StallF, StallD, FlushD, FlushE;

  // ---- Direcciones de registros para unidad de hazard (desde etapa ID) ----
  wire [4:0]  Rs1D, Rs2D;

  // ---- PC de etapa IF ----
  wire [31:0] PCF;
  assign PC       = PCF;
  assign DataAdr  = ALUResultM;
  assign WriteData= WriteDataM;
  assign MemWrite = MemWriteM;
  assign InstrF   = Instr; // IF es directamente la entrada

  controller c(
    .op(InstrD[6:0]),
    .funct3(InstrD[14:12]),
    .funct7b5(InstrD[30]),
    .ResultSrc(ResultSrcD), .MemWrite(MemWriteD),
    .ALUSrc(ALUSrcD),       .RegWrite(RegWriteD),
    .Jump(JumpD),           .Branch(BranchD),
    .ImmSrc(ImmSrcD),       .ALUControl(ALUControlD)
  );

  datapath dp(
    .clk(clk),     .reset(reset),
    // IF
    .PCF(PCF),     .InstrF(Instr),
    // ID
    .InstrD(InstrD),
    .Rs1D(Rs1D),   .Rs2D(Rs2D),
    .RegWriteD(RegWriteD), .ALUSrcD(ALUSrcD),
    .MemWriteD(MemWriteD), .JumpD(JumpD),
    .BranchD(BranchD),
    .ResultSrcD(ResultSrcD), .ImmSrcD(ImmSrcD),
    .ALUControlD(ALUControlD),
    // EX
    .Rs1E(Rs1E),   .Rs2E(Rs2E), .RdE(RdE),
    .PCSrcE(PCSrcE),
    .IsLoadE(IsLoadE),
    // MEM
    .RegWriteM(RegWriteM), .MemWriteM(MemWriteM),
    .RdM(RdM),
    .ALUResultM(ALUResultM), .WriteDataM(WriteDataM),
    .ReadDataM(ReadData),
    // WB
    .RegWriteW(RegWriteW), .RdW(RdW),
    // Control de hazard
    .StallF(StallF),       .StallD(StallD),
    .FlushD(FlushD),       .FlushE(FlushE),
    .ForwardAE(ForwardAE), .ForwardBE(ForwardBE),
    // Instrucciones para depuracion
    .InstrE(InstrE), .InstrM(InstrM), .InstrW(InstrW)
  );

  hazard hu(
    .Rs1D(Rs1D),       .Rs2D(Rs2D),
    .Rs1E(Rs1E),       .Rs2E(Rs2E),     .RdE(RdE),
    .RdM(RdM),         .RdW(RdW),
    .RegWriteM(RegWriteM), .RegWriteW(RegWriteW),
    .IsLoadE(IsLoadE),
    .PCSrcE(PCSrcE),
    .ForwardAE(ForwardAE), .ForwardBE(ForwardBE),
    .StallF(StallF),   .StallD(StallD),
    .FlushD(FlushD),   .FlushE(FlushE)
  );

endmodule
