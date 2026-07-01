`timescale 1ns/1ps

module tb_quicksort;

reg clk;
reg reset;

wire [31:0] WriteData;
wire [31:0] DataAdr;
wire MemWrite;

wire [31:0] InstrF, InstrD, InstrE, InstrM, InstrW;

integer cycles;

//--------------------------------------------------
// DUT
//--------------------------------------------------

top #(
    .MEM_FILE("quicksort_fat1.mem")
) dut(
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

//--------------------------------------------------
// Clock
//--------------------------------------------------

initial
    clk = 1;

always #5 clk = ~clk;

//--------------------------------------------------
// Reset
//--------------------------------------------------

initial begin
    reset  = 1;
    cycles = 0;

    #22;
    reset = 0;

    // Esperar hasta que el programa inicialice el arreglo
    wait (A7 == 32'h52DDBEE2);

    #1;

    $display("");
    $display("======================================");
    $display("         ARREGLO INICIAL");
    $display("======================================");
    mostrar_arreglo();
    $display("======================================");
    $display("");

end

//--------------------------------------------------
// Contador de ciclos
//--------------------------------------------------

always @(posedge clk)
begin
    if (reset)
        cycles <= 0;
    else
        cycles <= cycles + 1;
end

//--------------------------------------------------
// Arreglo en memoria
//--------------------------------------------------

wire [31:0] A0 = dut.dmem.RAM[2040];
wire [31:0] A1 = dut.dmem.RAM[2041];
wire [31:0] A2 = dut.dmem.RAM[2042];
wire [31:0] A3 = dut.dmem.RAM[2043];
wire [31:0] A4 = dut.dmem.RAM[2044];
wire [31:0] A5 = dut.dmem.RAM[2045];
wire [31:0] A6 = dut.dmem.RAM[2046];
wire [31:0] A7 = dut.dmem.RAM[2047];

//--------------------------------------------------
// Mostrar arreglo
//--------------------------------------------------

task mostrar_arreglo;
begin

    $display("A0 = %08h", A0);
    $display("A1 = %08h", A1);
    $display("A2 = %08h", A2);
    $display("A3 = %08h", A3);
    $display("A4 = %08h", A4);
    $display("A5 = %08h", A5);
    $display("A6 = %08h", A6);
    $display("A7 = %08h", A7);

end
endtask

//--------------------------------------------------
// Esperar hasta que termine
//--------------------------------------------------

initial
begin

    forever
    begin

        @(posedge clk);

        if (!reset)

        begin

            if (

                A0 == 32'h52DDBEE2 &&
                A1 == 32'h54E9A990 &&
                A2 == 32'h565E3A49 &&
                A3 == 32'h577CB5BA &&
                A4 == 32'h586F53C7 &&
                A5 == 32'h599E80AB &&
                A6 == 32'h5A218000 &&
                A7 == 32'h5B25951D

            )

            begin

                $display("");
                $display("======================================");
                $display("PASS: QuickSort ordeno correctamente.");
                $display("Tiempo de simulacion : %0t ns", $time);
                $display("Ciclos ejecutados    : %0d", cycles);

                $display("");
                $display("======================================");
                $display("          ARREGLO FINAL");
                $display("======================================");
                mostrar_arreglo();
                $display("======================================");

                $finish;

            end

        end

    end

end

//--------------------------------------------------
// Timeout
//--------------------------------------------------

initial
begin

    #50000000;

    $display("");
    $display("======================================");
    $display("TIMEOUT");
    $display("Tiempo de simulacion : %0t ns", $time);
    $display("Ciclos ejecutados    : %0d", cycles);

    $display("");
    $display("======================================");
    $display("          ARREGLO FINAL");
    $display("======================================");
    mostrar_arreglo();
    $display("======================================");

    $finish;

end

endmodule