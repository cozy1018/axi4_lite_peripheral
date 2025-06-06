module counter_peripheral (
    input  logic        clk,
    input  logic        rst_n,
    // AXI4-Lite Write Address Channel
    input  logic        awvalid,
    output logic        awready,
    input  logic [31:0] awaddr,
    // AXI4-Lite Write Data Channel
    input  logic        wvalid,
    output logic        wready,
    input  logic [31:0] wdata,
    input  logic [3:0]  wstrb,
    // AXI4-Lite Write Response Channel
    output logic        bvalid,
    input  logic        bready,
    output logic [1:0]  bresp,  // Added missing write response
    // AXI4-Lite Read Address Channel
    input  logic        arvalid,
    output logic        arready,
    input  logic [31:0] araddr,
    // AXI4-Lite Read Data Channel
    output logic        rvalid,
    input  logic        rready,
    output logic [31:0] rdata,
    output logic [1:0]  rresp   // Added missing read response
);
    // Internal registers
    logic [31:0] ctrl;
    logic [31:0] count;
    logic [31:0] init_val;
    logic        counting;
    logic        ctrl_prev;  // To detect rising edge
    
    // AXI write state machine
    typedef enum logic [1:0] {
        W_IDLE,
        W_WAIT_DATA,
        W_RESPONSE
    } write_state_t;
    
    write_state_t wr_state;
    logic [31:0] wr_addr_reg;
    
    // AXI read state machine  
    typedef enum logic [1:0] {
        R_IDLE,
        R_RESPONSE
    } read_state_t;
    
    read_state_t rd_state;
    logic [31:0] rd_addr_reg;

    // Write logic with proper AXI handshaking
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ctrl <= 32'd0;
            init_val <= 32'd0;
            wr_state <= W_IDLE;
            wr_addr_reg <= 32'd0;
            awready <= 1'b0;
            wready <= 1'b0;
            bvalid <= 1'b0;
            bresp <= 2'b00;
        end else begin
            case (wr_state)
                W_IDLE: begin
                    awready <= 1'b1;
                    wready <= 1'b1;
                    bvalid <= 1'b0;
                    
                    if (awvalid && awready) begin
                        wr_addr_reg <= awaddr;
                        awready <= 1'b0;
                        if (wvalid && wready) begin
                            // Both address and data ready simultaneously
                            case (awaddr)
                                32'h00: ctrl <= wdata;
                                32'h08: init_val <= wdata;
                                default: ;
                            endcase
                            wr_state <= W_RESPONSE;
                            wready <= 1'b0;
                            bvalid <= 1'b1;
                            bresp <= 2'b00; // OKAY response
                        end else begin
                            wr_state <= W_WAIT_DATA;
                        end
                    end else if (wvalid && wready) begin
                        wready <= 1'b0;
                        wr_state <= W_WAIT_DATA; // Wait for address
                    end
                end
                
                W_WAIT_DATA: begin
                    if (wvalid && !wready) begin
                        wready <= 1'b1;
                        case (wr_addr_reg)
                            32'h00: ctrl <= wdata;
                            32'h08: init_val <= wdata;
                            default: ;
                        endcase
                        wr_state <= W_RESPONSE;
                        wready <= 1'b0;
                        bvalid <= 1'b1;
                        bresp <= 2'b00;
                    end else if (awvalid && !awready) begin
                        awready <= 1'b1;
                        wr_addr_reg <= awaddr;
                        case (awaddr)
                            32'h00: ctrl <= wdata;
                            32'h08: init_val <= wdata;
                            default: ;
                        endcase
                        wr_state <= W_RESPONSE;
                        awready <= 1'b0;
                        bvalid <= 1'b1;
                        bresp <= 2'b00;
                    end
                end
                
                W_RESPONSE: begin
                    if (bvalid && bready) begin
                        bvalid <= 1'b0;
                        wr_state <= W_IDLE;
                    end
                end
            endcase
        end
    end

    // Counter logic with proper edge detection
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= 32'd0;
            counting <= 1'b0;
            ctrl_prev <= 1'b0;
        end else begin
            ctrl_prev <= ctrl[0];
            
            // Detect rising edge of ctrl[0]
            if (!ctrl_prev && ctrl[0]) begin
                count <= init_val;
                counting <= 1'b1;
            end else if (ctrl[0] && counting) begin
                count <= count + 1;
            end else if (!ctrl[0]) begin
                counting <= 1'b0;
            end
        end
    end

    // Read logic with proper AXI handshaking
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_state <= R_IDLE;
            rd_addr_reg <= 32'd0;
            arready <= 1'b0;
            rvalid <= 1'b0;
            rdata <= 32'd0;
            rresp <= 2'b00;
        end else begin
            case (rd_state)
                R_IDLE: begin
                    arready <= 1'b1;
                    rvalid <= 1'b0;
                    
                    if (arvalid && arready) begin
                        rd_addr_reg <= araddr;
                        arready <= 1'b0;
                        rvalid <= 1'b1;
                        rresp <= 2'b00; // OKAY response
                        
                        case (araddr)
                            32'h00: rdata <= ctrl;
                            32'h04: rdata <= count;
                            32'h08: rdata <= init_val;
                            default: begin
                                rdata <= 32'd0;
                                rresp <= 2'b10; // SLVERR for invalid address
                            end
                        endcase
                        rd_state <= R_RESPONSE;
                    end
                end
                
                R_RESPONSE: begin
                    if (rvalid && rready) begin
                        rvalid <= 1'b0;
                        rd_state <= R_IDLE;
                    end
                end
            endcase
        end
    end

endmodule