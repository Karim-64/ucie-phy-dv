import Universal_pkg ::* ; 

module Controller_SB_Top #( parameter NC=32,
                            parameter DATA_WIDTH=64,
                            parameter NUM_LANES=16)
(top_if SR_IF);



//--------------------------------------------------------------//


//Inistantiate SB_TOP
SB_TOP #(.NC(NC),.DATA_WIDTH(DATA_WIDTH)) SB_TOP_U0 ( SR_IF );


//Inistantiate Controller
Controller_TOP #(.DATA_WIDTH_TOP(DATA_WIDTH),.ADDR_WIDTH_TOP(ADDR_LENGTH)) Controller_TOP_U0 (SR_IF);


endmodule 
