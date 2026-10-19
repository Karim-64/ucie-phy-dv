`ifndef MUX_SBTX_BASE_TEST_SVH
`define MUX_SBTX_BASE_TEST_SVH

class mux_sbtx_base_test extends uvm_test;
  `uvm_component_utils(mux_sbtx_base_test)

  mux_sbtx_environment env;
  mux_sbtx_env_cfg_obj env_cfg;

  mux_sbtx_corner_seq corner_seq;
  mux_sbtx_isolation_seq isolation_seq;
  mux_sbtx_rand_seq rand_seq;

  function new(string name = "mux_sbtx_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Create and configure the environment config object
    env_cfg = mux_sbtx_env_cfg_obj::type_id::create("env_cfg");

    // Retrieve the virtual interface from config_db (set in tb_top)
    if (!uvm_config_db#(virtual mux_sbtx_if#(INPUT_WIDTH))::get(
            this, "", "MUX_SBTX_VIF", env_cfg.mux_sbtx_vif))
      `uvm_fatal("MUX_SBTX_TEST", "MUX_SBTX_VIF not found in config_db")

    // Enable all components
    env_cfg.mux_sbtx_has_agent      = 1;
    env_cfg.mux_sbtx_has_scoreboard = 1;
    env_cfg.mux_sbtx_has_subscriber = 1;
    env_cfg.active_passive_agents["mux_sbtx"] = UVM_ACTIVE;

    uvm_config_db#(mux_sbtx_env_cfg_obj)::set(this, "env", "cfg", env_cfg);

    env = mux_sbtx_environment::type_id::create("env", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    corner_seq = mux_sbtx_corner_seq::type_id::create("corner_seq");
    isolation_seq = mux_sbtx_isolation_seq::type_id::create("isolation_seq");
    rand_seq = mux_sbtx_rand_seq::type_id::create("rand_seq");

    phase.raise_objection(this);
    corner_seq.start(env.agt.seqr);
    isolation_seq.start(env.agt.seqr);
    rand_seq.start(env.agt.seqr);
    phase.drop_objection(this);
  endtask
endclass

`endif // MUX_SBTX_BASE_TEST_SVH
