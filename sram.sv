module sram(rd_en,din,addr,dout,clk,state);
  logic [14:0]mem[0:63];
input logic clk,rd_en;

input logic [1:0]state;
  input logic [14:0]din,addr;
output logic [6:0]dout;

always_ff @(posedge clk)begin
mem[0]  = 7'd0;
mem[1]  = 7'd1;
mem[2]  = 7'd2;
mem[3]  = 7'd3;
mem[4]  = 7'd4;
mem[5]  = 7'd5;
mem[6]  = 7'd6;
mem[7]  = 7'd7;
mem[8]  = 7'd8;
mem[9]  = 7'd9;
mem[10] = 7'd10;
mem[11] = 7'd11;
mem[12] = 7'd12;
mem[13] = 7'd13;
mem[14] = 7'd14;
mem[15] = 7'd15;
mem[16] = 7'd16;
mem[17] = 7'd17;
mem[18] = 7'd18;
mem[19] = 7'd19;
mem[20] = 7'd20;
mem[21] = 7'd21;
mem[22] = 7'd22;
mem[23] = 7'd23;
mem[24] = 7'd24;
mem[25] = 7'd25;
mem[26] = 7'd26;
mem[27] = 7'd27;
mem[28] = 7'd28;
mem[29] = 7'd29;
mem[30] = 7'd30;
mem[31] = 7'd31;

  if(rd_en==1'b1 /*&& state==2'b01*/ ) begin
dout<=mem[addr];
end
  else if(rd_en==1'b0 /*&& state==2'b11*/ )begin
mem[addr+31]<=din;
  $display("value at %d is %d",addr+30,mem[addr+30]);
end
end
endmodule
