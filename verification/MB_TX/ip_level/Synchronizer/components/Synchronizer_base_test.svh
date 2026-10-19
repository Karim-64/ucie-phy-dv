`ifndef SYNCHRONIZER_BASE_TEST_SVH
`define SYNCHRONIZER_BASE_TEST_SVH

class Synchronizer_base_test extends uvm_test;
  `uvm_component_utils(Synchronizer_base_test)

  Synchronizer_environment env;
  Synchronizer_env_cfg_obj env_cfg;
    Synchronizer_base_sequence seq;

  function new(string name = "Synchronizer_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Create and configure the environment config object
    env_cfg = Synchronizer_env_cfg_obj::type_id::create("env_cfg");

    // Retrieve the virtual interface from config_db (set in tb_top)
    if (!uvm_config_db#(virtual Synchronizer_if#())::get(
            this, "", "SYNCHRONIZER_VIF", env_cfg.Synchronizer_vif))
      `uvm_fatal("SYNCHRONIZER_TEST", "SYNCHRONIZER_VIF not found in config_db")

    // Enable all components
    env_cfg.Synchronizer_has_agent      = 1;
    env_cfg.Synchronizer_has_scoreboard = 1;
    env_cfg.Synchronizer_has_subscriber = 1;
    env_cfg.active_passive_agents["Synchronizer"] = UVM_ACTIVE;

    uvm_config_db#(Synchronizer_env_cfg_obj)::set(this, "env", "cfg", env_cfg);

    env = Synchronizer_environment::type_id::create("env", this);
    seq = Synchronizer_base_sequence::type_id::create("seq");
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

`endif // SYNCHRONIZER_BASE_TEST_SVH
