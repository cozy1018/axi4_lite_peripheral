`timescale 1ns/1ps

module counter_tb();
    // Clock and reset
    logic clk;
    logic rst_n;
    
    // AXI4-Lite signals
    logic        awvalid, awready;
    logic [31:0] awaddr;
    logic        wvalid, wready;
    logic [31:0] wdata;
    logic [3:0]  wstrb;
    logic        bvalid, bready;
    logic [1:0]  bresp;
    logic        arvalid, arready;
    logic [31:0] araddr;
    logic        rvalid, rready;
    logic [31:0] rdata;
    logic [1:0]  rresp;

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk; // 100MHz

    // DUT
    counter_peripheral dut (
        .clk      (clk),
        .rst_n    (rst_n),
        .awvalid  (awvalid),
        .awready  (awready),
        .awaddr   (awaddr),
        .wvalid   (wvalid),
        .wready   (wready),
        .wdata    (wdata),
        .wstrb    (wstrb),
        .bvalid   (bvalid),
        .bready   (bready),
        .bresp    (bresp),
        .arvalid  (arvalid),
        .arready  (arready),
        .araddr   (araddr),
        .rvalid   (rvalid),
        .rready   (rready),
        .rdata    (rdata),
        .rresp    (rresp)
    );

    // Task: AXI write
    task axi_write(input [31:0] addr, input [31:0] data);
        begin
            @(posedge clk);
            awaddr  <= addr;
            awvalid <= 1;
            wdata   <= data;
            wvalid  <= 1;
            wstrb   <= 4'hF;
            bready  <= 1;
            
            // Wait for write to complete
            wait (bvalid && bready);
            @(posedge clk);
            awvalid <= 0;
            wvalid  <= 0;
            bready  <= 0;
            
            $display("[WRITE] addr = 0x%08x, data = 0x%08x, resp = %0d", addr, data, bresp);
        end
    endtask

    // Task: AXI read
    task axi_read(input [31:0] addr);
        begin
            @(posedge clk);
            araddr  <= addr;
            arvalid <= 1;
            rready  <= 1;
            
            // Wait for read to complete
            wait (rvalid && rready);
            @(posedge clk);
            $display("[READ] addr = 0x%08x, data = 0x%08x, resp = %0d", addr, rdata, rresp);
            arvalid <= 0;
            rready  <= 0;
        end
    endtask

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, counter_tb);
        
        // Initialize all signals
        awaddr = 0; awvalid = 0;
        wdata  = 0; wvalid  = 0;
        araddr = 0; arvalid = 0;
        rready = 0;
        wstrb  = 4'hF;
        bready = 0;
        rst_n = 0;
        
        // Reset sequence
        repeat (5) @(posedge clk);
        rst_n = 1;
        repeat (2) @(posedge clk);
                
        // Write INIT_VAL = 0x1000
        axi_write(32'h08, 32'h00001000);
        
        // Read back INIT_VAL to verify
        axi_read(32'h08);
        
        // Enable counter
        axi_write(32'h00, 32'h1);
        
        // Wait a few cycles and read count multiple times
        repeat (5) @(posedge clk);
        axi_read(32'h04);
        
        repeat (5) @(posedge clk);
        axi_read(32'h04);
        
        // Disable counter
        axi_write(32'h00, 32'h0);
        
        // Wait and verify counter stopped
        repeat (5) @(posedge clk);
        axi_read(32'h04);
        
        repeat (5) @(posedge clk);
        axi_read(32'h04);
        
        // Re-enable counter (should restart from init_val)
        axi_write(32'h00, 32'h1);
        
        repeat (3) @(posedge clk);
        axi_read(32'h04);
        
        // Test invalid address
        axi_read(32'h10);
        
        repeat (5) @(posedge clk);
        $finish;
    end

endmodule