`ifndef DEMUX_SBTX_BASE_TEST_SVH
`define DEMUX_SBTX_BASE_TEST_SVH

class demux_SBTX_base_test extends uvm_test;
  `uvm_component_utils(demux_SBTX_base_test)

  demux_SBTX_environment env;
  demux_SBTX_env_cfg_obj env_cfg;

  demux_SBTX_base_sequence seq;

  function new(string name = "demux_SBTX_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Create and configure the environment config object
    env_cfg = demux_SBTX_env_cfg_obj::type_id::create("env_cfg");

    // Retrieve the virtual interface from config_db (set in tb_top)
    if (!uvm_config_db#(virtual demux_SBTX_if#(DATA_WIDTH))::get(
            this, "", "DEMUX_SBTX_VIF", env_cfg.demux_SBTX_vif))
      `uvm_fatal("DEMUX_SBTX_TEST", "DEMUX_SBTX_VIF not found in config_db")

    // Enable all components
    env_cfg.demux_SBTX_has_agent      = 1;
    env_cfg.demux_SBTX_has_scoreboard = 1;
    env_cfg.demux_SBTX_has_subscriber = 1;
    env_cfg.active_passive_agents["demux_SBTX"] = UVM_ACTIVE;

    uvm_config_db#(demux_SBTX_env_cfg_obj)::set(this, "env", "cfg", env_cfg);

    env = demux_SBTX_environment::type_id::create("env", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    seq = demux_SBTX_base_sequence::type_id::create("seq");
    phase.raise_objection(this);
    seq.start(env.agt.seqr);
    repeat(2) @(posedge env_cfg.demux_SBTX_vif.clk);
    phase.drop_objection(this);
  endtask
endclass

`endif // DEMUX_SBTX_BASE_TEST_SVH
