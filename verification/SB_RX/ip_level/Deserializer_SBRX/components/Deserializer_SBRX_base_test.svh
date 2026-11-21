`ifndef DESERIALIZER_SBRX_BASE_TEST_SVH
`define DESERIALIZER_SBRX_BASE_TEST_SVH

class Deserializer_SBRX_base_test extends uvm_test;
  `uvm_component_utils(Deserializer_SBRX_base_test)

  Deserializer_SBRX_environment env;
  Deserializer_SBRX_env_cfg_obj env_cfg;

  function new(string name = "Deserializer_SBRX_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Create and configure the environment config object
    env_cfg = Deserializer_SBRX_env_cfg_obj::type_id::create("env_cfg");

    // Retrieve the virtual interface from config_db (set in tb_top)
    if (!uvm_config_db#(virtual Deserializer_SBRX_if#(DATA_WIDTH))::get(
            this, "", "DESERIALIZER_SBRX_VIF", env_cfg.Deserializer_SBRX_vif))
      `uvm_fatal("DESERIALIZER_SBRX_TEST", "DESERIALIZER_SBRX_VIF not found in config_db")

    // Enable all components
    env_cfg.Deserializer_SBRX_has_agent      = 1;
    env_cfg.Deserializer_SBRX_has_scoreboard = 1;
    env_cfg.Deserializer_SBRX_has_subscriber = 1;
    env_cfg.active_passive_agents["Deserializer_SBRX"] = UVM_ACTIVE;

    uvm_config_db#(Deserializer_SBRX_env_cfg_obj)::set(this, "env", "cfg", env_cfg);

    env = Deserializer_SBRX_environment::type_id::create("env", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

  task run_phase(uvm_phase phase);
    Deserializer_SBRX_Virtual_sequence v_seq;
    super.run_phase(phase);
    // TODO: Start sequences on the sequencer
    v_seq = Deserializer_SBRX_Virtual_sequence::type_id::create("v_seq");
    phase.raise_objection(this);
    v_seq.start(env.virt_seqr);
    phase.drop_objection(this);
  endtask
endclass

`endif // DESERIALIZER_SBRX_BASE_TEST_SVH
