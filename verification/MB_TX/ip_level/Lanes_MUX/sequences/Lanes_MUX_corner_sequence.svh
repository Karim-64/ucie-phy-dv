`ifndef LANES_MUX_CORNER_SEQUENCE_SVH
`define LANES_MUX_CORNER_SEQUENCE_SVH

class Lanes_MUX_corner_sequence extends uvm_sequence #(Lanes_MUX_sequence_item);
  `uvm_object_utils(Lanes_MUX_corner_sequence)
  `uvm_declare_p_sequencer(Lanes_MUX_sequencer)


    // Corner-case patterns
  bit [7:0] corner_cases [] = '{
    8'h00,  // All zeros
    8'hFF,  // All ones
    8'h01,  // LSB only
    8'hFE,  // All ones except LSB
    8'h80,  // MSB only
    8'h7F,  // All ones except MSB
    8'h55,  // Alternating 01010101
    8'hAA   // Alternating 10101010
  };

   // Walking-one patterns: exactly one bit is 1
  bit [7:0] walking_ones [0:7];

  // Walking-zero patterns: exactly one bit is 0
  bit [7:0] walking_zeros [0:7];

  function new(string name = "Lanes_MUX_corner_sequence");
    super.new(name);

    foreach (walking_ones[i]) begin
        walking_ones[i]  = 8'b0000_0001 << i;
        walking_zeros[i] = ~(8'b0000_0001 << i);
    end
  endfunction

  task body();
    // TODO: Implement sequence body
    Lanes_MUX_sequence_item req;
    foreach (corner_cases[i]) begin
      foreach (corner_cases[j]) begin
        for (int sel = 0; sel <= 1; sel++) begin
          req = Lanes_MUX_sequence_item::type_id::create("req");
          start_item(req);
          assert(req.randomize() with {
            foreach (IN_0[k]){
              IN_0[k] inside {corner_cases};
              IN_1[k] inside {corner_cases};
              if (k > 0) {
                IN_0 [k] != IN_0 [k-1];
                IN_1 [k] != IN_1 [k-1];
              }
            }
            SEL_2 == sel[0];
          });
          finish_item(req);
          p_sequencer.seqr_aport.write(req);
        end
      end
    end

    foreach (walking_ones[i]) begin
      foreach (walking_ones[j]) begin
        for (int sel = 0; sel <= 1; sel++) begin
          req = Lanes_MUX_sequence_item::type_id::create("req");
          start_item(req);
          assert(req.randomize() with {
            foreach (IN_0[k]){
              IN_0[k] == walking_ones[i];
              IN_1[k] == walking_ones[j];
            }
            SEL_2 == sel[0];
          });
          finish_item(req);
          p_sequencer.seqr_aport.write(req);
        end
      end
    end


    foreach (walking_zeros[i]) begin
      foreach (walking_zeros[j]) begin
        for (int sel = 0; sel <= 1; sel++) begin
          req = Lanes_MUX_sequence_item::type_id::create("req");
          start_item(req);
          assert(req.randomize() with {
            foreach (IN_0[k]){
              IN_0[k] == walking_zeros[i];
              IN_1[k] == walking_zeros[j];
            }
            SEL_2 == sel[0];
          });
          finish_item(req);
          p_sequencer.seqr_aport.write(req);
        end
      end
    end
  endtask
endclass

`endif // LANES_MUX_corner_SEQUENCE_SVH
