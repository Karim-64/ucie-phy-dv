`ifndef WR_CONTROL_SBTX_BASE_TEST_SVH
`define WR_CONTROL_SBTX_BASE_TEST_SVH

class wr_control_sbtx_base_test extends uvm_test;
  `uvm_component_utils(wr_control_sbtx_base_test)

  wr_control_sbtx_environment env;
  wr_control_sbtx_env_cfg_obj env_cfg;
  wr_control_sbtx_base_sequence seq;
  wr_control_sbtx_all_opcodes_seq all_opcodes_seq_inst;
  wr_control_sbtx_directed_seq dir_seq_inst;
  wr_control_sbtx_randomized_sequence rand_seq_inst;

  function new(string name = "wr_control_sbtx_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Create and configure the environment config object
    env_cfg = wr_control_sbtx_env_cfg_obj::type_id::create("env_cfg");

    // Retrieve the virtual interface from config_db (set in tb_top)
    if (!uvm_config_db#(virtual wr_control_sbtx_if#(NC))::get(
            this, "", "WR_CONTROL_SBTX_VIF", env_cfg.wr_control_sbtx_vif))
      `uvm_fatal("WR_CONTROL_SBTX_TEST", "WR_CONTROL_SBTX_VIF not found in config_db")

    // Enable all components
    env_cfg.wr_control_sbtx_has_agent      = 1;
    env_cfg.wr_control_sbtx_has_scoreboard = 1;
    env_cfg.wr_control_sbtx_has_subscriber = 1;
    env_cfg.active_passive_agents["wr_control_sbtx"] = UVM_ACTIVE;

    uvm_config_db#(wr_control_sbtx_env_cfg_obj)::set(this, "env", "cfg", env_cfg);

    env = wr_control_sbtx_environment::type_id::create("env", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    // TODO: Start sequences on the sequencer
    seq = wr_control_sbtx_base_sequence::type_id::create("seq");
    all_opcodes_seq_inst=wr_control_sbtx_all_opcodes_seq::type_id::create("all_opcodes_seq_inst");
    dir_seq_inst=wr_control_sbtx_directed_seq::type_id::create("dir_seq_inst");
    rand_seq_inst=wr_control_sbtx_randomized_sequence::type_id::create("rand_seq_inst");
    phase.raise_objection(this);
    seq.start(env.agt.seqr);
    all_opcodes_seq_inst.start(env.agt.seqr);
    all_opcodes_seq_inst.use_idle_cycles=0;
    all_opcodes_seq_inst.start(env.agt.seqr);
    dir_seq_inst.start(env.agt.seqr);
    rand_seq_inst.start(env.agt.seqr);
    #8;
    phase.drop_objection(this);
  endtask
endclass

`endif // WR_CONTROL_SBTX_BASE_TEST_SVH
