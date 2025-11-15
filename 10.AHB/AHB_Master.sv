import AHB_defs::*;

module AHB_master(
    input  logic        H_CLK,
    input  logic        H_RESETn,
    
    // bus side
    output logic        H_SEL,          // master asserts when addressing the slave (decoder simplified)
    output logic [31:0] H_ADDR,
    output logic [31:0] H_WDATA,
    output H_SIZE_t     H_SIZE,
    output H_BURST_t    H_BURST,
    output logic [3:0]  H_PROTECT,
    output H_TRANS_t    H_TRANS,
    output logic        H_WRITE,
    output logic        H_MASTLOCK,
    
    input  logic        H_READY,    // from Slave → MUX → Master
    input  logic [31:0] H_RDATA,
    input  logic        H_RESPONSE,

    input logic         CMD_start,
    input logic [31:0]  CMD_ADDR,
    input logic         CMD_WRITE,
    input H_SIZE_t      CMD_SIZE,
    input H_BURST_t     CMD_BURST,
    input logic [31:0]  CMD_WDATA,
    output logic [31:0] CMD_RDATA,

    output logic ready,valid
);
    // register outputs
    logic [31:0]    addr_r;
    logic           write_r;
    H_SIZE_t        size_r;
    H_BURST_t       burst_r;
    logic [31:0]    Wdata_r;
    logic [31:0]    Rdata_r;

    logic [7:0] BEAT_cnt;

    typedef enum logic [2:0] {
        M_IDLE,
        M_TRANSCEIVE,
        M_WAIT_READY
    } master_state_t;
    master_state_t current_state, next_state;


    logic [7:0] BEAT_num;
    always_comb begin
        case(burst_r)
            SINGLE : BEAT_num = 0;
            INCR   : BEAT_num = 8'hFF;
            INCR4  : BEAT_num = 3;
            INCR8  : BEAT_num = 7;
            INCR16 : BEAT_num = 15;
        endcase  
    end

    // current_state register
    always_ff @(posedge H_CLK or negedge H_RESETn) begin
        if (!H_RESETn) begin
            current_state <= M_IDLE;
        end else begin
            current_state <= next_state;
        end
    end


    // next-current_state and outputs
    always_comb begin
        next_state = current_state;
        
        case (current_state)
            M_IDLE: begin
                if (CMD_start && H_READY) next_state = M_TRANSCEIVE;
            end

            M_TRANSCEIVE:begin
                H_SEL = 1'b1;   //slave should be selected by the decoder, however am keeping it simple for now
                if(!CMD_start) next_state = M_IDLE;
            end
            default: next_state = M_IDLE;

        endcase
    end

    task automatic captureCMD();
        H_ADDR  <= CMD_ADDR;
        H_WRITE <= CMD_WRITE;
        H_SIZE  <= CMD_SIZE;
        H_BURST <= CMD_BURST;

        write_r <= CMD_WRITE;
        burst_r <= CMD_BURST;               //save it for next cycle
        if(CMD_WRITE) Wdata_r <= CMD_WDATA; //save it for next cycle
        //else Rdata_r <= H_RDATA           //not needed as we don't send or receive data on the first beat(only address)
    endtask

    assign ready = H_READY;
    assign CMD_RDATA = H_RDATA;

    always_ff @(posedge H_CLK or negedge H_RESETn) begin
        if (!H_RESETn) begin
            addr_r <= 32'h0;
            write_r <= 1'b0;
            size_r <= WORD;
            burst_r <= SINGLE;
            Wdata_r <= 32'h0;
            
            BEAT_cnt <= 0;
            //valid <= 0;

            H_ADDR  <= 1'b0;
            H_WRITE <= 1'b0;
            H_SIZE  <= WORD;
            H_BURST <= SINGLE;
            H_WDATA <= 32'h0;

            H_PROTECT   <= 3'b0;
            H_TRANS     <= IDLE;
            H_MASTLOCK  <= 1'b0;
        end else begin
            case(current_state)

                M_IDLE :begin
                    H_TRANS     <= IDLE;
                    BEAT_cnt    <= 0;
                    valid       <= 0;
                    
                    //capturing address and control signals
                    if (CMD_start && H_READY)begin
                        H_TRANS <= NONSEQ;
                        captureCMD();
                    end
                end

                M_TRANSCEIVE:begin
                    //generating Address and Control signals
                    if(H_READY)begin
                        H_TRANS <= (CMD_start && (BEAT_cnt == BEAT_num)) ? NONSEQ : SEQ;
                        
                        if(write_r) begin
                            H_WDATA <= Wdata_r;
                            Wdata_r <= CMD_WDATA;
                        end 
                        //else assign CMD_RDATA from H_RDATA

                        if(BEAT_cnt < BEAT_num) begin
                            BEAT_cnt <= BEAT_cnt + 1;    //increment BEAT count
                            valid <= (CMD_WRITE)? 0 : 1;
                        end else begin //last cycle: BEAT_cnt == BEAT_num
                            BEAT_cnt <= 0;
                            if(CMD_start) captureCMD();//Processor have another data capture it
                        end 
                    end
                end
            endcase
        end
    end

endmodule
