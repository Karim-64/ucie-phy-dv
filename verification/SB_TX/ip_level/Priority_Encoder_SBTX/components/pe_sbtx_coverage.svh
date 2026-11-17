`ifndef PE_SBTX_COVERAGE_SVH
`define PE_SBTX_COVERAGE_SVH

// 1. Declare unique suffixes for each analysis imp port OUTSIDE the class
`uvm_analysis_imp_decl(_phy)
`uvm_analysis_imp_decl(_d2d)

class pe_sbtx_coverage extends uvm_component;
  `uvm_component_utils(pe_sbtx_coverage)
  
  // 2. Instantiate the two analysis implementation ports
  uvm_analysis_imp_phy#(pe_sbtx_PHY_sequence_item, pe_sbtx_coverage) phy_imp;
  uvm_analysis_imp_d2d#(pe_sbtx_D2D_sequence_item, pe_sbtx_coverage) d2d_imp;
  
  // Local handles to hold the latest transactions for sampling
  pe_sbtx_PHY_sequence_item phy_item;
  pe_sbtx_D2D_sequence_item d2d_item;
  
  // Synchronization flags so sampling occurs once per clock cycle after both monitors write
  bit phy_valid;
  bit d2d_valid;
  
  // Shadow state types matching Priority_Encoder_SBTX.sv
  typedef enum logic[1:0] {
    REQ_NONE = 2'b00, REQ_D2D_ONLY = 2'b01, REQ_PHY_ONLY = 2'b10, REQ_BOTH_ACTIVE = 2'b11} req_state_e;
  
  typedef enum logic[2:0] {
    LOCK_IDLE = 3'd0,
    D2D_LOCK_CYC1 = 3'd1, // Header phase in FIFO (Priority_Lock=1, Lock_Counter=0)
    D2D_LOCK_CYC2 = 3'd2, // Data phase in FIFO   (Priority_Lock=1, Lock_Counter=1)
    PHY_LOCK_CYC1 = 3'd3, // Header phase in FIFO (Priority_Lock=1, Lock_Counter=0)
    PHY_LOCK_CYC2 = 3'd4 // Data phase in FIFO   (Priority_Lock=1, Lock_Counter=1)
  } lock_phase_e;
  
  // Helper state variables for temporal scenarios (Scenarios 3, 5, 6, 7, 8)
  req_state_e curr_req;
  lock_phase_e lock_phase;
  bit post_lock_bubble; // High on the 1-cycle cooldown after CYC2 unlock
  bit phy_retry_pending; // Set when PHY is rejected; cleared when PHY wins
  bit d2d_retry_pending; // Set when D2D is rejected; cleared when D2D wins
  bit mid_lock_rst_seen; // Set when RST_n=0 occurs during an active lock
  
  // ===========================================================================
  // SCENARIOS 1 & 2: Normal Sanity & Simultaneous Contention (Unlocked)
  // ===========================================================================
  covergroup cg_scen1_2_sanity_and_contention;
    option.per_instance = 1;
    
    cp_req: coverpoint curr_req iff (phy_item.rst_n && lock_phase == LOCK_IDLE) {
      bins idle = {REQ_NONE};
      bins d2d_only = {REQ_D2D_ONLY};
      bins phy_only = {REQ_PHY_ONLY};
      bins both_active = {REQ_BOTH_ACTIVE};
    }
    
    cp_phy_dm: coverpoint phy_item.data_marker iff (phy_item.rst_n && lock_phase == LOCK_IDLE) {
      bins single_phase = {1'b0};
      bins two_phase = {1'b1};
    }
    
    cp_d2d_dm: coverpoint d2d_item.data_marker iff (phy_item.rst_n && lock_phase == LOCK_IDLE) {
      bins single_phase = {1'b0};
      bins two_phase = {1'b1};
    }
    
    // Scenario 1: Uncontended 1-phase and 2-phase requests for D2D and PHY
    cx_scen1_sanity: cross cp_req, cp_phy_dm, cp_d2d_dm {
      bins d2d_1phase = binsof(cp_req.d2d_only) && binsof(cp_d2d_dm.single_phase);
      bins d2d_2phase = binsof(cp_req.d2d_only) && binsof(cp_d2d_dm.two_phase);
      bins phy_1phase = binsof(cp_req.phy_only) && binsof(cp_phy_dm.single_phase);
      bins phy_2phase = binsof(cp_req.phy_only) && binsof(cp_phy_dm.two_phase);
      ignore_bins others = binsof(cp_req.idle) || binsof(cp_req.both_active);
    }
    
    // Scenario 2: Simultaneous contention (BOTH_ACTIVE) across all Data_Marker combinations
    cx_scen2_contention: cross cp_req, cp_phy_dm, cp_d2d_dm {
      bins both_active_all_dm = binsof(cp_req.both_active);
      ignore_bins non_contended = !binsof(cp_req.both_active);
    }
  endgroup
  
  // ===========================================================================
  // SCENARIOS 3 & 7: Mid-Message Locking & BOTH_ACTIVE During Lock
  // ===========================================================================
  covergroup cg_scen3_7_mid_lock_contention;
    option.per_instance = 1;
    
    cp_lock_phase: coverpoint lock_phase iff (phy_item.rst_n && lock_phase != LOCK_IDLE) {
      bins d2d_cyc1 = {D2D_LOCK_CYC1};
      bins d2d_cyc2 = {D2D_LOCK_CYC2};
      bins phy_cyc1 = {PHY_LOCK_CYC1};
      bins phy_cyc2 = {PHY_LOCK_CYC2};
    }
    
    cp_req_in_lock: coverpoint curr_req iff (phy_item.rst_n && lock_phase != LOCK_IDLE) {
      bins d2d_only = {REQ_D2D_ONLY};
      bins phy_only = {REQ_PHY_ONLY};
      bins both_active = {REQ_BOTH_ACTIVE};
    }
    
    // Scenario 3: Competing master interrupts during Lock Cycle 1 or Lock Cycle 2
    // Scenario 7: Both masters active (BOTH_ACTIVE) during Lock Cycle 1 or Lock Cycle 2
    cx_lock_interruptions: cross cp_lock_phase, cp_req_in_lock {
      // Scenario 3 bins
      bins phy_interrupts_d2d_cyc1 = binsof(cp_lock_phase.d2d_cyc1) && binsof(cp_req_in_lock.phy_only);
      bins phy_interrupts_d2d_cyc2 = binsof(cp_lock_phase.d2d_cyc2) && binsof(cp_req_in_lock.phy_only);
      bins d2d_interrupts_phy_cyc1 = binsof(cp_lock_phase.phy_cyc1) && binsof(cp_req_in_lock.d2d_only);
      bins d2d_interrupts_phy_cyc2 = binsof(cp_lock_phase.phy_cyc2) && binsof(cp_req_in_lock.d2d_only);
      
      // Scenario 7 bins (BOTH_ACTIVE edge case while locked)
      bins both_active_in_d2d_cyc1 = binsof(cp_lock_phase.d2d_cyc1) && binsof(cp_req_in_lock.both_active);
      bins both_active_in_d2d_cyc2 = binsof(cp_lock_phase.d2d_cyc2) && binsof(cp_req_in_lock.both_active);
      bins both_active_in_phy_cyc1 = binsof(cp_lock_phase.phy_cyc1) && binsof(cp_req_in_lock.both_active);
      bins both_active_in_phy_cyc2 = binsof(cp_lock_phase.phy_cyc2) && binsof(cp_req_in_lock.both_active);
      
      // Ignore same-master continuation without contention
      ignore_bins same_master_cont = (binsof(cp_lock_phase.d2d_cyc1) && binsof(cp_req_in_lock.d2d_only)) || (binsof(cp_lock_phase.d2d_cyc2) && binsof(cp_req_in_lock.d2d_only)) || (binsof(cp_lock_phase.phy_cyc1) && binsof(cp_req_in_lock.phy_only)) || (binsof(cp_lock_phase.phy_cyc2) && binsof(cp_req_in_lock.phy_only));
    }
  endgroup
  
  // ===========================================================================
  // SCENARIO 4: Completion Marker (Comp_Marker_D2D) Filtering & Passthrough
  // ===========================================================================
  covergroup cg_scen4_comp_marker;
    option.per_instance = 1;
    
    cp_d2d_comp: coverpoint d2d_item.comp_marker iff (phy_item.rst_n) {
      bins comp_0 = {1'b0};
      bins comp_1 = {1'b1};
    }
    
    cp_arb_context: coverpoint {lock_phase, curr_req} iff (phy_item.rst_n) {
      bins d2d_uncontended_win = {{LOCK_IDLE, REQ_D2D_ONLY}};
      bins phy_contention_win = {{LOCK_IDLE, REQ_BOTH_ACTIVE}};
      bins phy_locked_suppress = {{PHY_LOCK_CYC1, REQ_D2D_ONLY}, {PHY_LOCK_CYC1, REQ_BOTH_ACTIVE}, {PHY_LOCK_CYC2, REQ_D2D_ONLY}, {PHY_LOCK_CYC2, REQ_BOTH_ACTIVE}
      };
    }
    
    cx_scen4_comp_check: cross cp_d2d_comp, cp_arb_context;
  endgroup
  
  // ===========================================================================
  // SCENARIO 5: Back-to-Back Traffic & Post-Lock Bubble
  // ===========================================================================
  covergroup cg_scen5_b2b_and_bubble;
    option.per_instance = 1;
    
    // Back-to-back single-phase streaming transitions
    cp_b2b_stream: coverpoint curr_req iff (phy_item.rst_n && lock_phase == LOCK_IDLE &&
      !phy_item.data_marker && !d2d_item.data_marker) {
      bins d2d_b2b = (REQ_D2D_ONLY => REQ_D2D_ONLY);
      bins phy_b2b = (REQ_PHY_ONLY => REQ_PHY_ONLY);
      bins d2d_to_phy = (REQ_D2D_ONLY => REQ_PHY_ONLY);
      bins phy_to_d2d = (REQ_PHY_ONLY => REQ_D2D_ONLY);
    }
    
    // Traffic arriving in the 1-cycle cooldown bubble immediately after a 2-phase lock releases
    cp_bubble_req: coverpoint curr_req iff (phy_item.rst_n && post_lock_bubble) {
      bins d2d_req_in_bubble = {REQ_D2D_ONLY};
      bins phy_req_in_bubble = {REQ_PHY_ONLY};
      bins both_req_in_bubble = {REQ_BOTH_ACTIVE};
    }
  endgroup
  
  // ===========================================================================
  // SCENARIO 6: Reactive Retry Loop (End-to-End Resend Completion)
  // ===========================================================================
  covergroup cg_scen6_reactive_retry;
    option.per_instance = 1;
    
    // Hits when PHY was previously rejected (PHY_Resend_Req triggered) and subsequently wins arbitration
    cp_phy_retry_success: coverpoint(phy_retry_pending && lock_phase == LOCK_IDLE &&
      (curr_req == REQ_PHY_ONLY || curr_req == REQ_BOTH_ACTIVE))
    iff (phy_item.rst_n) {
      bins retry_completed = {1'b1};
    }
    
    // Hits when D2D was previously rejected (D2D_Resend_Req triggered) and subsequently wins arbitration
    cp_d2d_retry_success: coverpoint(d2d_retry_pending && lock_phase == LOCK_IDLE &&
      curr_req == REQ_D2D_ONLY)
    iff (phy_item.rst_n) {
      bins retry_completed = {1'b1};
    }
  endgroup
  
  // ===========================================================================
  // SCENARIO 8: Mid-Transaction Asynchronous Reset (RST_n) Recovery
  // ===========================================================================
  covergroup cg_scen8_reset_recovery;
    option.per_instance = 1;
    
    cp_rst_n: coverpoint(phy_item.rst_n) {
      bins active_low = {1'b0};
      bins active_high = {1'b1};
      bins rst_assert_edge = (1'b1 => 1'b0);
      bins rst_deassert_edge = (1'b0 => 1'b1);
    }
    
    // Captures which state the arbiter was in when RST_n=0 arrived
    cp_rst_during_lock: coverpoint lock_phase iff (!phy_item.rst_n) {
      bins rst_in_idle = {LOCK_IDLE};
      bins rst_in_d2d_lock = {D2D_LOCK_CYC1, D2D_LOCK_CYC2};
      bins rst_in_phy_lock = {PHY_LOCK_CYC1, PHY_LOCK_CYC2};
    }
    
    // Verifies normal transaction acceptance after recovering from a mid-lock reset
    cp_post_rst_recovery: coverpoint(mid_lock_rst_seen && phy_item.rst_n &&
      (curr_req == REQ_D2D_ONLY || curr_req == REQ_PHY_ONLY)) {
      bins recovered_and_transacting = {1'b1};
    }
  endgroup
  
  // ===========================================================================
  // Constructor & Build Phase
  // ===========================================================================
  function new(string name = "pe_sbtx_coverage", uvm_component parent = null);
    super.new(name, parent);
    cg_scen1_2_sanity_and_contention = new();
    cg_scen3_7_mid_lock_contention = new();
    cg_scen4_comp_marker = new();
    cg_scen5_b2b_and_bubble = new();
    cg_scen6_reactive_retry = new();
    cg_scen8_reset_recovery = new();
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    phy_imp = new("phy_imp", this);
    d2d_imp = new("d2d_imp", this);
    phy_item = pe_sbtx_PHY_sequence_item::type_id::create("phy_item");
    d2d_item = pe_sbtx_D2D_sequence_item::type_id::create("d2d_item");
    
    lock_phase = LOCK_IDLE;
    post_lock_bubble = 1'b0;
    phy_retry_pending = 1'b0;
    d2d_retry_pending = 1'b0;
    mid_lock_rst_seen = 1'b0;
  endfunction
  
  // ===========================================================================
  // Monitor Write Callbacks & Cycle-Aligned State Tracker
  // ===========================================================================
  virtual function void write_phy(pe_sbtx_PHY_sequence_item t);
    phy_item = t;
    phy_valid = 1'b1;
    if (d2d_valid) sample_and_advance();
  endfunction
  
  virtual function void write_d2d(pe_sbtx_D2D_sequence_item t);
    d2d_item = t;
    d2d_valid = 1'b1;
    if (phy_valid) sample_and_advance();
  endfunction
  
  // Samples all covergroups for the current clock edge, then advances the shadow FSM
  virtual function void sample_and_advance();
    phy_valid = 1'b0;
    d2d_valid = 1'b0;
    
    curr_req = req_state_e'({phy_item.en, d2d_item.en});
    
    // 1. Sample all covergroups using current cycle stimulus and current lock state
    cg_scen1_2_sanity_and_contention.sample();
    cg_scen3_7_mid_lock_contention.sample();
    cg_scen4_comp_marker.sample();
    cg_scen5_b2b_and_bubble.sample();
    cg_scen6_reactive_retry.sample();
    cg_scen8_reset_recovery.sample();
    
    // 2. Advance shadow state to mirror Priority_Encoder_SBTX.sv for the next cycle
    update_arbiter_state();
  endfunction
  
  virtual function void update_arbiter_state();
    // Asynchronous reset handling (Scenario 8)
    if (!phy_item.rst_n) begin
      if (lock_phase != LOCK_IDLE) begin
        mid_lock_rst_seen = 1'b1;
      end
      lock_phase = LOCK_IDLE;
      post_lock_bubble = 1'b0;
      phy_retry_pending = 1'b0;
      d2d_retry_pending = 1'b0;
      return;
    end
    
    // Clear mid_lock_rst_seen once a post-reset transaction is observed
    if (mid_lock_rst_seen && (curr_req == REQ_D2D_ONLY || curr_req == REQ_PHY_ONLY)) begin
      mid_lock_rst_seen = 1'b0;
    end
    
    // Track Resend_Req / Retry lifecycle (Scenario 6)
    if (lock_phase == LOCK_IDLE) begin
      if (curr_req == REQ_PHY_ONLY || curr_req == REQ_BOTH_ACTIVE)
        phy_retry_pending = 1'b0; // PHY won arbitration
      if (curr_req == REQ_D2D_ONLY)
        d2d_retry_pending = 1'b0; // D2D won arbitration
      if (curr_req == REQ_BOTH_ACTIVE)
        d2d_retry_pending = 1'b1; // D2D rejected due to simultaneous contention
    end
    else begin
      // Rejected due to active priority lock
      if (curr_req == REQ_PHY_ONLY && (lock_phase == D2D_LOCK_CYC1 || lock_phase == D2D_LOCK_CYC2))
        phy_retry_pending = 1'b1;
      if (curr_req == REQ_D2D_ONLY && (lock_phase == PHY_LOCK_CYC1 || lock_phase == PHY_LOCK_CYC2))
        d2d_retry_pending = 1'b1;
      if (curr_req == REQ_BOTH_ACTIVE)
        d2d_retry_pending = 1'b1;
    end
    
    // Advance lock phase state machine matching Priority_Encoder_SBTX.sv
    post_lock_bubble = 1'b0;
    case (lock_phase)
      LOCK_IDLE: begin
        if (curr_req == REQ_D2D_ONLY && d2d_item.data_marker)
          lock_phase = D2D_LOCK_CYC1;
        else if ((curr_req == REQ_PHY_ONLY || curr_req == REQ_BOTH_ACTIVE) && phy_item.data_marker)
          lock_phase = PHY_LOCK_CYC1;
      end
      
      D2D_LOCK_CYC1: lock_phase = D2D_LOCK_CYC2;
      PHY_LOCK_CYC1: lock_phase = PHY_LOCK_CYC2;
      
      D2D_LOCK_CYC2,
      PHY_LOCK_CYC2: begin
        lock_phase = LOCK_IDLE;
        post_lock_bubble = 1'b1; // Next cycle is the 1-cycle post-lock bubble
      end
      
      default: lock_phase = LOCK_IDLE;
    endcase
  endfunction
endclass

`endif // PE_SBTX_COVERAGE_SVH