`ifndef LEVEL_SYNC_SBTX_BASE_TEST_SVH
`define LEVEL_SYNC_SBTX_BASE_TEST_SVH

class level_sync_sbtx_base_test extends uvm_test;
  `uvm_component_utils(level_sync_sbtx_base_test)

  level_sync_sbtx_environment env;
  level_sync_sbtx_env_cfg_obj env_cfg;

  level_sync_sbtx_rst_sequence rst_seq;
  level_sync_sbtx_random_sequence rand_seq;

  function new(string name = "level_sync_sbtx_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Create and configure the environment config object
    env_cfg = level_sync_sbtx_env_cfg_obj::type_id::create("env_cfg");
    rst_seq = level_sync_sbtx_rst_sequence::type_id::create("rst_seq");
    rand_seq = level_sync_sbtx_random_sequence::type_id::create("rand_seq");

    // Retrieve the virtual interface from config_db (set in tb_top)
    if (!uvm_config_db#(virtual level_sync_sbtx_if#())::get(
            this, "", "LEVEL_SYNC_SBTX_VIF", env_cfg.level_sync_sbtx_vif))
      `uvm_fatal("LEVEL_SYNC_SBTX_TEST", "LEVEL_SYNC_SBTX_VIF not found in config_db")

    // Enable all components
    env_cfg.level_sync_sbtx_has_agent      = 1;
    env_cfg.level_sync_sbtx_has_scoreboard = 1;
    env_cfg.level_sync_sbtx_has_subscriber = 1;
    env_cfg.active_passive_agents["level_sync_sbtx"] = UVM_ACTIVE;

    uvm_config_db#(level_sync_sbtx_env_cfg_obj)::set(this, "env", "cfg", env_cfg);

    env = level_sync_sbtx_environment::type_id::create("env", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    phase.raise_objection(this);
    rst_seq.start(env.agt.seqr);
    rand_seq.start(env.agt.seqr);
    repeat(2) @(posedge env.cfg.level_sync_sbtx_vif.CLK);
    phase.drop_objection(this);
  endtask
endclass

`endif // LEVEL_SYNC_SBTX_BASE_TEST_SVH
