`ifndef PE_SBTX_COVERAGE_SVH
`define PE_SBTX_COVERAGE_SVH

// 1. Declare unique suffixes for each analysis imp port OUTSIDE the class
`uvm_analysis_imp_decl(_d2d)
`uvm_analysis_imp_decl(_phy)

class pe_sbtx_coverage extends uvm_component;
  `uvm_component_utils(pe_sbtx_coverage)

  // 2. Instantiate one analysis implementation port per connected agent
  uvm_analysis_imp_d2d#(pe_sbtx_D2D_sequence_item, pe_sbtx_coverage) d2d_imp;
  uvm_analysis_imp_phy#(pe_sbtx_PHY_sequence_item, pe_sbtx_coverage) phy_imp;

  // Local handles to hold the latest transactions for sampling
  pe_sbtx_D2D_sequence_item d2d_item;
  pe_sbtx_PHY_sequence_item phy_item;

  // Synchronization flags so sampling occurs once per clock cycle after all monitors write
  bit d2d_valid;
  bit phy_valid;

  // TODO: Shadow state / helper variables for temporal scenarios

  // ===========================================================================
  // D2D interface coverage (generic, one coverpoint per signal)
  // TODO: replace / extend with scenario covergroups (iff gates, crosses, transitions)
  // ===========================================================================
  covergroup cg_d2d;
    option.per_instance = 1;

    cp_rst_n: coverpoint d2d_item.rst_n;
    cp_en: coverpoint d2d_item.en;
    cp_data_marker: coverpoint d2d_item.data_marker;
    cp_comp_marker: coverpoint d2d_item.comp_marker;
    cp_data: coverpoint d2d_item.data {
      option.auto_bin_max = 16;
    }
    cp_resend_req: coverpoint d2d_item.resend_req;
  endgroup

  // ===========================================================================
  // PHY interface coverage (generic, one coverpoint per signal)
  // TODO: replace / extend with scenario covergroups (iff gates, crosses, transitions)
  // ===========================================================================
  covergroup cg_phy;
    option.per_instance = 1;

    cp_rst_n: coverpoint phy_item.rst_n;
    cp_en: coverpoint phy_item.en;
    cp_data_marker: coverpoint phy_item.data_marker;
    cp_comp_marker: coverpoint phy_item.comp_marker;
    cp_data: coverpoint phy_item.data {
      option.auto_bin_max = 16;
    }
    cp_resend_req: coverpoint phy_item.resend_req;
  endgroup

  // ===========================================================================
  // Constructor & Build Phase
  // ===========================================================================
  function new(string name = "pe_sbtx_coverage", uvm_component parent = null);
    super.new(name, parent);
    cg_d2d = new();
    cg_phy = new();
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    d2d_imp = new("d2d_imp", this);
    phy_imp = new("phy_imp", this);
    d2d_item = pe_sbtx_D2D_sequence_item::type_id::create("d2d_item");
    phy_item = pe_sbtx_PHY_sequence_item::type_id::create("phy_item");
  endfunction

  // ===========================================================================
  // Monitor Write Callbacks & Cycle-Aligned Sampling
  // ===========================================================================
  virtual function void write_d2d(pe_sbtx_D2D_sequence_item t);
    d2d_item = t;
    d2d_valid = 1'b1;
    if (all_valid()) sample_and_advance();
  endfunction

  virtual function void write_phy(pe_sbtx_PHY_sequence_item t);
    phy_item = t;
    phy_valid = 1'b1;
    if (all_valid()) sample_and_advance();
  endfunction

  // True once every connected monitor has written its item for the current cycle
  virtual function bit all_valid();
    return d2d_valid && phy_valid;
  endfunction

  // Samples all covergroups for the current clock edge, then advances the shadow state
  virtual function void sample_and_advance();
    d2d_valid = 1'b0;
    phy_valid = 1'b0;

    // 1. Sample all covergroups using the current cycle items
    cg_d2d.sample();
    cg_phy.sample();

    // 2. Advance shadow state for the next cycle
    update_state();
  endfunction

  virtual function void update_state();
    // TODO: Update shadow state variables used by temporal coverage
  endfunction
endclass

`endif // PE_SBTX_COVERAGE_SVH
