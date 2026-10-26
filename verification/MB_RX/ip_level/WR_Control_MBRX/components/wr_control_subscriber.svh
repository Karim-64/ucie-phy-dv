
`ifndef WR_CONTROL_COVERAGE_SVH
`define WR_CONTROL_COVERAGE_SVH

class wr_control_subscriber extends uvm_subscriber #(wr_control_sequence_item);
  `uvm_component_utils(wr_control_subscriber)

  wr_control_sequence_item item;

  covergroup wr_control_cg;
    option.per_instance = 1;
    option.comment = "Functional Coverage for MBRX Write Control";

    // Reset coverage
    cp_reset: coverpoint item.R_RST_n {
      bins active         = {0};
      bins inactive       = {1};
      bins transition_0_1 = (0 => 1);
      bins transition_1_0 = (1 => 0);
    }

    // Width degrade mode coverage
    cp_width_degrade: coverpoint item.Width_Degrade {
      bins full_width     = {3'b011};
      bins degraded_lower = {3'b001};
      bins degraded_upper = {3'b010};
      bins illegal_codes  = {3'b000, [3'b100:3'b111]};
      bins trans1[]       = (3'b011, 3'b010, 3'b001 => 3'b001);
      bins trans2[]       = (3'b011, 3'b010, 3'b001 => 3'b010);
      bins trans3[]       = (3'b011, 3'b010, 3'b001 => 3'b011);
    }

    // General enable coverage
    cp_en: coverpoint item.EN {
      bins disabled     = {0};
      bins enabled      = {1};
      bins continuous   = (1[*3]);
      bins transaction  = (1 => 0 => 1);
    }

    // Deserialization done coverage
    cp_deser_done: coverpoint item.Deser_Done {
      bins not_done     = {0};
      bins done         = {1};
      bins continuous   = (1[*3]);
      bins transaction  = (1 => 0 => 1);
    }
    
    cp_Width_degrade_update: coverpoint item.Width_Degrade_Update {
      bins no_update = {0};
      bins update    = {1};
      bins trans1    = (1 => 0[*2]);
      bins trans2    = (1[*2]); 
    }

    cp_wrn: coverpoint item.WR_EN {
      bins no_write   = {0};
      bins write      = {1};
    }

    // Width mode / enable / completion interaction
    cross_mode_handshake: cross cp_width_degrade, cp_en, cp_deser_done {
      ignore_bins ignore_transitions_wd =
          binsof(cp_width_degrade.trans1) ||
          binsof(cp_width_degrade.trans2) ||
          binsof(cp_width_degrade.trans3);

      ignore_bins ignore_transitions_en =
          binsof(cp_en.continuous) || binsof(cp_en.transaction);
      
      ignore_bins ignore_transitions_deser_done =
          binsof(cp_deser_done.continuous) || binsof(cp_deser_done.transaction);
    }

    cross_width_update_with_widths: cross cp_Width_degrade_update, cp_width_degrade{
      ignore_bins ignore_transitions_wd =
          binsof(cp_width_degrade.trans1) ||
          binsof(cp_width_degrade.trans2) ||
          binsof(cp_width_degrade.trans3);
        
      ignore_bins ignore_transitions_wdup =
          binsof(cp_Width_degrade_update.trans1) ||
          binsof(cp_Width_degrade_update.trans2);
    }

    cross_rst_while_width_update: cross cp_reset, cp_Width_degrade_update{
      ignore_bins ignore_transitions_wdup =
          binsof(cp_Width_degrade_update.trans1) ||
          binsof(cp_Width_degrade_update.trans2);

      ignore_bins ignore_transitions_rst =
          binsof(cp_reset.transition_0_1) ||
          binsof(cp_reset.transition_1_0);
    }
  endgroup

  function new(string name = "wr_control_subscriber",
               uvm_component parent = null);
    super.new(name, parent);
    wr_control_cg = new();
  endfunction

  function void write(wr_control_sequence_item t);
    if (t == null) begin
      `uvm_error(get_type_name(), "Received null transaction")
      return;
    end

    item = t;
    wr_control_cg.sample();
  endfunction

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);

    `uvm_info(
      get_type_name(),
      $sformatf("Functional Coverage: %.2f%%",
                wr_control_cg.get_inst_coverage()),
      UVM_LOW
    )
  endfunction

endclass

`endif
