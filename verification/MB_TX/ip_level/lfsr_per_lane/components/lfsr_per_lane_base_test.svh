`ifndef LFSR_PER_LANE_BASE_TEST_SVH
`define LFSR_PER_LANE_BASE_TEST_SVH

class lfsr_per_lane_base_test extends uvm_test;
  `uvm_component_utils(lfsr_per_lane_base_test)

  lfsr_per_lane_environment env;
  lfsr_per_lane_env_cfg_obj env_cfg;

  function new(string name = "lfsr_per_lane_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Create and configure the environment config object
    env_cfg = lfsr_per_lane_env_cfg_obj::type_id::create("env_cfg");

    // Retrieve the virtual interface from config_db (set in tb_top)
    if (!uvm_config_db#(virtual lfsr_per_lane_if#(WIDTH, Seed))::get(
            this, "", "LFSR_PER_LANE_VIF", env_cfg.lfsr_per_lane_vif))
      `uvm_fatal("LFSR_PER_LANE_TEST", "LFSR_PER_LANE_VIF not found in config_db")

    // Enable all components
    env_cfg.lfsr_per_lane_has_agent      = 1;
    env_cfg.lfsr_per_lane_has_scoreboard = 1;
    env_cfg.lfsr_per_lane_has_subscriber = 1;
    env_cfg.active_passive_agents["lfsr_per_lane"] = UVM_ACTIVE;

    uvm_config_db#(lfsr_per_lane_env_cfg_obj)::set(this, "env", "cfg", env_cfg);

    env = lfsr_per_lane_environment::type_id::create("env", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

  task run_phase(uvm_phase phase);
    lfsr_per_lane_base_sequence seq;
    super.run_phase(phase);

    phase.raise_objection(this);
    seq = lfsr_per_lane_base_sequence::type_id::create("seq");
    seq.start(env.agt.seqr);
    phase.drop_objection(this);
  endtask
endclass

`endif // LFSR_PER_LANE_BASE_TEST_SVH
