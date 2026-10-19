import Universal_pkg ::* ; 

module SB_TOP #( parameter NC =32,
                 parameter DATA_WIDTH=64)
(top_if  SB_IF );


//-------------------------------------------------//


//Inistantiate SB_RX
SB_RX_TOP #(
	.DATA_WIDTH(DATA_WIDTH),
	.FIFO_DEPTH(32),
	.CHUNK_WIDTH(NC))  SB_RX_TOP_U0 
(SB_IF);

//Inistantiate SB_TX

SB_TX_Top #(
    .NC(NC),
    .FIFO_DEPTH(64),
    .DATA_WIDTH(DATA_WIDTH)) SB_TX_Top_U0
(SB_IF);


endmodule 
