module apb_requester #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    input  logic                     Pclk,
    input  logic                     PRESETn,

    // Upstream request interface
    input  logic                     req_valid, // Indicates to APB_Requester: new request data is valid
    output logic                     req_ready, // Indicates to processor: ready to accept new request
    input  logic [ADDR_WIDTH-1:0]    req_addr,
    input  logic                     req_write,
    input  logic [DATA_WIDTH-1:0]    req_wdata,
    output logic [DATA_WIDTH-1:0]    req_rdata,
    output logic                     req_error,

    // APB interface (Requester side)
    output logic                     PSEL,
    output logic                     PENABLE,
    output logic                     PWRITE,
    output logic [ADDR_WIDTH-1:0]    PADDR,
    output logic [DATA_WIDTH-1:0]    PWDATA,
    input  logic [DATA_WIDTH-1:0]    PRDATA,
    input  logic                     PREADY,
    input  logic                     PSLVERR
);

    // -------------------------
    //    State Machine
    // -------------------------
    typedef enum logic [1:0] {
        IDLE,
        SETUP,
        ACCESS
    } apb_state_t;

    apb_state_t state, next_state;

    // Sequential state update
    always_ff @(posedge Pclk or posedge PRESETn) begin
        if (!PRESETn)
            state <= IDLE;
        else
            state <= next_state;
    end

    // ------------------------------------------------------------------
    //     Next-state Logic
    // ------------------------------------------------------------------
    always_comb begin
        // Defaults
        req_ready = 1'b0;
        PSEL = 1'b0;
        PENABLE = 1'b0;
        req_rdata = {DATA_WIDTH{1'b0}};
        
        next_state = state;

        case (state)

            IDLE: begin
                PSEL = 1'b0;
                PENABLE = 1'b0;
                req_ready = 1'b1;  // accept new request
                if (req_valid) next_state = SETUP;
            end

            SETUP: begin
                PSEL = 1'b1;
                PENABLE = 1'b0;
                req_ready = 1'b0;  //Requester Busy
                next_state = ACCESS;
            end

            ACCESS: begin
                PSEL    = 1'b1;
                PENABLE = 1'b1;
                req_ready = 1'b0;  //Requester Busy
                if(!PWRITE) req_rdata = PRDATA;    //If read, capture read data

                if (PREADY && req_valid) next_state = SETUP;
                else if (PREADY && !req_valid) next_state = IDLE;
            end

        endcase
    end

    task automatic Capture_Request();
        PWRITE <= req_write;
        PADDR <= req_addr;

        if(req_write) PWDATA <= req_wdata;
        else PWDATA <= {DATA_WIDTH{1'b0}};
    endtask
    
    task automatic reset_bus();
        PWRITE  <= 1'b0;
        PWDATA  <= {DATA_WIDTH{1'b0}};
        PADDR   <= {DATA_WIDTH{1'b0}};
    endtask //automatic

    // ------------------------------------------------------------------
    //     Data Path Registers
    // ------------------------------------------------------------------
    always_ff @(posedge Pclk) begin

        if (!PRESETn)begin
            PADDR    <= '0;
            PWRITE   <= 1'b0;
            PWDATA   <= '0;
            req_error <= 1'b0;
        end else begin

            case(state)
                IDLE: begin
                    if (req_valid) begin
                        Capture_Request();
                    end else begin
                        reset_bus();
                    end
                end

                SETUP: begin
                    // No data path updates in SETUP
                end

                ACCESS: begin
                    if(PREADY)begin //when completer is ready

                        req_error <= PSLVERR;               //Capture error status

                        //capture new request if valid and go to setup state
                        //OR: reset bus and go to IDLE state
                        if (req_valid) begin
                            Capture_Request();
                        end else begin
                            reset_bus();
                        end
                    end
                end

            endcase
        end
    end

endmodule
