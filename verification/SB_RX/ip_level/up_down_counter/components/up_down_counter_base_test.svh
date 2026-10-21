`ifndef UP_DOWN_COUNTER_BASE_TEST_SVH
`define UP_DOWN_COUNTER_BASE_TEST_SVH

class up_down_counter_base_test extends uvm_test;
  `uvm_component_utils(up_down_counter_base_test)

  up_down_counter_environment env;
  up_down_counter_env_cfg_obj env_cfg;
  up_down_counter_base_sequence seq;

  function new(string name = "up_down_counter_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Create and configure the environment config object
    env_cfg = up_down_counter_env_cfg_obj::type_id::create("env_cfg");

    // Retrieve the virtual interface from config_db (set in tb_top)
    if (!uvm_config_db#(virtual up_down_counter_if#(WIDTH))::get(
            this, "", "UP_DOWN_COUNTER_VIF", env_cfg.up_down_counter_vif))
      `uvm_fatal("UP_DOWN_COUNTER_TEST", "UP_DOWN_COUNTER_VIF not found in config_db")

    // Enable all components
    env_cfg.up_down_counter_has_agent      = 1;
    env_cfg.up_down_counter_has_scoreboard = 1;
    env_cfg.up_down_counter_has_subscriber = 1;
    env_cfg.active_passive_agents["up_down_counter"] = UVM_ACTIVE;

    uvm_config_db#(up_down_counter_env_cfg_obj)::set(this, "env", "cfg", env_cfg);

    env = up_down_counter_environment::type_id::create("env", this);
    seq = up_down_counter_base_sequence::type_id::create("seq");
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

`endif // UP_DOWN_COUNTER_BASE_TEST_SVH
