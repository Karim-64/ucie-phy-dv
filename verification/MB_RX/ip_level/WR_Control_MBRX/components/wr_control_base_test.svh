`ifndef WR_CONTROL_BASE_TEST_SVH
`define WR_CONTROL_BASE_TEST_SVH

class wr_control_base_test extends uvm_test;
  `uvm_component_utils(wr_control_base_test)

  wr_control_environment env;
  wr_control_env_cfg_obj env_cfg;

  wr_control_base_sequence           base_seq;
  wr_control_reset_sequence          reset_seq;
  wr_control_full_width_sequence     full_width_seq;
  wr_control_degraded_lower_sequence degraded_lower_seq;
  wr_control_degraded_upper_sequence degraded_upper_seq;
  wr_control_negative_sequence       negative_seq;
  wr_control_random_sequence         random_seq;

  function new(string name = "wr_control_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Create and configure the environment config object
    env_cfg = wr_control_env_cfg_obj::type_id::create("env_cfg");

    // Retrieve the virtual interface from config_db (set in tb_top)
    if (!uvm_config_db#(virtual wr_control_if#(W_D_SIZE, WIDTH_DEGRADE_LENGTH))::get(
            this, "", "WR_CONTROL_VIF", env_cfg.wr_control_vif))
      `uvm_fatal("WR_CONTROL_TEST", "WR_CONTROL_VIF not found in config_db")

    // Enable all components
    env_cfg.wr_control_has_agent      = 1;
    env_cfg.wr_control_has_scoreboard = 1;
    env_cfg.wr_control_has_subscriber = 1;
    env_cfg.active_passive_agents["wr_control"] = UVM_ACTIVE;

    uvm_config_db#(wr_control_env_cfg_obj)::set(this, "env", "cfg", env_cfg);

    env = wr_control_environment::type_id::create("env", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    // Create all sequences
    reset_seq          = wr_control_reset_sequence::type_id::create("reset_seq");
    base_seq           = wr_control_base_sequence::type_id::create("base_seq");
    full_width_seq     = wr_control_full_width_sequence::type_id::create("full_width_seq");
    degraded_lower_seq = wr_control_degraded_lower_sequence::type_id::create("degraded_lower_seq");
    degraded_upper_seq = wr_control_degraded_upper_sequence::type_id::create("degraded_upper_seq");
    negative_seq       = wr_control_negative_sequence::type_id::create("negative_seq");
    random_seq         = wr_control_random_sequence::type_id::create("random_seq");
    phase.raise_objection(this);
    // Start all sequences
    reset_seq.start(env.agt.seqr);
    base_seq.start(env.agt.seqr);
    full_width_seq.start(env.agt.seqr);
    degraded_lower_seq.start(env.agt.seqr);
    degraded_upper_seq.start(env.agt.seqr);
    negative_seq.start(env.agt.seqr);
    random_seq.start(env.agt.seqr);
    // margin time to allow the scoreboard to process the last two transactions
    #4ns;
    phase.drop_objection(this);
  endtask
endclass

`endif // WR_CONTROL_BASE_TEST_SVH