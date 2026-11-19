`ifndef CREDITS_HANDLER_SBTX_BASE_TEST_SVH
`define CREDITS_HANDLER_SBTX_BASE_TEST_SVH

class Credits_Handler_SBTX_base_test extends uvm_test;
  `uvm_component_utils(Credits_Handler_SBTX_base_test)

  Credits_Handler_SBTX_environment env;
  Credits_Handler_SBTX_env_cfg_obj env_cfg;

  Credits_Handler_SBTX_rst_sequence rst_seq;
  Credits_Handler_SBTX_3_idle_sequence idle3_seq;
  Credits_Handler_SBTX_protocol_sequence protocol_seq;
  Credits_Handler_SBTX_concurrent_burst_and_drain_sequence drain_seq;
  Credits_Handler_SBTX_mid_drain_rst_sequence mid_rst_seq;
  Credits_Handler_SBTX_combinations_sequence comb_seq;
  Credits_Handler_SBTX_back_to_back_sequence b2b_seq;
  Credits_Handler_SBTX_random_sequence rand_seq;

  function new(string name = "Credits_Handler_SBTX_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Create and configure the environment config object
    env_cfg = Credits_Handler_SBTX_env_cfg_obj::type_id::create("env_cfg");

    // Retrieve the virtual interface from config_db (set in tb_top)
    if (!uvm_config_db#(virtual Credits_Handler_SBTX_if#())::get(
            this, "", "CREDITS_HANDLER_SBTX_VIF", env_cfg.Credits_Handler_SBTX_vif))
      `uvm_fatal("CREDITS_HANDLER_SBTX_TEST", "CREDITS_HANDLER_SBTX_VIF not found in config_db")

    // Enable all components
    env_cfg.Credits_Handler_SBTX_has_agent      = 1;
    env_cfg.Credits_Handler_SBTX_has_scoreboard = 1;
    env_cfg.Credits_Handler_SBTX_has_subscriber = 1;
    env_cfg.active_passive_agents["Credits_Handler_SBTX"] = UVM_ACTIVE;

    uvm_config_db#(Credits_Handler_SBTX_env_cfg_obj)::set(this, "env", "cfg", env_cfg);

    env = Credits_Handler_SBTX_environment::type_id::create("env", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    rst_seq = Credits_Handler_SBTX_rst_sequence::type_id::create("rst_seq");
    idle3_seq = Credits_Handler_SBTX_3_idle_sequence::type_id::create("idle3_seq");
    protocol_seq = Credits_Handler_SBTX_protocol_sequence::type_id::create("protocol_seq");
    drain_seq = Credits_Handler_SBTX_concurrent_burst_and_drain_sequence::type_id::create("drain_seq");
    mid_rst_seq = Credits_Handler_SBTX_mid_drain_rst_sequence::type_id::create("mid_rst_seq");
    comb_seq = Credits_Handler_SBTX_combinations_sequence::type_id::create("comb_seq");
    b2b_seq = Credits_Handler_SBTX_back_to_back_sequence::type_id::create("b2b_seq");
    rand_seq = Credits_Handler_SBTX_random_sequence::type_id::create("rand_seq");
    phase.raise_objection(this);
    rst_seq.start(env.agt.seqr);
    idle3_seq.start(env.agt.seqr);
    protocol_seq.start(env.agt.seqr);
    drain_seq.start(env.agt.seqr);
    mid_rst_seq.start(env.agt.seqr); 
    comb_seq.start(env.agt.seqr);
    b2b_seq.start(env.agt.seqr);
    rand_seq.start(env.agt.seqr);
    repeat(2) @(posedge env_cfg.Credits_Handler_SBTX_vif.clk);
    phase.drop_objection(this);
  endtask
endclass

`endif // CREDITS_HANDLER_SBTX_BASE_TEST_SVH
