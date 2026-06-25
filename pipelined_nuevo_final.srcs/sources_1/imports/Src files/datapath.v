// Datapath del procesador RISC-V segmentado en 5 etapas 
// Etapas: IF -> ID -> EX -> MEM -> WB
// Incluye propagacion completa de la instruccion de 32 bits para depuracion en waveform
module datapath(
    input  clk, reset,
    
    // ---- Etapa IF ----
    output [31:0] PCF,
    input  [31:0] InstrF,
    input         IsCompressedF,
    
    // ---- Etapa ID: instruccion y direcciones de registros al controlador/hazard ----
    output [31:0] InstrD,
    output [4:0]  Rs1D, Rs2D,
    
    // ---- Etapa ID: senales de control desde el controlador ----
    input         RegWriteD, ALUSrcD, MemWriteD, JumpD, JalrD, BranchED, BranchNED,
    input  [1:0]  ResultSrcD,
    input  [2:0]  ImmSrcD,
    input  [3:0]  ALUControlD,
    
    // ---- Etapa EX: hacia la unidad de hazard ----
    output [4:0]  Rs1E, Rs2E, RdE,
    output        PCSrcE,
    output        IsLoadE,   // 1 solo para lw (ResultSrc==01)
    
    // ---- Etapa MEM: hacia la unidad de hazard y memoria externa ----
    output        RegWriteM, MemWriteM,
    output [4:0]  RdM,
    output [31:0] ALUResultM, WriteDataM,
    input  [31:0] ReadDataM,
    
    // ---- Etapa WB: hacia la unidad de hazard ----
    output        RegWriteW,
    output [4:0]  RdW,
    
    // ---- Control de la unidad de hazard ----
    input         StallF, StallD, FlushD, FlushE,
    input  [1:0]  ForwardAE, ForwardBE,
    
    // ---- Instruccion en cada etapa (solo para depuracion en waveform) ----
    output [31:0] InstrE,
    output [31:0] InstrM,
    output [31:0] InstrW
    );
    
    localparam WIDTH = 32;
    // NOP canonico: ADDI x0, x0, 0
    localparam NOP = 32'h00000013;
    
    // ================================================================
    // Etapa IF
    // ================================================================
    wire [31:0] PCNextF;
    wire [31:0] PCNextSeqF;
    wire [31:0] PCIncF;
    wire [31:0] PCTargetE;
    
    flopenr #(WIDTH) pcreg(
    .clk(clk), .reset(reset), .en(~StallF),
    .d(PCNextF), .q(PCF)
    );
    
    mux2 #(WIDTH) pcincmux(
        .d0(32'd4),
        .d1(32'd2),
        .s(IsCompressedF),
        .y(PCIncF)
    );
    
    adder pcadd(
        .a(PCF),
        .b(PCIncF),
        .y(PCNextSeqF)
    );
    
    // ----------------------------------------------------------------
    // Registro de pipeline IF/ID
    // ----------------------------------------------------------------
    wire [95:0] ifid_in;
    wire [95:0] ifid_out;
    
    assign ifid_in = {PCF, InstrF, PCNextSeqF};
    
    pipeline_reg #(
    .WIDTH(96),
    .RESET_VALUE(96'd0),
    .FLUSH_VALUE(96'd0)
    ) ifid_reg (
        .clk(clk),
        .reset(reset),
        .en(~StallD),
        .flush(FlushD),
    
        .d(ifid_in),
        .q(ifid_out)
    );
    
    wire [31:0] PCD;
    wire [31:0] PCNextSeqD;
    assign {
        PCD,
        InstrD,
        PCNextSeqD
    } = ifid_out;
    
    // ================================================================
    // Etapa ID
    // ================================================================
    assign Rs1D = InstrD[19:15];
    assign Rs2D = InstrD[24:20];
    wire [4:0]  RdD = InstrD[11:7];
    
    wire [31:0] RD1D, RD2D, ImmExtD, ResultW;
    
    regfile rf(
    .clk(clk), .we3(RegWriteW),
    .a1(Rs1D), .a2(Rs2D), .a3(RdW),
    .wd3(ResultW),
    .rd1(RD1D), .rd2(RD2D)
    );
    
    extend ext(
    .instr(InstrD[31:7]), .immsrc(ImmSrcD), .immext(ImmExtD)
    );
    
    // ----------------------------------------------------------------
    // Registro de pipeline ID/EX
    // ----------------------------------------------------------------
    localparam [219:0] ID_EX_BUBBLE = {
        1'b0,        // RegWrite
        1'b0,        // ALUSrc
        1'b0,        // MemWrite
        1'b0,        // Jump
        1'b0,        // Jalr
        1'b0,        // BranchE
        1'b0,       // BranchNE
        
        2'b00,       // ResultSrc
        4'b0000,      // ALUControl
        
        32'd0,       // RD1
        32'd0,       // RD2
        
        32'd0,       // PC
        
        5'd0,        // Rs1
        5'd0,        // Rs2
        5'd0,        // Rd
        
        32'd0,       // ImmExt
        32'd0,       // PCNextSeq
        
        NOP          // Instr
    };
    
    wire [219:0] idex_in;
    wire [219:0] idex_out;
    
    assign idex_in = {
        RegWriteD,
        ALUSrcD,
        MemWriteD,
        JumpD,
        JalrD,
        BranchED,
        BranchNED,
    
        ResultSrcD,
        ALUControlD,
    
        RD1D,
        RD2D,
    
        PCD,
    
        Rs1D,
        Rs2D,
        RdD,
    
        ImmExtD,
        PCNextSeqD,
    
        InstrD
    };
    
    pipeline_reg #(
        .WIDTH(220),
        .RESET_VALUE(220'd0),
        .FLUSH_VALUE(ID_EX_BUBBLE)
    ) idex_reg (
        .clk(clk),
        .reset(reset),
        .en(1'b1),
        .flush(FlushE),
        
        .d(idex_in),
        .q(idex_out)
    );
    
    wire        RegWriteE;
    wire        ALUSrcE;
    wire        MemWriteE;
    wire        JumpE;
    wire        JalrE;
    wire        BranchEE;
    wire        BranchNEE;
    
    wire [1:0]  ResultSrcE;
    wire [3:0]  ALUControlE;
    
    wire [31:0] RD1E;
    wire [31:0] RD2E;
    
    wire [31:0] PCE;
    wire [31:0] ImmExtE;
    wire [31:0] PCNextSeqE;
    
    wire [4:0]  Rs1E_int;
    wire [4:0]  Rs2E_int;
    wire [4:0]  RdE_int;
    
    wire [31:0] InstrE_int;
    
    
    assign {
        RegWriteE,
        ALUSrcE,
        MemWriteE,
        JumpE,
        JalrE,
        BranchEE,
        BranchNEE,
    
        ResultSrcE,
        ALUControlE,
    
        RD1E,
        RD2E,
    
        PCE,
    
        Rs1E_int,
        Rs2E_int,
        RdE_int,
    
        ImmExtE,
        PCNextSeqE,
    
        InstrE_int
    } = idex_out;
    
    
    assign Rs1E = Rs1E_int;
    assign Rs2E = Rs2E_int;
    assign RdE  = RdE_int;
    
    assign InstrE = InstrE_int;
    
    assign IsLoadE = (ResultSrcE == 2'b01);
    
    // ================================================================
    // Etapa EX
    // ================================================================
    wire [31:0] SrcAE, SrcBE, WriteDataE, ALUResultE;
    wire        ZeroE;
    
    // ResultM: para LUI (ResultSrc=11) se reenvia el inmediato, no el resultado ALU
    wire [31:0] ResultM;
    wire        ResultMSel;
    
    assign ResultMSel = (ResultSrcM == 2'b11);
    
    mux2 #(WIDTH) resultmmux(
        .d0(ALUResultM_int),
        .d1(ImmExtM),
        .s(ResultMSel),
        .y(ResultM)
    );
    
    // Muxes de forwarding
    mux3 #(WIDTH) fwdamux(.d0(RD1E), .d1(ResultW), .d2(ResultM), .s(ForwardAE), .y(SrcAE));
    mux3 #(WIDTH) fwdbmux(.d0(RD2E), .d1(ResultW), .d2(ResultM), .s(ForwardBE), .y(WriteDataE));
    mux2 #(WIDTH) srcbmux(.d0(WriteDataE), .d1(ImmExtE), .s(ALUSrcE), .y(SrcBE));
    
    alu alu_unit(
    .a(SrcAE), .b(SrcBE),
    .alucontrol(ALUControlE),
    .result(ALUResultE), .zero(ZeroE)
    );
    
    wire [31:0] BaseJumpE;

    mux2 #(WIDTH) jumpbasemux(
        .d0(PCE),
        .d1(SrcAE),
        .s(JalrE),
        .y(BaseJumpE)
    );
    
    
    wire [31:0] PCTargetRawE;
    
    adder targetadd(
        .a(BaseJumpE),
        .b(ImmExtE),
        .y(PCTargetE)
    );
    
        
    assign PCSrcE =
        (BranchEE   &  ZeroE) |
        (BranchNEE & ~ZeroE) |
        JumpE | JalrE;
    
    mux2 #(WIDTH) pcmux(
        .d0(PCNextSeqF),
        .d1(PCTargetE),
        .s(PCSrcE),
        .y(PCNextF)
    );
    
    // ----------------------------------------------------------------
    // Registro de pipeline EX/MEM
    // ----------------------------------------------------------------
    wire [168:0] exmem_in;
    wire [168:0] exmem_out;
    
    assign exmem_in = {
        RegWriteE,
        MemWriteE,
    
        ResultSrcE,
    
        ALUResultE,
        WriteDataE,
    
        PCNextSeqE,
    
        RdE,
    
        ImmExtE,
    
        InstrE
    };
    
    pipeline_reg #(
        .WIDTH(169),
        .RESET_VALUE(169'd0),
        .FLUSH_VALUE(169'd0)
    ) exmem_reg (
        .clk(clk),
        .reset(reset),
        .en(1'b1),
        .flush(1'b0),
    
        .d(exmem_in),
        .q(exmem_out)
    );
    
    wire        RegWriteM_int;
    wire        MemWriteM_int;
    
    wire [1:0]  ResultSrcM;
    
    wire [31:0] ALUResultM_int;
    wire [31:0] WriteDataM_int;
    
    wire [31:0] PCNextSeqM;
    wire [31:0] ImmExtM;
    
    wire [4:0]  RdM_int;
    
    wire [31:0] InstrM_int;
    
    
    assign {
    
        RegWriteM_int,
        MemWriteM_int,
    
        ResultSrcM,
    
        ALUResultM_int,
        WriteDataM_int,
    
        PCNextSeqM,
    
        RdM_int,
    
        ImmExtM,
    
        InstrM_int
    
    } = exmem_out;
    
    assign RegWriteM  = RegWriteM_int;
    assign MemWriteM  = MemWriteM_int;
    
    assign ALUResultM = ALUResultM_int;
    assign WriteDataM = WriteDataM_int;
    
    assign RdM        = RdM_int;
    
    assign InstrM     = InstrM_int;
    
    
    // ================================================================
    // Etapa MEM  (acceso a dmem externo ocurre en top/riscvpipelined)
    // ================================================================
    
    // ----------------------------------------------------------------
    // Registro de pipeline MEM/WB
    // ----------------------------------------------------------------
    wire [167:0] memwb_in;
    wire [167:0] memwb_out;
    
    assign memwb_in = {
        RegWriteM,
    
        ResultSrcM,
    
        ALUResultM,
        ReadDataM,
    
        PCNextSeqM,
    
        RdM,
    
        ImmExtM,
    
        InstrM
    };
    
    pipeline_reg #(
        .WIDTH(168),
        .RESET_VALUE(168'd0),
        .FLUSH_VALUE(168'd0)
    ) memwb_reg (
        .clk(clk),
        .reset(reset),
        .en(1'b1),
        .flush(1'b0),
    
        .d(memwb_in),
        .q(memwb_out)
    );
    
    wire        RegWriteW_int;

    wire [1:0]  ResultSrcW;
    
    wire [31:0] ALUResultW;
    wire [31:0] ReadDataW;
    
    wire [31:0] PCNextSeqW;
    wire [31:0] ImmExtW;
    
    wire [4:0]  RdW_int;
    
    wire [31:0] InstrW_int;
    
   
    assign {
        RegWriteW_int,
    
        ResultSrcW,
    
        ALUResultW,
        ReadDataW,
    
        PCNextSeqW,
    
        RdW_int,
    
        ImmExtW,
    
        InstrW_int
    
    } = memwb_out;
    
    assign RegWriteW = RegWriteW_int;
    assign RdW       = RdW_int;
    
    assign InstrW    = InstrW_int;
   
  
    // ================================================================
    // Etapa WB
    // ================================================================
    // Mux de resultado (4 opciones): 00=ALU, 01=ReadData(lw), 10 = PCNextSeq (jal / c.jal), 11=ImmExt(lui)
    mux4 #(WIDTH) resultwmux(
        .d0(ALUResultW),
        .d1(ReadDataW),
        .d2(PCNextSeqW),
        .d3(ImmExtW),
        .s(ResultSrcW),
        .y(ResultW)
    );

endmodule
