`ifndef DEMUX_BASE_TEST_SVH
`define DEMUX_BASE_TEST_SVH

class DEMUX_base_test extends uvm_test;
  `uvm_component_utils(DEMUX_base_test)

  DEMUX_environment env;
  DEMUX_env_cfg_obj env_cfg;

  DEMUX_base_sequence seq;

  function new(string name = "DEMUX_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Create and configure the environment config object
    env_cfg = DEMUX_env_cfg_obj::type_id::create("env_cfg");

    // Retrieve the virtual interface from config_db (set in tb_top)
    if (!uvm_config_db#(virtual DEMUX_if#())::get(
            this, "", "DEMUX_VIF", env_cfg.DEMUX_vif))
      `uvm_fatal("DEMUX_TEST", "DEMUX_VIF not found in config_db")

    // Enable all components
    env_cfg.DEMUX_has_agent      = 1;
    env_cfg.DEMUX_has_scoreboard = 1;
    env_cfg.DEMUX_has_subscriber = 1;
    env_cfg.active_passive_agents["DEMUX"] = UVM_ACTIVE;

    env = DEMUX_environment::type_id::create("env", this);

    uvm_config_db#(DEMUX_env_cfg_obj)::set(this, "env", "cfg", env_cfg);

  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    seq = DEMUX_base_sequence::type_id::create("seq");
    phase.raise_objection(this);
    seq.start(env.agt.seqr);
    repeat(1) @(posedge env_cfg.DEMUX_vif.clk);
    phase.drop_objection(this);
  endtask
endclass

`endif // DEMUX_BASE_TEST_SVH
