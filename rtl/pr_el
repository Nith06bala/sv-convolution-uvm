module pr_el(clk,in,out,state);
input logic [14:0]in;
  output logic [14:0] out;
logic [14:0]in1;
input logic clk;
input logic [1:0]state;


always_comb begin
if(state==2'b10)begin
out=in*in1;
end

end
always_ff @(posedge clk)begin
in1<=in;
end
endmodule
