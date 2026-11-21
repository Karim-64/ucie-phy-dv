`ifndef MUX_SBRX_BASE_TEST_SVH
`define MUX_SBRX_BASE_TEST_SVH

class mux_sbrx_base_test extends uvm_test;
  `uvm_component_utils(mux_sbrx_base_test)

  mux_sbrx_environment env;
  mux_sbrx_env_cfg_obj env_cfg;

  mux_sbrx_corner_seq corner_seq;
  mux_sbrx_isolation_seq isolation_seq;
  mux_sbrx_rand_seq rand_seq;

  function new(string name = "mux_sbrx_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Create and configure the environment config object
    env_cfg = mux_sbrx_env_cfg_obj::type_id::create("env_cfg");

    // Retrieve the virtual interface from config_db (set in tb_top)
    if (!uvm_config_db#(virtual mux_sbrx_if#(INPUT_WIDTH))::get(
            this, "", "MUX_SBRX_VIF", env_cfg.mux_sbrx_vif))
      `uvm_fatal("MUX_SBRX_TEST", "MUX_SBRX_VIF not found in config_db")

    // Enable all components
    env_cfg.mux_sbrx_has_agent      = 1;
    env_cfg.mux_sbrx_has_scoreboard = 1;
    env_cfg.mux_sbrx_has_subscriber = 1;
    env_cfg.active_passive_agents["mux_sbrx"] = UVM_ACTIVE;

    uvm_config_db#(mux_sbrx_env_cfg_obj)::set(this, "env", "cfg", env_cfg);

    env = mux_sbrx_environment::type_id::create("env", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    corner_seq = mux_sbrx_corner_seq::type_id::create("corner_seq");
    isolation_seq = mux_sbrx_isolation_seq::type_id::create("isolation_seq");
    rand_seq = mux_sbrx_rand_seq::type_id::create("rand_seq");

    phase.raise_objection(this);
    corner_seq.start(env.agt.seqr);
    isolation_seq.start(env.agt.seqr);
    rand_seq.start(env.agt.seqr);
    phase.drop_objection(this);
  endtask
endclass

`endif // MUX_SBRX_BASE_TEST_SVH
