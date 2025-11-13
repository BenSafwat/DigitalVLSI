package AHB_defs;

    typedef enum logic [1:0]{
        //H_TRANS values
        IDLE  ,
        BUSY  ,
        NONSEQ,
        SEQ   
    }H_TRANS_t;

    typedef enum logic [2:0]{
        BYTE,
        HALFWORD,
        WORD,
        W2RD
    }H_SIZE_t;

    typedef enum logic [2:0]{
        SINGLE,
        INCR,
        INCR4,
        INCR8,
        INCR16
    }H_BURST_t;

endpackage