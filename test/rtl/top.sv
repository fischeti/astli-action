module top (
  input  logic clk_i,
  input  logic d_i,
  output logic q_o
);
  logic spare;
  always_ff @(posedge clk_i) q_o <= d_i;
endmodule
