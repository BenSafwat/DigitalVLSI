module apb_completer #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter MEM_DEPTH  = 256
)(
    input  logic                     Pclk,
    input  logic                     PRESETn,

    // APB interface (Completer/Slave side)
    input  logic                     PSEL,
    input  logic                     PENABLE,
    input  logic                     PWRITE,
    input  logic [ADDR_WIDTH-1:0]    PADDR,
    input  logic [DATA_WIDTH-1:0]    PWDATA,
    output logic [DATA_WIDTH-1:0]    PRDATA,
    output logic                     PREADY,
    output logic                     PSLVERR
);

    // -------------------------
    //    Memory Array
    // -------------------------
    logic [DATA_WIDTH-1:0] memory [MEM_DEPTH];

    // -------------------------
    //    Address Decode
    // -------------------------
    logic [7:0] mem_addr;  // Use lower 8 bits for 256-entry memory (2^8)
    assign mem_addr = PADDR[7:0];

    logic addr_valid;
    assign addr_valid = (PADDR[ADDR_WIDTH-1:8] == '0);  // Check upper bits are 0

    // -------------------------
    //    State Machine
    // -------------------------
    typedef enum logic [1:0] {
        IDLE,
        ACCESS
    } apb_state_t;

    apb_state_t state, next_state;

    // Sequential state update
    always_ff @(posedge Pclk or negedge PRESETn) begin
        if (!PRESETn)
            state <= IDLE;
        else
            state <= next_state;
    end

    // -------------------------
    //    Next-State Logic
    // -------------------------
    always_comb begin
        next_state = state;

        case (state)
            IDLE: begin
                PREADY = 1'b0;
                if (PSEL && !PENABLE) next_state = ACCESS;
            end

            ACCESS: begin
                //If memory is ready
                    PREADY = 1'b1;
                //else in wait state
                    //PREADY = 1'b0;

                next_state = IDLE;
            end
        endcase
    end

    // -------------------------
    //    Data Path Logic
    // -------------------------
    always_ff @(posedge Pclk) begin
        if (!PRESETn) begin
            PRDATA <= {DATA_WIDTH{1'b0}};
            PSLVERR <= 1'b0;
        end else begin
            
            case(state)

                IDLE: begin
                    // Check if address is valid (within memory range)
                    if (!addr_valid) begin
                        PSLVERR <= 1'b1;  // Error: address out of range
                    end else begin
                        PSLVERR <= 1'b0;  // OK
                        if (!PWRITE && PSEL && !PENABLE) PRDATA <= memory[mem_addr]; // Read? retrieve data from memory
                    end
                end

                ACCESS: begin
                    if (PSEL && PENABLE && addr_valid) begin
                        if (PWRITE) begin
                            // Write transaction: store data to memory
                            memory[mem_addr] <= PWDATA;
                        end
                    end
                end

                default:;
            endcase
        end
    end

endmodule
