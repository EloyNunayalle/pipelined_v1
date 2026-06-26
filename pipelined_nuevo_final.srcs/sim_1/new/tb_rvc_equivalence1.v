//==============================================================
// Testbench: RVC Equivalence
//
// Verifica que las instrucciones comprimidas de la Parte I
// producen exactamente el mismo resultado que sus equivalentes
// RV32I.
//
// Instrucciones verificadas:
//
//   c.lui
//   c.addi
//   c.slli
//   c.srli
//   c.srai
//   c.add
//   c.sub
//   c.and
//   c.or
//   c.xor
//
// Criterio:
//
//   x8  <- instrucciones RVC
//   x9  <- instrucciones RV32I
//
// Al finalizar:
//
//   sub x11, x8, x9
//   sw  x11,100(x0)
//
// Esperado:
//
//   mem[100] = 0x00000000
//==============================================================

`timescale 1ns / 1ps

module tb_rvc_equivalence1;

    reg clk;
    reg reset;

    wire [31:0] WriteData;
    wire [31:0] DataAdr;
    wire MemWrite;

    // Propagacion del pipeline
    wire [31:0] InstrF;
    wire [31:0] InstrD;
    wire [31:0] InstrE;
    wire [31:0] InstrM;
    wire [31:0] InstrW;

    //----------------------------------------------------------
    // DUT
    //----------------------------------------------------------

    top #(
        .MEM_FILE("test_rvc_equivalence1.mem")
    ) dut (

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

    //----------------------------------------------------------
    // Clock
    //----------------------------------------------------------

    initial
        clk = 1'b1;

    always
        #5 clk = ~clk;

    //----------------------------------------------------------
    // Reset
    //----------------------------------------------------------

    initial begin

        reset = 1'b1;

        #22;

        reset = 1'b0;

    end

    //----------------------------------------------------------
    // Pipeline Trace
    //----------------------------------------------------------

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

    //----------------------------------------------------------
    // Resultado final
    //----------------------------------------------------------

    always @(negedge clk) begin

        if (MemWrite) begin

            if (DataAdr == 32'd100 &&
                WriteData == 32'h00000000) begin

                $display("");
                $display("----------------------------------------");
                $display("[PASS] tb_rvc_equivalence");
                $display("Todas las instrucciones RVC");
                $display("producen el mismo resultado");
                $display("que sus equivalentes RV32I.");
                $display("mem[100] = %h", WriteData);
                $display("----------------------------------------");

                $finish;

            end

            else begin

                $display("");
                $display("----------------------------------------");
                $display("[FAIL] tb_rvc_equivalence");
                $display("Direccion : %0d", DataAdr);
                $display("Resultado : %h", WriteData);
                $display("Esperado  : 00000000");
                $display("----------------------------------------");

                $finish;

            end

        end

    end

    //----------------------------------------------------------
    // Timeout
    //----------------------------------------------------------

    initial begin

        #2000;

        $display("");
        $display("----------------------------------------");
        $display("[FAIL] tb_rvc_equivalence");
        $display("Tiempo agotado.");
        $display("----------------------------------------");

        $finish;

    end

endmodule