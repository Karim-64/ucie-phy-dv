`ifndef DMUX_1X4_BASE_TEST_SVH
`define DMUX_1X4_BASE_TEST_SVH

class DMUX_1x4_base_test extends uvm_test;
  `uvm_component_utils(DMUX_1x4_base_test)

  DMUX_1x4_environment env;
  DMUX_1x4_env_cfg_obj env_cfg;

  function new(string name = "DMUX_1x4_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Create and configure the environment config object
    env_cfg = DMUX_1x4_env_cfg_obj::type_id::create("env_cfg");

    // Retrieve the virtual interface from config_db (set in tb_top)
    if (!uvm_config_db#(virtual DMUX_1x4_if#(DATA_WIDTH, DESTINATION_SEL))::get(
            this, "", "DMUX_1X4_VIF", env_cfg.DMUX_1x4_vif))
      `uvm_fatal("DMUX_1X4_TEST", "DMUX_1X4_VIF not found in config_db")

    // Enable all components
    env_cfg.DMUX_1x4_has_agent      = 1;
    env_cfg.DMUX_1x4_has_scoreboard = 1;
    env_cfg.DMUX_1x4_has_subscriber = 1;
    env_cfg.active_passive_agents["DMUX_1x4"] = UVM_ACTIVE;

    uvm_config_db#(DMUX_1x4_env_cfg_obj)::set(this, "env", "cfg", env_cfg);

    env = DMUX_1x4_environment::type_id::create("env", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

  task run_phase(uvm_phase phase);
    DMUX_1x4_base_sequence seq;
    super.run_phase(phase);
    seq = DMUX_1x4_base_sequence::type_id::create("seq");
    phase.raise_objection(this);
    seq.start(env.agt.seqr);
    phase.drop_objection(this);
  endtask
endclass

`endif // DMUX_1X4_BASE_TEST_SVH
