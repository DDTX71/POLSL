// Perforemd by: Najda Dawid
//
// Task 2. Design an overflow detector by copping your frequency meter to prepared t2.v file. 
// Here you will find module declaration including OVF (Overflow output). The overflow signal 
// should be treated lie other measurement results and should be passed through the latch register
// to retain the result value for displaying it for user.
//

`timescale 1ns/100ps

module FM_OVF(CLK, CLR, F_IN, QH, QD, QU, OVF, nDONE);
input CLK;  //Reference clock
input CLR; //Frequency meter clear signal
input F_IN; //Measured frequency 
output [3:0] QH, QD, QU; //Measurement result
output OVF; //Resoult overflow notification
output nDONE; //Notification about completing measurement process

//Control unit
wire [3:0] Q_CTRL;
wire [7:0] nCTRL;
wire DUMMY_0, DUMMY_1;
wire GATE_EN, GATE_NEN; //Gate
wire G_F_IN; //Gated F_IN
wire CNT_CLR, nCNT_CLR; //Counter clear
wire LD; //Load latch
wire nCLR, nR, R;
wire Q_OVF;
//Counters and latches
wire [3:0] QC_H, QC_D, QC_U;

//Control unit
not  #2 (nCLR, CLR);

nand #2 (G_F_IN, GATE_EN, F_IN); //Input signal gate
SN7493 CTRL_CNT1(.CLK(CLK), .R0(CLR), .Q(Q_CTRL));
SN7442 CTRL_DEC1(.Y({DUMMY_1, DUMMY_0, nCTRL}), .I({1'b0, Q_CTRL[3:1]}));

nand #2 (R, nCTRL[5], nCLR);
not  #2 (nR, R);
SN7474 CTRL_G_CTRL(.CLK(1'b0), .nS(nCTRL[0]), .nR(nR), .Q(GATE_EN), .nQ());
SN7474 CTRL_LD_CTRL(.CLK(CLK), .nS(1'b1), .nR(1'b1), .D(nCTRL[5]), .Q(LD), .nQ());


nand #2 (CNT_CLR, nCTRL[7], nCLR);
not  #2 (nCNT_CLR, CNT_CLR);
assign #2 nDONE = nCTRL[7]; //End of measurement notification

//Counter
SN7490 C1(.CLK(G_F_IN),  .R0(CNT_CLR), .R9(1'b0), .Q(QC_U));
SN7490 C2(.CLK(QC_U[3]), .R0(CNT_CLR), .R9(1'b0), .Q(QC_D));
SN7490 C3(.CLK(QC_D[3]), .R0(CNT_CLR), .R9(1'b0), .Q(QC_H));
SN7474 O4(.CLK(QC_H[3]), .nS(1'b1), .nR(nCNT_CLR), .D(1'b1), .Q(Q_OVF), .nQ());

//Latch
SN7474_4 L1(.CLK(LD), .nCLR(1'b1), .D(QC_U), .Q(QU));
SN7474_4 L2(.CLK(LD), .nCLR(1'b1), .D(QC_D), .Q(QD));
SN7474_4 L3(.CLK(LD), .nCLR(1'b1), .D(QC_H), .Q(QH));
SN7474   L4(.CLK(LD), .nS(1'b1), .nR(1'b1), .D(Q_OVF), .Q(OVF));


endmodule


module T2_TEST;
reg CLK;  //Reference clock
reg CLR;
wire F_IN; //Measured frequency 
output [3:0] QH, QD, QU; //Measurement result
wire OVF;
wire nDONE;
reg [31:0] F_SET;

FM_OVF UUT(
    .CLK(CLK), .CLR(CLR), 
    .F_IN(F_IN), 
    .QH(QH), .QD(QD), .QU(QU), .OVF(OVF) ,
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

always @(negedge nDONE)
    $display("Measured frequency : %b : %d%d%d ", OVF, QH, QD, QU);

initial begin
    CLK = 1'b0;
    forever begin
        #50_000 CLK = ~CLK;
    end
end

initial begin
    $dumpfile("t2.vcd");
    $dumpvars;
    $dumpon;
end

endmodule
