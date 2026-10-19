`ifndef DEMUX_BASE_TEST_SVH
`define DEMUX_BASE_TEST_SVH

class demux_base_test extends uvm_test;
  `uvm_component_utils(demux_base_test)

  demux_environment env;
  demux_env_cfg_obj env_cfg;

  demux_directed_seq directed_seq;
  demux_random_seq random_seq;

  function new(string name = "demux_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Create and configure the environment config object
    env_cfg = demux_env_cfg_obj::type_id::create("env_cfg");

    // Retrieve the virtual interface from config_db (set in tb_top)
    if (!uvm_config_db#(virtual demux_if#())::get(
            this, "", "DEMUX_VIF", env_cfg.demux_vif))
      `uvm_fatal("DEMUX_TEST", "DEMUX_VIF not found in config_db")

    // Enable all components
    env_cfg.demux_has_agent      = 1;
    env_cfg.demux_has_scoreboard = 1;
    env_cfg.demux_has_subscriber = 1;
    env_cfg.active_passive_agents["demux"] = UVM_ACTIVE;

    uvm_config_db#(demux_env_cfg_obj)::set(this, "env", "cfg", env_cfg);

    env = demux_environment::type_id::create("env", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    directed_seq = demux_directed_seq::type_id::create("directed_seq");
    random_seq   = demux_random_seq::type_id::create("random_seq");

    phase.raise_objection(this);
    directed_seq.start(env.agt.seqr);
    random_seq.start(env.agt.seqr);
    phase.drop_objection(this);
  endtask
endclass

`endif // DEMUX_BASE_TEST_SVH
