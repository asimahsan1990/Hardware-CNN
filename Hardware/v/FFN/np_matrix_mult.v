module np_matrix_mult(
  input clock,
  input reset,
 
   
  input [`FFN_IN_BITWIDTH:0] feature_pixel,
  input [`FFN_IN_BITWIDTH:0] weight,

//  input [`NUM_MM_BUFFER-1:0] frame_rdy, assume frame is ready
  output reg [`NUM_MM_BUFFER-1:0] reading_frame, // a vector of boolean signals. one signal per frame/feature buffer

  output reg [`FFN_OUT_BIRWIDTH:0] sum,
  output reg d_val

  output [`NP_COUNT_BITWIDTH:0] buf_addr
);

// parameter declaration

// wire declaration
wire [`NP_MM_OUT_BITWIDTH:0] sum_prelatch;

// reg declaration
reg [`NP_COUNT_BITWIDTH:0] count;

// assign statments
assign buf_addr = count;

// instantiate multiplyer
// there should be no registers in mult module
lpm_mult_np_mm mult_inst(
  .clock(clock),
  .reset(reset),
  .operand_a(feature_pixel),
  .operand_b(weight),
  .product(product)
);

// instantiate adder with feedback
// there should be no registers in adder
lpm_add_np_mm add_inst(
  .clock(clock), 
  .reset(reset),
  .operand_a(product),
  .operand_b(sum),
  .sum(sum_prelatch)
);

// counter and data valid logic
always@(posedge clock or negedge reset) begin
  if( reset == 1'b0) begin
    d_val <= 1'd0;
    count <= `NP_COUNT_WIDTH'd0;
    sum <= `NP_MM_OUT_WIDTH'd0;
  end else if( count == `NP_COUNT_WIDTH'd`NP_MAX_COUNT) begin
    d_val <= 1'd1;
    count <= `NP_COUNT_WIDTH'd0;
    sum <= `NP_MM_OUT_WIDTH'd0; 
  end else begin 
    d_val <= 1'd0;
    count <= count + `NP_COUNT_WIDTH'd1;
    sum <= sum_prelatch; // output current sum
  end
end // always

// buffer select logic
always@(posedge clock or negedge reset) begin
  if(reset == 1'b0) begin
    reading_frame <= `NUM_MM_BUFFER'd1; // always start reading first frame buffer
  end else if( count == `NP_COUNT_WIDTH'd`NP_MAX_COUNT) begin
    reading_frame <= { reading_frame[`NUM_MM_BUFFER-2:0], reading_frame[`NUM_MM_BUFFER-1] };
  end 
end // always
