
`define FPGA
module SME(clk,reset,chardata,isstring,ispattern,valid,match,match_index);
input clk;
input reset;
input [7:0] chardata;
input isstring;
input ispattern;
output match;
output reg[4:0] match_index;
output valid;
//==================
//  Integers
//==================
integer i;

//==================
//  PARAMETERS
//==================
parameter BYTE = 8 ;
parameter STR_LENGTH = 1024 ;
parameter PATTERN_LENGTH = 32 ;

parameter PTR_WIDTH = BYTE;
parameter CNT_WIDTH = BYTE;

//==================
//  ASCII
//==================
localparam [7:0] HAT = 8'h5E ; // ^
localparam [7:0] DOLLAR = 8'h24 ; // $
localparam [7:0] POINT = 8'h2E ; // .
localparam [7:0] STAR = 8'h2A ; // *

localparam [7:0] SPACE = 8'h20 ; // [ ]

//==================
//  stateS
//==================
//L1 FSM
localparam RD_DATA      = 3'b001 ;
localparam STR_MATCHING = 3'b010 ;
localparam DONE         = 3'b100 ;

//L2 FSM
localparam NORMAL_MODE   = 4'b0001 ;
localparam FIRST_OR_SPACE  = 4'b0010 ;
localparam LAST_OR_SPACE = 4'b0100 ;
localparam WAIT_FOR_CHAR = 4'b1000 ;

//================================
//  MAIN CTR
//================================

`ifdef FPGA
(*fsm_encoding = "one_hot"*)
`endif
reg [3:0] l1_curState,l1_nxtState,l2_curState,l2_nxtState;

wire state_RD_DATA      = l1_curState[0];
wire state_STR_MATCHING = l1_curState[1];
wire state_DONE         = l1_curState[2];

wire state_NORMAL_MODE   = l2_curState[0];
wire state_CAP_OR_SPACE  = l2_curState[1];
wire state_LAST_OR_SPACE = l2_curState[2];
wire state_WAIT_FOR_CHAR = l2_curState[3];

//================================
//  String and Pattern PTRs
//================================
reg[PTR_WIDTH-1:0] pattern_char_ptr;
reg[PTR_WIDTH-1:0] str_char_ptr;
reg[PTR_WIDTH-1:0] str_frame_ptr;
reg [PTR_WIDTH-1:0] pattern_star_temp_ptr;


//================================
//  STR,PATTERN STORAGE
//================================
(*ram_style = "block"*) reg [BYTE-1:0] str_B_rf[0:STR_LENGTH-1];

(*ram_style = "block"*) reg [BYTE-1:0] pattern_B_rf[0:PATTERN_LENGTH-1];

(*ram_style = "block"*) reg [BYTE-1:0] pattern_B_mem[0:STR_LENGTH-1];


//================================
//  COUNTERS
//================================
reg [CNT_WIDTH-1:0] str_length_cnt;
reg [CNT_WIDTH-1:0] pattern_length_cnt;

//=======================================
//  String and Pattern current Character
//=======================================
wire[BYTE-1:0] current_str_char = str_B_rf[str_char_ptr];
wire[BYTE-1:0] current_pattern_char = pattern_B_rf[pattern_char_ptr];

//================================
//  CONTROL FLAGS
//================================
reg charMatches_f;
reg strMatchingDone_f;
reg matches_cur_state;
reg star_mode_state;
reg star_searched_state;

wire isHat_f           = pattern_B_rf[pattern_char_ptr] == HAT;
wire isStar_f          = pattern_B_rf[pattern_char_ptr] == STAR;
wire isDollar_f        = pattern_B_rf[pattern_char_ptr] == DOLLAR;

wire str_is_space_f    =  str_B_rf[str_char_ptr] == SPACE;

wire isPoint_f         = pattern_B_rf[pattern_char_ptr] == POINT;
wire charFound_f       = charMatches_f && state_WAIT_FOR_CHAR;

wire localpatternSearched_f = (pattern_char_ptr == (pattern_length_cnt-1));

wire firstStrChar_f              = str_char_ptr == 0;
wire lastStrChar_f               = str_char_ptr >= str_length_cnt;

wire str_current_is_empty        = current_str_char == 0;

wire patternMatched_f = (localpatternSearched_f && charMatches_f) || (state_LAST_OR_SPACE && str_current_is_empty);

wire star_all_permuted = str_frame_ptr == str_length_cnt-1;

//================================================================
//  MAIN DESIGN
//================================================================
//================================
//  level 1 FSM
//================================
always @(posedge clk or posedge reset)
begin:L1_FSM
    if(reset)
    begin
        l1_curState <=  RD_DATA;
    end
    else
    begin
        l1_curState <=  l1_nxtState;
    end
end

always @(*)
begin:L1_FSM_NXT
    case(l1_curState)
        RD_DATA:
        begin
            l1_nxtState = (~isstring && ~ispattern ) ? STR_MATCHING : RD_DATA;
        end
        STR_MATCHING:
        begin
            l1_nxtState = patternMatched_f || strMatchingDone_f ? DONE : STR_MATCHING;
        end
        DONE:
        begin
            l1_nxtState = RD_DATA;
        end
        default:
        begin
            l1_nxtState = RD_DATA;
        end
    endcase
end

//================================
//  level 2 FSM
//================================
always @(posedge clk or posedge reset)
begin:L2_FSM
    if(reset)
    begin
        l2_curState <=  NORMAL_MODE;
    end
    else
    begin
        l2_curState <=  l2_nxtState;
    end
end

always @(*)
begin:L2_FSM_NXT
    case(l2_curState)
        NORMAL_MODE:
        begin
            case({isHat_f,isDollar_f,isStar_f})
                3'b100:
                begin
                    l2_nxtState = FIRST_OR_SPACE;
                end
                3'b010:
                begin
                    l2_nxtState = LAST_OR_SPACE;
                end
                3'b001:
                begin
                    l2_nxtState = WAIT_FOR_CHAR;
                end
                default:
                begin
                    l2_nxtState = NORMAL_MODE;
                end
            endcase
        end
        FIRST_OR_SPACE:
        begin
            l2_nxtState = NORMAL_MODE;
        end
        LAST_OR_SPACE:
        begin
            l2_nxtState = NORMAL_MODE;
        end
        WAIT_FOR_CHAR:
        begin
            if(charFound_f)
            begin
                l2_nxtState = NORMAL_MODE;
            end
            else if(str_char_ptr == str_length_cnt)
            begin
                l2_nxtState = NORMAL_MODE;
            end
            else
            begin
                l2_nxtState = WAIT_FOR_CHAR;
            end
        end
        default:
        begin
            l2_nxtState = RD_DATA;
        end
    endcase
end

//================================
//  POINTERS
//================================
always @(posedge clk or posedge reset)
begin: PTRS
    if(reset)
    begin
        pattern_char_ptr<=  0;
        str_char_ptr    <=  0;
        str_frame_ptr   <=  0;
    end
    else if(state_DONE)
    begin
        pattern_char_ptr<=  0;
        str_char_ptr    <=  0;
        str_frame_ptr   <=  0;
    end
    else if(state_STR_MATCHING)
    begin
        case(l2_curState)
            NORMAL_MODE:
            begin
                if(isHat_f)
                begin
                    pattern_char_ptr <=  pattern_char_ptr;
                    str_char_ptr     <=  str_char_ptr;
                    str_frame_ptr    <=  str_frame_ptr;
                end
                else if(isDollar_f)
                begin
                    pattern_char_ptr <=  pattern_char_ptr ;
                    str_char_ptr     <=  str_char_ptr ;
                    str_frame_ptr    <=  str_frame_ptr;
                end
                else if (lastStrChar_f && star_mode_state)
                begin
                    pattern_char_ptr <=  0;
                    str_char_ptr     <=  str_frame_ptr + 1;
                    str_frame_ptr    <=  str_frame_ptr + 1;

                end
                else if(localpatternSearched_f)
                begin
                    if(star_mode_state)
                    begin
                        pattern_char_ptr <=  pattern_star_temp_ptr;
                        str_char_ptr     <=  str_frame_ptr + 1;
                        str_frame_ptr    <=  str_frame_ptr + 1;
                    end
                    else if(charMatches_f)
                    begin
                        pattern_char_ptr <=  0;
                        str_char_ptr     <=  str_frame_ptr;
                        str_frame_ptr    <=  str_frame_ptr;
                    end
                    begin
                        pattern_char_ptr <=  0;
                        str_char_ptr     <=  str_frame_ptr + 1;
                        str_frame_ptr    <=  str_frame_ptr + 1;
                    end
                end
                else if(isStar_f)
                begin
                    pattern_char_ptr <=  pattern_char_ptr+1;
                    str_char_ptr     <=  str_char_ptr ;
                    str_frame_ptr    <=  str_frame_ptr;
                end
                else if(!charMatches_f)
                begin
                    if(star_mode_state)
                    begin
                        if(lastStrChar_f)
                        begin
                            pattern_char_ptr <=  pattern_star_temp_ptr;
                            str_char_ptr     <=  str_frame_ptr + 1;
                            str_frame_ptr    <=  str_frame_ptr + 1;
                        end
                        else if(star_searched_state)
                        begin //Prevent * ,from seraching other char again
                            pattern_char_ptr <=  pattern_star_temp_ptr;
                            str_char_ptr     <=  str_char_ptr + 1;
                            str_frame_ptr    <=  str_frame_ptr;
                        end
                        else
                        begin
                            pattern_char_ptr <=  pattern_char_ptr    ;
                            str_char_ptr     <=  str_char_ptr     + 1;
                            str_frame_ptr    <=  str_frame_ptr;
                        end
                    end
                    else
                    begin
                        pattern_char_ptr <=  0;
                        str_char_ptr     <=  str_frame_ptr + 1;
                        str_frame_ptr    <=  str_frame_ptr + 1;
                    end
                end
                else
                begin
                    if(star_mode_state)
                    begin
                        pattern_char_ptr<=  charMatches_f ? pattern_char_ptr + 1 : 0;
                        str_char_ptr    <=  charMatches_f ? str_char_ptr + 1 : str_char_ptr;
                        str_frame_ptr   <=  str_frame_ptr;
                    end
                    else
                    begin
                        pattern_char_ptr<=  charMatches_f ? pattern_char_ptr + 1 : 0;
                        str_char_ptr    <=  charMatches_f ? str_char_ptr + 1 : str_frame_ptr;
                        str_frame_ptr   <=  str_frame_ptr;
                    end
                end
            end
            FIRST_OR_SPACE:
            begin
                if(firstStrChar_f)
                begin
                    pattern_char_ptr<=  pattern_char_ptr + 1;
                    str_char_ptr    <=  str_char_ptr;
                    str_frame_ptr   <=  str_frame_ptr;
                end
                else if(str_is_space_f)
                begin
                    pattern_char_ptr<=  pattern_char_ptr + 1;
                    str_char_ptr    <=  str_char_ptr + 1;
                    str_frame_ptr   <=  str_frame_ptr + 1;
                end
                else
                begin
                    pattern_char_ptr<=  0;
                    str_char_ptr    <=  str_frame_ptr + 1;
                    str_frame_ptr   <=  str_frame_ptr + 1;
                end
            end
            LAST_OR_SPACE:
            begin
                if(lastStrChar_f)
                begin
                    pattern_char_ptr <=  pattern_char_ptr;
                    str_char_ptr     <=  str_char_ptr;
                    str_frame_ptr    <=  str_frame_ptr;
                end
                else if(star_mode_state)
                begin
                    if(str_is_space_f || str_current_is_empty)
                    begin
                        pattern_char_ptr <=  0;
                        str_char_ptr     <=  str_frame_ptr;
                        str_frame_ptr    <=  str_frame_ptr;
                    end
                    else
                    begin
                        pattern_char_ptr <=  pattern_star_temp_ptr;
                        str_char_ptr     <=  str_char_ptr+ 1;
                        str_frame_ptr    <=  str_frame_ptr ;
                    end
                end
                else
                begin
                    pattern_char_ptr <=  0;
                    str_char_ptr     <=  str_frame_ptr+1;
                    str_frame_ptr    <=  str_frame_ptr+1;
                end
            end
            WAIT_FOR_CHAR:
            begin
                if(str_char_ptr == str_length_cnt)
                begin
                    pattern_char_ptr <=  0;
                    str_char_ptr     <=  str_frame_ptr +1;
                    str_frame_ptr    <=  str_frame_ptr +1;
                end
                else if(charFound_f)
                begin
                    pattern_char_ptr <=  pattern_char_ptr+1;
                    str_char_ptr     <=  str_char_ptr  +1;
                    str_frame_ptr    <=  str_frame_ptr ;
                end
                else
                begin
                    pattern_char_ptr<=  pattern_char_ptr;
                    str_char_ptr    <=  charFound_f ? str_char_ptr : str_char_ptr + 1;
                    str_frame_ptr   <=  str_frame_ptr;
                end

            end
            default:
            begin
                pattern_char_ptr<=  0;
                str_char_ptr    <=  0;
                str_frame_ptr   <=  0;
            end
        endcase
    end
    else
    begin
        pattern_char_ptr     <=  pattern_char_ptr ;
        str_char_ptr        <=  str_char_ptr ;
        str_frame_ptr       <=  str_frame_ptr ;
    end
end

always @(posedge clk or posedge reset)
begin
    if(reset)
    begin
        pattern_star_temp_ptr <= 0;
    end
    else if(state_DONE)
    begin
        pattern_star_temp_ptr <= 0;
    end
    else if(charFound_f)
    begin
        pattern_star_temp_ptr <= pattern_char_ptr-1;
    end
    else
    begin
        pattern_star_temp_ptr <= pattern_star_temp_ptr;
    end
end

always @(posedge clk or posedge reset)
begin
    if(reset)
    begin
        star_mode_state <= 0;
    end
    else if(state_DONE)
    begin
        star_mode_state <= 0;
    end
    else if(patternMatched_f)
    begin
        star_mode_state <= 0;
    end
    else if(isStar_f)
    begin
        star_mode_state <= 1;
    end
    else
    begin
        star_mode_state <= star_mode_state;
    end
end

//================================
//  Pattern_mem
//================================
always @(posedge clk or posedge reset)
begin
    if(reset)
    begin
        for(i=0;i<PATTERN_LENGTH;i=i+1)
        begin
            pattern_B_mem[i] <= pattern_B_mem[i];
        end
    end
    else if(isstring || ispattern)
    begin
        pattern_B_mem[str_length_cnt] <= pattern_B_rf[3];
    end
    else
    begin
        for(i=0;i<PATTERN_LENGTH;i=i+1)
        begin
            pattern_B_mem[i] <= pattern_B_mem[i];
        end
    end
end

//================================
//  Det Match flag
//================================
always @(*)
begin
    if(state_STR_MATCHING)
    begin
        case(l2_curState)
            NORMAL_MODE:
            begin
                charMatches_f =  isPoint_f || str_B_rf[str_char_ptr] == pattern_B_rf[pattern_char_ptr];
            end
            FIRST_OR_SPACE:
            begin
                if(firstStrChar_f)
                begin
                    charMatches_f = isPoint_f || str_B_rf[str_char_ptr] == pattern_B_rf[pattern_char_ptr];
                end
                else if(str_is_space_f)
                begin
                    charMatches_f = 1'b1;
                end
                else
                begin
                    charMatches_f = 1'b0;
                end
            end
            LAST_OR_SPACE:
            begin
                if(lastStrChar_f)
                begin
                    charMatches_f = str_current_is_empty;
                end
                else if(str_is_space_f)
                begin
                    charMatches_f = 1'b1;
                end
                else
                begin
                    charMatches_f = 1'b0;
                end
            end
            WAIT_FOR_CHAR:
            begin
                charMatches_f = str_B_rf[str_char_ptr] == pattern_B_rf[pattern_char_ptr];
            end
            default:
            begin
                charMatches_f = 1'b0;
            end
        endcase
    end
    else
    begin
        charMatches_f = 1'b0;
    end
end
//================================
//  matches cur state
//================================
always @(posedge clk)
begin
    if(reset)
    begin
        matches_cur_state <=  1'b0;
    end
    else if(state_DONE)
    begin
        matches_cur_state <=  1'b0;
    end
    else
    begin
        matches_cur_state <=  charMatches_f;
    end
end
//================================
//  searched state *
//================================
always @(posedge clk or posedge reset)
begin
    if(reset)
    begin
        star_searched_state <= 0;
    end
    else if(charFound_f && star_mode_state)
    begin
        star_searched_state <= 1;
    end
    else if(!charMatches_f)
    begin
        star_searched_state <= 0;
    end
    else
    begin
        star_searched_state <= star_searched_state;
    end
end



//================================
//  str Matching done flag
//================================
always @(*)
begin
    if(star_mode_state)
    begin
        strMatchingDone_f = star_all_permuted ? 1'b1 : 1'b0;
    end
    else if(matches_cur_state && pattern_char_ptr == (PATTERN_LENGTH))
    begin
        strMatchingDone_f = 1'b1;
    end
    else if(str_char_ptr == ((STR_LENGTH)-(pattern_length_cnt)))
    begin
        strMatchingDone_f = 1'b1;
    end
    else
    begin
        strMatchingDone_f = 1'b0;
    end
end

//================================
//  COUNTERS
//================================
always @(posedge clk or posedge reset)
begin: LEN_CNT
    if(reset)
    begin
        pattern_length_cnt <=  0;
        str_length_cnt     <=  0;
    end
    else if(state_DONE)
    begin
        pattern_length_cnt <=  ispattern ? 1 : pattern_length_cnt;
        str_length_cnt     <=  isstring  ? 1 : str_length_cnt;
    end
    else if(isstring)
    begin
        pattern_length_cnt <=  0;
        str_length_cnt     <=  str_length_cnt + 1;
    end
    else if(ispattern)
    begin
        str_length_cnt     <=  str_length_cnt;
        pattern_length_cnt <=  pattern_length_cnt+1;
    end
    else
    begin
        pattern_length_cnt <=  pattern_length_cnt;
        str_length_cnt     <=  str_length_cnt;
    end
end

//================================
//  string,pattern data storage
//================================
always @(posedge clk or posedge reset)
begin: STR_RF
    if(reset)
    begin
        for(i=0;i<STR_LENGTH;i=i+1)
        begin
            str_B_rf[i] <=  {BYTE{1'b0}};
        end
    end
    else if(state_DONE)
    begin
        for(i=1;i<STR_LENGTH;i=i+1)
        begin
            str_B_rf[i] <=  isstring ? {BYTE{1'b0}} : str_B_rf[i];
        end

        str_B_rf[0] <=  isstring ? chardata : str_B_rf[0];
    end
    else if(state_RD_DATA && isstring)
    begin
        str_B_rf[(str_length_cnt)] <=  chardata;
    end
    else
    begin
        for(i=0;i<STR_LENGTH;i=i+1)
        begin
            str_B_rf[i] <=  str_B_rf[i];
        end
    end
end

always @(posedge clk or posedge reset)
begin: PATTERN_RF
    if(reset)
    begin
        for(i=0;i<PATTERN_LENGTH;i=i+1)
        begin
            pattern_B_rf[i] <=  {BYTE{1'b0}};
        end
    end
    else if(state_DONE)
    begin
        for(i=1;i<PATTERN_LENGTH;i=i+1)
        begin
            pattern_B_rf[i] <=  {BYTE{1'b0}};
        end

        pattern_B_rf[0] <= ispattern ? chardata : 0;
    end
    else if(state_RD_DATA && ispattern)
    begin
        pattern_B_rf[(pattern_length_cnt)] <=  chardata;
    end
    else
    begin
        for(i=0;i<PATTERN_LENGTH;i=i+1)
        begin
            pattern_B_rf[i] <=  pattern_B_rf[i];
        end
    end
end

//================================
//  I/O
//================================
assign match = state_DONE && matches_cur_state;

always @(posedge clk or posedge reset)
begin
    if(reset)
    begin
        match_index <= 0;
    end
    else
    begin
        match_index <= patternMatched_f ? str_frame_ptr : match_index;
    end
end

assign valid = state_DONE;

endmodule
