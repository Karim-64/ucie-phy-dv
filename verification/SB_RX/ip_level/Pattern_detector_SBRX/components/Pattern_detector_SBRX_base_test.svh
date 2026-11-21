`ifndef PATTERN_DETECTOR_SBRX_BASE_TEST_SVH
`define PATTERN_DETECTOR_SBRX_BASE_TEST_SVH

class Pattern_detector_SBRX_base_test extends uvm_test;
  `uvm_component_utils(Pattern_detector_SBRX_base_test)

  Pattern_detector_SBRX_environment env;
  Pattern_detector_SBRX_env_cfg_obj env_cfg;
  Pattern_detector_SBRX_base_sequence seq;

  function new(string name = "Pattern_detector_SBRX_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Create and configure the environment config object
    env_cfg = Pattern_detector_SBRX_env_cfg_obj::type_id::create("env_cfg");

    // Retrieve the virtual interface from config_db (set in tb_top)
    if (!uvm_config_db#(virtual Pattern_detector_SBRX_if#(DATA_WIDTH))::get(
            this, "", "PATTERN_DETECTOR_SBRX_VIF", env_cfg.Pattern_detector_SBRX_vif))
      `uvm_fatal("PATTERN_DETECTOR_SBRX_TEST", "PATTERN_DETECTOR_SBRX_VIF not found in config_db")

    // Enable all components
    env_cfg.Pattern_detector_SBRX_has_agent      = 1;
    env_cfg.Pattern_detector_SBRX_has_scoreboard = 1;
    env_cfg.Pattern_detector_SBRX_has_subscriber = 1;
    env_cfg.active_passive_agents["Pattern_detector_SBRX"] = UVM_ACTIVE;

    uvm_config_db#(Pattern_detector_SBRX_env_cfg_obj)::set(this, "env", "cfg", env_cfg);

    env = Pattern_detector_SBRX_environment::type_id::create("env", this);
    seq = Pattern_detector_SBRX_base_sequence::type_id::create("seq");
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    // TODO: Start sequences on the sequencer
    phase.raise_objection(this);
    seq.start(env.agt.seqr);
    phase.drop_objection(this);
  endtask
endclass

`endif // PATTERN_DETECTOR_SBRX_BASE_TEST_SVH
