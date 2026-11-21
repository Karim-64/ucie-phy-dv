`ifndef GRAY_SYNCHRONIZER_SBTX_BASE_TEST_SVH
`define GRAY_SYNCHRONIZER_SBTX_BASE_TEST_SVH

class gray_synchronizer_sbtx_base_test extends uvm_test;
  `uvm_component_utils(gray_synchronizer_sbtx_base_test)

  gray_synchronizer_sbtx_environment env;
  gray_synchronizer_sbtx_env_cfg_obj env_cfg;

  function new(string name = "gray_synchronizer_sbtx_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Create and configure the environment config object
    env_cfg = gray_synchronizer_sbtx_env_cfg_obj::type_id::create("env_cfg");

    // Retrieve the virtual interface from config_db (set in tb_top)
    if (!uvm_config_db#(virtual gray_synchronizer_sbtx_if#(DATA_SIZE))::get(
            this, "", "GRAY_SYNCHRONIZER_SBTX_VIF", env_cfg.gray_synchronizer_sbtx_vif))
      `uvm_fatal("GRAY_SYNCHRONIZER_SBTX_TEST", "GRAY_SYNCHRONIZER_SBTX_VIF not found in config_db")

    // Enable all components
    env_cfg.gray_synchronizer_sbtx_has_agent      = 1;
    env_cfg.gray_synchronizer_sbtx_has_scoreboard = 1;
    env_cfg.gray_synchronizer_sbtx_has_subscriber = 1;
    env_cfg.active_passive_agents["gray_synchronizer_sbtx"] = UVM_ACTIVE;

    uvm_config_db#(gray_synchronizer_sbtx_env_cfg_obj)::set(this, "env", "cfg", env_cfg);

    env = gray_synchronizer_sbtx_environment::type_id::create("env", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

  task run_phase(uvm_phase phase);
    gray_synchronizer_sbtx_base_sequence seq;
    super.run_phase(phase);
    seq = gray_synchronizer_sbtx_base_sequence::type_id::create("seq");
    phase.raise_objection(this);
    seq.start(env.agt.seqr);
    phase.drop_objection(this);
  endtask
endclass

`endif // GRAY_SYNCHRONIZER_SBTX_BASE_TEST_SVH
