module cu(  input [7:0] ir,
            input [3:0] slow,/*������*/
            input quick,
            output reg[14:0] op);
/**
 * 14:11 ALU
 * 10:7 A B
 * 6:2 register 
 * 1:0 W R
 */
always@(slow,quick)begin
    if(quick == 1'b1)begin
        case(slow)
                        4'b1000: op <= 15'b000100100000100;
                        4'b0100: op <= 15'b001000100010000;
                        4'b0010: op <= 15'b000010000001001;
                        4'b0001: op <= 15'b111100000000000;
        endcase
    end else begin
        case(ir)
        8'b00000110: begin
                    case(slow)
                        4'b1000: op <= 15'b000100100000100;
                        4'b0100: op <= 15'b000010000100001;
                        4'b0010: op <= 15'b001000100010000;
                        4'b0001: op <= 15'b111100000000000;
                    endcase
                end
    8'b00000010: begin
                    case(slow)
                        4'b1000: op <= 15'b000100100000100;
                        4'b0100: op <= 15'b000010001000001;
                        4'b0010: op <= 15'b001000100010000;
                        4'b0001: op <= 15'b111100000000000;
                    endcase
                end
    8'b00001101: begin
                    case(slow)
                        4'b1000: op <= 15'b000100100000100;
                        4'b0100: op <= 15'b000010100000101;
                        4'b0010: op <= 15'b000100010000010;
                        4'b0001: op <= 15'b001000100010000;
                    endcase
                end
    8'b00010100: begin
                    case(slow)
                        4'b1000: op <= 15'b111100000000000;
                        4'b0100: op <= 15'b001101010100000;
                        4'b0010: op <= 15'b111100000000000;
                        4'b0001: op <= 15'b111100000000000;
                    endcase
                end
    8'b00100100: begin
                    case(slow)
                        4'b1000: op <= 15'b111100000000000;
                        4'b0100: op <= 15'b010001010100000;
                        4'b0010: op <= 15'b111100000000000;
                        4'b0001: op <= 15'b111100000000000;
                    endcase
                end
    8'b00110100: begin
                    case(slow)
                        4'b1000: op <= 15'b111100000000000;
                        4'b0100: op <= 15'b010101010100000;
                        4'b0010: op <= 15'b111100000000000;
                        4'b0001: op <= 15'b111100000000000;
                    endcase
                end
    8'b01000100: begin
                    case(slow)
                        4'b1000: op <= 15'b111100000000000;
                        4'b0100: op <= 15'b011001000100000;
                        4'b0010: op <= 15'b111100000000000;
                        4'b0001: op <= 15'b111100000000000;
                    endcase
                end
    8'b01010100: begin
                    case(slow)
                        4'b1000: op <= 15'b111100000000000;
                        4'b0100: op <= 15'b011101000100000;
                        4'b0010: op <= 15'b111100000000000;
                        4'b0001: op <= 15'b111100000000000;
                    endcase
                end
    8'b01100100: begin
                    case(slow)
                        4'b1000: op <= 15'b111100000000000;
                        4'b0100: op <= 15'b100001010100000;
                        4'b0010: op <= 15'b111100000000000;
                        4'b0001: op <= 15'b111100000000000;
                    endcase
                end
    8'b01110100: begin
                    case(slow)
                        4'b1000: op <= 15'b111100000000000;
                        4'b0100: op <= 15'b100101010100000;
                        4'b0010: op <= 15'b111100000000000;
                        4'b0001: op <= 15'b111100000000000;
                    endcase
                end
    8'b10000100: begin
                    case(slow)
                        4'b1000: op <= 15'b111100000000000;
                        4'b0100: op <= 15'b101001000100000;
                        4'b0010: op <= 15'b111100000000000;
                        4'b0001: op <= 15'b111100000000000;
                    endcase
                end
    8'b10010100: begin
                    case(slow)
                        4'b1000: op <= 15'b111100000000000;
                        4'b0100: op <= 15'b101101010100000;
                        4'b0010: op <= 15'b111100000000000;
                        4'b0001: op <= 15'b111100000000000;
                    endcase
                end
    8'b10100100: begin
                    case(slow)
                        4'b1000: op <= 15'b111100000000000;
                        4'b0100: op <= 15'b110001010100000;
                        4'b0010: op <= 15'b111100000000000;
                        4'b0001: op <= 15'b111100000000000;
                    endcase
                end
    8'b11111111: begin
                    case(slow)
                        4'b1000: op <= 15'b111100000000000;
                        4'b0100: op <= 15'b110100100010000;
                        4'b0010: op <= 15'b111100000000000;
                        4'b0001: op <= 15'b111100000000000;
                    endcase
                end
        endcase
    end
end
endmodule