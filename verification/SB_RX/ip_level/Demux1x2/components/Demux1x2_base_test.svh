`ifndef DEMUX1X2_BASE_TEST_SVH
`define DEMUX1X2_BASE_TEST_SVH

class Demux1x2_base_test extends uvm_test;
  `uvm_component_utils(Demux1x2_base_test)

  Demux1x2_environment env;
  Demux1x2_env_cfg_obj env_cfg;

  Demux1x2_rst_seq  rst_seq;
  Demux1x2_zero_seq zero_seq;
  Demux1x2_one_seq one_seq;
  Demux1x2_select_1_seq select_1_seq;
  Demux1x2_select_0_seq select_0_seq;
  Demux1x2_random_seq random_seq;
  Demux1x2_alternating_seq alt_seq;
  Demux1x2_directed_seq    dir_seq;

  function new(string name = "Demux1x2_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Create and configure the environment config object
    env_cfg = Demux1x2_env_cfg_obj::type_id::create("env_cfg");

    // Retrieve the virtual interface from config_db (set in tb_top)
    if (!uvm_config_db#(virtual Demux1x2_if#(DATA_WIDTH))::get(
            this, "", "DEMUX1X2_VIF", env_cfg.Demux1x2_vif))
      `uvm_fatal("DEMUX1X2_TEST", "DEMUX1X2_VIF not found in config_db")

    // Enable all components
    env_cfg.Demux1x2_has_agent      = 1;
    env_cfg.Demux1x2_has_scoreboard = 1;
    env_cfg.Demux1x2_has_subscriber = 1;
    env_cfg.active_passive_agents["Demux1x2"] = UVM_ACTIVE;

    uvm_config_db#(Demux1x2_env_cfg_obj)::set(this, "env", "cfg", env_cfg);

    env = Demux1x2_environment::type_id::create("env", this);

    rst_seq       = Demux1x2_rst_seq::type_id::create("rst_seq");
    zero_seq      = Demux1x2_zero_seq::type_id::create("zero_seq");
    one_seq       = Demux1x2_one_seq::type_id::create("one_seq");
    select_1_seq  = Demux1x2_select_1_seq::type_id::create("select_1_seq");
    select_0_seq  = Demux1x2_select_0_seq::type_id::create("select_0_seq");
    random_seq    = Demux1x2_random_seq::type_id::create("random_seq");
    alt_seq       = Demux1x2_alternating_seq::type_id::create("alt_seq");
    dir_seq       = Demux1x2_directed_seq::type_id::create("dir_seq");
    
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
  
`uvm_info("run_phase", "dir_seq sequence start", UVM_MEDIUM)
  dir_seq.start(env.agt.seqr);
  `uvm_info("run_phase", "dir_seq sequence completed", UVM_MEDIUM)

  `uvm_info("run_phase", "zero_data sequence start", UVM_MEDIUM)
  zero_seq.start(env.agt.seqr);
  `uvm_info("run_phase", "zero_data sequence completed", UVM_MEDIUM)

  `uvm_info("run_phase", "one_data sequence start", UVM_MEDIUM)
  one_seq.start(env.agt.seqr);
  `uvm_info("run_phase", "one_data sequence completed", UVM_MEDIUM)

  `uvm_info("run_phase", "select_1 sequence start", UVM_MEDIUM)
  select_1_seq.start(env.agt.seqr);
  `uvm_info("run_phase", "select_1 sequence completed", UVM_MEDIUM)

  `uvm_info("run_phase", "select_0 sequence start", UVM_MEDIUM)
  select_0_seq.start(env.agt.seqr);
  `uvm_info("run_phase", "select_0 sequence completed", UVM_MEDIUM)

  `uvm_info("run_phase", "random sequence start", UVM_MEDIUM)
  random_seq.start(env.agt.seqr);
  `uvm_info("run_phase", "random sequence completed", UVM_MEDIUM) 

  `uvm_info("run_phase", "alternating sequence start", UVM_MEDIUM)
  alt_seq.start(env.agt.seqr);
  `uvm_info("run_phase", "alternating sequence completed", UVM_MEDIUM)

   repeat(1)@(posedge env.cfg.Demux1x2_vif.CLK);
  phase.drop_objection(this);
  endtask
endclass

`endif // DEMUX1X2_BASE_TEST_SVH
