`timescale 1ns/1ps

module tb_apb_spi;

    // Parameters
    parameter DATA_WIDTH = 32;
    parameter ADDR_WIDTH = 32;
    parameter APB_CLK_PERIOD = 10;

    // APB signals
    reg                  PCLK;
    reg                  PRESETn;
    reg                  PSEL;
    reg                  PENABLE;
    reg                  PWRITE;
    reg  [ADDR_WIDTH-1:0] PADDR;
    reg  [DATA_WIDTH-1:0] PWDATA;
    wire [DATA_WIDTH-1:0] PRDATA;
    wire                 PREADY;
    wire                 PSLVERR;

    // SPI signals
    wire spi_cs_n;
    wire spi_sclk;
    wire spi_mosi;
    wire spi_miso;

    // Counters
    integer pass_count;
    integer fail_count;

    // DUT
    apb_spi_top dut (
        .PCLK(PCLK),
        .PRESETn(PRESETn),
        .PSEL(PSEL),
        .PENABLE(PENABLE),
        .PWRITE(PWRITE),
        .PADDR(PADDR),
        .PWDATA(PWDATA),
        .PRDATA(PRDATA),
        .PREADY(PREADY),
        .PSLVERR(PSLVERR),

        .spi_cs_n(spi_cs_n),
        .spi_sclk(spi_sclk),
        .spi_mosi(spi_mosi),
        .spi_miso(spi_miso)
    );

    // Clock generation
    initial begin
        PCLK = 0;
        forever #(APB_CLK_PERIOD/2) PCLK = ~PCLK;
    end

    // ============================
    // RESET
    // ============================
    task reset_dut;
        begin
            PRESETn = 0;
            PSEL    = 0;
            PENABLE = 0;
            PWRITE  = 0;
            PADDR   = 0;
            PWDATA  = 0;
            repeat (5) @(posedge PCLK);
            PRESETn = 1;
            repeat (5) @(posedge PCLK);
            $display("---- RESET DONE ----");
        end
    endtask

    // ============================
    // APB WRITE TASK
    // ============================
    task apb_write;
        input [ADDR_WIDTH-1:0] addr;
        input [DATA_WIDTH-1:0] data;
        begin
            @(posedge PCLK);
            PSEL    = 1;
            PWRITE  = 1;
            PADDR   = addr;
            PWDATA  = data;
            PENABLE = 0;

            @(posedge PCLK);
            PENABLE = 1;

            wait (PREADY);
            @(posedge PCLK);

            PSEL    = 0;
            PENABLE = 0;
            PWRITE  = 0;

            $display("[WRITE] Addr=0x%08h Data=0x%08h", addr, data);
        end
    endtask

    // ============================
    // APB READ TASK
    // ============================
    task apb_read;
        input  [ADDR_WIDTH-1:0] addr;
        input  [DATA_WIDTH-1:0] exp_data;
        begin
            @(posedge PCLK);
            PSEL    = 1;
            PWRITE  = 0;
            PADDR   = addr;
            PENABLE = 0;

            @(posedge PCLK);
            PENABLE = 1;

            wait (PREADY);
            @(posedge PCLK);

            if (PRDATA === exp_data) begin
                $display("[PASS] READ Addr=0x%08h Data=0x%08h", addr, PRDATA);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] READ Addr=0x%08h Exp=0x%08h Got=0x%08h",
                         addr, exp_data, PRDATA);
                fail_count = fail_count + 1;
            end

            PSEL    = 0;
            PENABLE = 0;
        end
    endtask

    // ============================
    // MAIN TEST
    // ============================
    initial begin
        $dumpfile("tb_apb_spi.vcd");
        $dumpvars(0, tb_apb_spi);

        pass_count = 0;
        fail_count = 0;

        reset_dut();

        // ----------------------------
        // WRITE TESTS
        // ----------------------------
        apb_write(32'h0000_0000, 32'hDEAD_BEEF);
        apb_write(32'h0000_0004, 32'h1234_5678);
        apb_write(32'h0000_0008, 32'hA5A5_A5A5);

        repeat (50) @(posedge PCLK);

        // ----------------------------
        // READ TESTS
        // ----------------------------
        apb_read(32'h0000_0000, 32'hDEAD_BEEF);
        apb_read(32'h0000_0004, 32'h1234_5678);
        apb_read(32'h0000_0008, 32'hA5A5_A5A5);

        // ----------------------------
        // SUMMARY
        // ----------------------------
        $display("----------------------------------");
        $display("TEST SUMMARY");
        $display("PASS : %0d", pass_count);
        $display("FAIL : %0d", fail_count);
        $display("----------------------------------");

        if (fail_count == 0)
            $display("ALL TESTS PASSED ");
        else
            $display("TEST FAILED");

        #100;
        $finish;
    end

endmodule

