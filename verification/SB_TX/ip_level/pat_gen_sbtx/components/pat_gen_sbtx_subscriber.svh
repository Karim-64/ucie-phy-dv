`ifndef PAT_GEN_SBTX_SUBSCRIBER_SVH
`define PAT_GEN_SBTX_SUBSCRIBER_SVH

class pat_gen_sbtx_subscriber extends uvm_subscriber #(pat_gen_sbtx_sequence_item);
  `uvm_component_utils(pat_gen_sbtx_subscriber)

  pat_gen_sbtx_sequence_item item;

  covergroup pat_gen_cg;
    option.per_instance = 1;
    option.comment = "Functional Coverage for SBTX Pattern Generator";

    // 1. Reset Coverage (Maps to rst_seq)
    cp_rst_n: coverpoint item.RST_n {
      bins active          = {0};
      bins inactive        = {1};
      bins assert_deassert = (1 => 0 => 1);
    }

    // 2. Enable Signal Coverage (Maps to base_seq & error_injec_seq)
    cp_en: coverpoint item.Patt_Gen_En {
      bins disabled = {0};
      bins enabled  = {1};
      bins turn_on  = (0 => 1);
      bins turn_off = (1 => 0);
    }

    // 3. Output start_64 Flag
    cp_start_64: coverpoint item.start_64 {
      bins low  = {0};
      bins high = {1};
    }

    // 4. Output Data Pattern (Maps to alternating 1, 0, 1, 0 verification)
    cp_sbtx_data: coverpoint item.SBTX_DATA {
      bins zero = {0};
      bins one  = {1};
      bins toggle_01 = (0 => 1);
      bins toggle_10 = (1 => 0);
    }

    // 5. Cross Coverage: Reset during active generation (Maps to error_injec_seq)
    cross_rst_active: cross cp_rst_n, cp_en {
      // Specifically target bins where reset is asserted (RST_n==0) while Enable is high (Patt_Gen_En==1)
      bins idle_reset = binsof(cp_en.disabled);
    }

  endgroup

  function new(string name = "pat_gen_sbtx_subscriber", uvm_component parent = null);
    super.new(name, parent);
    pat_gen_cg = new();
  endfunction

  function void write(pat_gen_sbtx_sequence_item t);
    if (!$cast(item, t)) begin
      `uvm_error(get_type_name(), "Cast failed in coverage subscriber")
      return;
    end
    pat_gen_cg.sample();
  endfunction

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info(get_type_name(), $sformatf("SBTX Pattern Gen Coverage: %.2f%%", pat_gen_cg.get_inst_coverage()), UVM_NONE)
  endfunction
endclass

`endif // PAT_GEN_SBTX_SUBSCRIBER_SVH