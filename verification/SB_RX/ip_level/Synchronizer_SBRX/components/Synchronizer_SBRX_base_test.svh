`ifndef SYNCHRONIZER_SBRX_BASE_TEST_SVH
`define SYNCHRONIZER_SBRX_BASE_TEST_SVH

class Synchronizer_SBRX_base_test extends uvm_test;
  `uvm_component_utils(Synchronizer_SBRX_base_test)

  Synchronizer_SBRX_environment env;
  Synchronizer_SBRX_env_cfg_obj env_cfg;

  Synchronizer_SBRX_reset_sequence    rst_seq;
  Synchronizer_SBRX_stream_0_sequence stream_0_seq;
  Synchronizer_SBRX_stream_1_sequence stream_1_seq;
  Synchronizer_SBRX_toggle_sequence   toggle_seq;
  Synchronizer_SBRX_random_sequence   random_seq;

  function new(string name = "Synchronizer_SBRX_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Create and configure the environment config object
    env_cfg = Synchronizer_SBRX_env_cfg_obj::type_id::create("env_cfg");

    // Retrieve the virtual interface from config_db (set in tb_top)
    if (!uvm_config_db#(virtual Synchronizer_SBRX_if#())::get(
            this, "", "SYNCHRONIZER_SBRX_VIF", env_cfg.Synchronizer_SBRX_vif))
      `uvm_fatal("SYNCHRONIZER_SBRX_TEST", "SYNCHRONIZER_SBRX_VIF not found in config_db")

    // Enable all components
    env_cfg.Synchronizer_SBRX_has_agent      = 1;
    env_cfg.Synchronizer_SBRX_has_scoreboard = 1;
    env_cfg.Synchronizer_SBRX_has_subscriber = 1;
    env_cfg.active_passive_agents["Synchronizer_SBRX"] = UVM_ACTIVE;

    uvm_config_db#(Synchronizer_SBRX_env_cfg_obj)::set(this, "env", "cfg", env_cfg);

    env = Synchronizer_SBRX_environment::type_id::create("env", this);


    rst_seq       = Synchronizer_SBRX_reset_sequence    ::type_id::create("rst_seq");
    stream_0_seq  = Synchronizer_SBRX_stream_0_sequence ::type_id::create("stream_0_seq");
    stream_1_seq  = Synchronizer_SBRX_stream_1_sequence ::type_id::create("stream_1_seq");
    toggle_seq    = Synchronizer_SBRX_toggle_sequence   ::type_id::create("toggle_seq");
    random_seq    = Synchronizer_SBRX_random_sequence   ::type_id::create("random_seq");
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    phase.raise_objection(this);
    `uvm_info("run_phase", "rst sequence start", UVM_MEDIUM)
    rst_seq.start(env.agt.seqr);
    `uvm_info("run_phase", "rst sequence completed", UVM_MEDIUM)

    `uvm_info("run_phase", "stream_0_seq sequence start", UVM_MEDIUM)
    stream_0_seq.start(env.agt.seqr);
    `uvm_info("run_phase", "stream_0_seq sequence completed", UVM_MEDIUM)

    `uvm_info("run_phase", "stream_1_seq sequence start", UVM_MEDIUM)
    stream_1_seq.start(env.agt.seqr);
    `uvm_info("run_phase", "stream_1_seq sequence completed", UVM_MEDIUM)

    `uvm_info("run_phase", "toggle_seq sequence start", UVM_MEDIUM)
    toggle_seq.start(env.agt.seqr);
    `uvm_info("run_phase", "toggle_seq sequence completed", UVM_MEDIUM)

    `uvm_info("run_phase", "random_seq sequence start", UVM_MEDIUM)
    random_seq.start(env.agt.seqr);
    `uvm_info("run_phase", "random_seq sequence completed", UVM_MEDIUM)
    
    repeat(1)@(posedge env.cfg.Synchronizer_SBRX_vif.clk_dst);
    phase.drop_objection(this);
  endtask
endclass

`endif // SYNCHRONIZER_SBRX_BASE_TEST_SVH
