`ifndef BIT_SYNC_SBTX_BASE_TEST_SVH
`define BIT_SYNC_SBTX_BASE_TEST_SVH

class BIT_SYNC_SBTX_base_test extends uvm_test;
  `uvm_component_utils(BIT_SYNC_SBTX_base_test)

  BIT_SYNC_SBTX_environment env;
  BIT_SYNC_SBTX_env_cfg_obj env_cfg;

  BIT_SYNC_SBTX_base_sequence seq;

  function new(string name = "BIT_SYNC_SBTX_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Create and configure the environment config object
    env_cfg = BIT_SYNC_SBTX_env_cfg_obj::type_id::create("env_cfg");

    // Retrieve the virtual interface from config_db (set in tb_top)
    if (!uvm_config_db#(virtual BIT_SYNC_SBTX_if#(NUM_STAGES, BUS_WIDTH))::get(
            this, "", "BIT_SYNC_SBTX_VIF", env_cfg.BIT_SYNC_SBTX_vif))
      `uvm_fatal("BIT_SYNC_SBTX_TEST", "BIT_SYNC_SBTX_VIF not found in config_db")

    // Enable all components
    env_cfg.BIT_SYNC_SBTX_has_agent      = 1;
    env_cfg.BIT_SYNC_SBTX_has_scoreboard = 1;
    env_cfg.BIT_SYNC_SBTX_has_subscriber = 1;
    env_cfg.active_passive_agents["BIT_SYNC_SBTX"] = UVM_ACTIVE;

    uvm_config_db#(BIT_SYNC_SBTX_env_cfg_obj)::set(this, "env", "cfg", env_cfg);

    env = BIT_SYNC_SBTX_environment::type_id::create("env", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    phase.raise_objection(this);
    seq = BIT_SYNC_SBTX_base_sequence::type_id::create("seq");
    seq.start(env.agt.seqr);
    repeat(NUM_STAGES + 1) @(posedge env_cfg.BIT_SYNC_SBTX_vif.clk);
    phase.drop_objection(this);
  endtask
endclass

`endif // BIT_SYNC_SBTX_BASE_TEST_SVH
