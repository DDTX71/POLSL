// Perforemd by: Najda Dawid
//
// Task 1. Design a simple frequency meter control unit using the prepared framework. 
// The unit should operate in a closed-loop consisting of opening the gate for a period 
// of 10 clock cycles next generating the sequence of the latch and clear pulses.
// You can observe that for your disposal are only 8 decoder outputs. To achieve 
// the required control scheme the gate is turned on by state 0 and turned of by state 5, 
// latch pulse is generated by output 6 of the decoder finally, the clear pulse is generated 
// by output 7. After that cycle starts over. 
// Is the measured result correct? 
// Is the result retained continuously until the next cycle finishes?
//

`timescale 1ns/100ps

module FM(CLK, CLR, F_IN, QH, QD, QU, nDONE);
input CLK;  //Reference clock
input CLR; //Frequency meter clear signal
input F_IN; //Measured frequency 
output [3:0] QH, QD, QU; //Measurement result
output nDONE; //Notification about completing measurement process

//Control unit
wire [3:0] Q_CTRL;
wire [7:0] nCTRL;
wire DUMMY_0, DUMMY_1;
wire GATE_EN, GATE_NEN; //Gate
wire G_F_IN; //Gated F_IN
wire CNT_CLR; //Counter clear
wire LD; //Load latch

//Counters and latches
wire [3:0] QC_H, QC_D, QC_U;

//Control unit
nand #2(G_F_IN, GATE_EN, F_IN); //Input signal gate
SN7493 CTRL_CNT1(.CLK(CLK), .R0(CLR), .Q(Q_CTRL));
SN7442 CTRL_DEC1(.Y({DUMMY_1, DUMMY_0, nCTRL}), .I({1'b0, Q_CTRL[3:1]}));

//Possibly this help you to generate GATE_EN'

SN7474 CTRL_G_CTRL(.CLK(1'b0), .nS(nCTRL[0]), .nR(nCTRL[5] & ~CLR), .Q(GATE_EN), .nQ());
//Generate LD and CNT_CLR note required signals polarity
not #2 N1 (LD, nCTRL[6]);

assign CNT_CLR = ~nCTRL[7] | CLR;
assign nDONE = nCTRL[7]; //End of measurement notification

//Counter
SN7490 C1(.CLK(G_F_IN),  .R0(CNT_CLR), .R9(1'b0), .Q(QC_U));
SN7490 C2(.CLK(QC_U[3]), .R0(CNT_CLR), .R9(1'b0), .Q(QC_D));
SN7490 C3(.CLK(QC_D[3]), .R0(CNT_CLR), .R9(1'b0), .Q(QC_H));
//Latch
SN7474_4 L1(.CLK(LD), .nCLR(1'b1), .D(QC_U), .Q(QU));
SN7474_4 L2(.CLK(LD), .nCLR(1'b1), .D(QC_D), .Q(QD));
SN7474_4 L3(.CLK(LD), .nCLR(1'b1), .D(QC_H), .Q(QH));

endmodule


module T1_TEST;
reg CLK;  //Reference clock
reg CLR;
wire F_IN; //Measured frequency 
output [3:0] QH, QD, QU; //Measurement result
wire nDONE;
reg [31:0] F_SET;

FM UUT(
    .CLK(CLK), .CLR(CLR), 
    .F_IN(F_IN), 
    .QH(QH), .QD(QD), .QU(QU), 
    .nDONE(nDONE));

FREQ_GEN FG(.CLK(F_IN), .F(F_SET));

initial begin
    F_SET = 32'd145;
    CLR = 1'b1;
    repeat(2) @(posedge CLK);
    CLR = 1'b0;
    repeat(3) @(negedge nDONE);
    F_SET = 32'd1045;
    repeat(2) @(negedge nDONE);    
    repeat(3) @(posedge CLK);
    $finish;
end

always @(posedge nDONE)
    $display("Measured frequency : %d%d%d ", QH, QD, QU);

initial begin
    CLK = 1'b0;
    forever begin
        #50_000 CLK = ~CLK;
    end
end

initial begin
    $dumpfile("t1.vcd");
    $dumpvars;
    $dumpon;
end

endmodule
