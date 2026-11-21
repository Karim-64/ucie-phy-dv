`ifndef SERIALIZER_SBTX_BASE_TEST_SVH
`define SERIALIZER_SBTX_BASE_TEST_SVH

class serializer_sbtx_base_test extends uvm_test;
  `uvm_component_utils(serializer_sbtx_base_test)

  serializer_sbtx_environment env;
  serializer_sbtx_env_cfg_obj env_cfg;
  serializer_sbtx_base_sequence seq;
  function new(string name = "serializer_sbtx_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Create and configure the environment config object
    env_cfg = serializer_sbtx_env_cfg_obj::type_id::create("env_cfg");

    // Retrieve the virtual interface from config_db (set in tb_top)
    if (!uvm_config_db#(virtual serializer_sbtx_if#(DATA_WIDTH))::get(
            this, "", "SERIALIZER_SBTX_VIF", env_cfg.serializer_sbtx_vif))
      `uvm_fatal("SERIALIZER_SBTX_TEST", "SERIALIZER_SBTX_VIF not found in config_db")

    // Enable all components
    env_cfg.serializer_sbtx_has_agent      = 1;
    env_cfg.serializer_sbtx_has_scoreboard = 1;
    env_cfg.serializer_sbtx_has_subscriber = 1;
    env_cfg.active_passive_agents["serializer_sbtx"] = UVM_ACTIVE;

    uvm_config_db#(serializer_sbtx_env_cfg_obj)::set(this, "env", "cfg", env_cfg);

    env = serializer_sbtx_environment::type_id::create("env", this);
    seq = serializer_sbtx_base_sequence::type_id::create("seq");
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
   
    phase.raise_objection(this);
    seq.start(env.agt.seqr);
    phase.drop_objection(this);
  endtask
endclass

`endif // SERIALIZER_SBTX_BASE_TEST_SVH
