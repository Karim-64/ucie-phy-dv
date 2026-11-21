`ifndef TIMER_SBTX_BASE_TEST_SVH
`define TIMER_SBTX_BASE_TEST_SVH

class Timer_SBTX_base_test extends uvm_test;
  `uvm_component_utils(Timer_SBTX_base_test)

  Timer_SBTX_environment env;
  Timer_SBTX_env_cfg_obj env_cfg;
  Timer_SBTX_base_sequence seq;

  function new(string name = "Timer_SBTX_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Create and configure the environment config object
    env_cfg = Timer_SBTX_env_cfg_obj::type_id::create("env_cfg");

    // Retrieve the virtual interface from config_db (set in tb_top)
    if (!uvm_config_db#(virtual Timer_SBTX_if#(NO_OF_CYCLES))::get(
            this, "", "TIMER_SBTX_VIF", env_cfg.Timer_SBTX_vif))
      `uvm_fatal("TIMER_SBTX_TEST", "TIMER_SBTX_VIF not found in config_db")

    // Enable all components
    env_cfg.Timer_SBTX_has_agent      = 1;
    env_cfg.Timer_SBTX_has_scoreboard = 1;
    env_cfg.Timer_SBTX_has_subscriber = 1;
    env_cfg.active_passive_agents["Timer_SBTX"] = UVM_ACTIVE;

    uvm_config_db#(Timer_SBTX_env_cfg_obj)::set(this, "env", "cfg", env_cfg);

    env = Timer_SBTX_environment::type_id::create("env", this);
    seq = Timer_SBTX_base_sequence::type_id::create("seq");
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

`endif // TIMER_SBTX_BASE_TEST_SVH
