`ifndef TIMER_MS_SBTX_BASE_TEST_SVH
`define TIMER_MS_SBTX_BASE_TEST_SVH

class Timer_ms_SBTX_base_test extends uvm_test;
  `uvm_component_utils(Timer_ms_SBTX_base_test)

  Timer_ms_SBTX_environment env;
  Timer_ms_SBTX_env_cfg_obj env_cfg;

  Timer_ms_SBTX_reset_sequence reset_seq;
  Timer_ms_SBTX_full_counting_sequence full_counting_seq;
  Timer_ms_SBTX_random_sequence random_seq;

  function new(string name = "Timer_ms_SBTX_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Create and configure the environment config object
    env_cfg = Timer_ms_SBTX_env_cfg_obj::type_id::create("env_cfg");

    // Retrieve the virtual interface from config_db (set in tb_top)
    if (!uvm_config_db#(virtual Timer_ms_SBTX_if#(CLK_FREQ_HZ, FACTOR))::get(
            this, "", "TIMER_MS_SBTX_VIF", env_cfg.Timer_ms_SBTX_vif))
      `uvm_fatal("TIMER_MS_SBTX_TEST", "TIMER_MS_SBTX_VIF not found in config_db")

    // Enable all components
    env_cfg.Timer_ms_SBTX_has_agent      = 1;
    env_cfg.Timer_ms_SBTX_has_scoreboard = 1;
    env_cfg.Timer_ms_SBTX_has_subscriber = 1;
    env_cfg.active_passive_agents["Timer_ms_SBTX"] = UVM_ACTIVE;

    uvm_config_db#(Timer_ms_SBTX_env_cfg_obj)::set(this, "env", "cfg", env_cfg);

    env = Timer_ms_SBTX_environment::type_id::create("env", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    reset_seq = Timer_ms_SBTX_reset_sequence::type_id::create("reset_seq");
    full_counting_seq = Timer_ms_SBTX_full_counting_sequence::type_id::create("full_counting_seq");
    random_seq = Timer_ms_SBTX_random_sequence::type_id::create("random_seq");
    phase.raise_objection(this);
    reset_seq.start(env.agt.seqr);
    full_counting_seq.start(env.agt.seqr);
    reset_seq.start(env.agt.seqr);
    random_seq.start(env.agt.seqr);
    repeat(2) @(posedge env_cfg.Timer_ms_SBTX_vif.clk);
    phase.drop_objection(this);
  endtask
endclass

`endif // TIMER_MS_SBTX_BASE_TEST_SVH
