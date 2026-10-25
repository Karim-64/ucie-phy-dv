`ifndef LANES_MUX_BASE_TEST_SVH
`define LANES_MUX_BASE_TEST_SVH

class Lanes_MUX_base_test extends uvm_test;
  `uvm_component_utils(Lanes_MUX_base_test)

  Lanes_MUX_environment env;
  Lanes_MUX_env_cfg_obj env_cfg;
  Lanes_MUX_base_sequence seq;

  function new(string name = "Lanes_MUX_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Create and configure the environment config object
    env_cfg = Lanes_MUX_env_cfg_obj::type_id::create("env_cfg");

    // Retrieve the virtual interface from config_db (set in tb_top)
    if (!uvm_config_db#(virtual Lanes_MUX_if#())::get(
            this, "", "LANES_MUX_VIF", env_cfg.Lanes_MUX_vif))
      `uvm_fatal("LANES_MUX_TEST", "LANES_MUX_VIF not found in config_db")

    // Enable all components
    env_cfg.Lanes_MUX_has_agent      = 1;
    env_cfg.Lanes_MUX_has_scoreboard = 1;
    env_cfg.Lanes_MUX_has_subscriber = 1;
    env_cfg.active_passive_agents["Lanes_MUX"] = UVM_ACTIVE;

    uvm_config_db#(Lanes_MUX_env_cfg_obj)::set(this, "env", "cfg", env_cfg);

    env = Lanes_MUX_environment::type_id::create("env", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    seq = Lanes_MUX_base_sequence::type_id::create("seq");
    phase.raise_objection(this);
    seq.start(env.agt.seqr);
    #4ns
    phase.drop_objection(this);
  endtask
endclass

`endif // LANES_MUX_BASE_TEST_SVH
