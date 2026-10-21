`ifndef FIFO_SBTX_BASE_TEST_SVH
`define FIFO_SBTX_BASE_TEST_SVH

class fifo_sbtx_base_test extends uvm_test;
  `uvm_component_utils(fifo_sbtx_base_test)

  fifo_sbtx_environment env;
  fifo_sbtx_env_cfg_obj env_cfg;
  fifo_sbtx_base_sequence seq;

  function new(string name = "fifo_sbtx_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Create and configure the environment config object
    env_cfg = fifo_sbtx_env_cfg_obj::type_id::create("env_cfg");

    // Retrieve the virtual interface from config_db (set in tb_top)
    if (!uvm_config_db#(virtual fifo_sbtx_if#(FIFO_WIDTH, FIFO_DEPTH))::get(
            this, "", "FIFO_SBTX_VIF", env_cfg.fifo_sbtx_vif))
      `uvm_fatal("FIFO_SBTX_TEST", "FIFO_SBTX_VIF not found in config_db")

    // Enable all components
    env_cfg.fifo_sbtx_has_agent      = 1;
    env_cfg.fifo_sbtx_has_scoreboard = 1;
    env_cfg.fifo_sbtx_has_subscriber = 1;
    env_cfg.active_passive_agents["fifo_sbtx"] = UVM_ACTIVE;

    uvm_config_db#(fifo_sbtx_env_cfg_obj)::set(this, "env", "cfg", env_cfg);

    env = fifo_sbtx_environment::type_id::create("env", this);
    seq = fifo_sbtx_base_sequence::type_id::create("seq");
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
  phase.raise_objection(this);
    seq.start(env.agt.seqr);
   @(negedge env_cfg.fifo_sbtx_vif.clk);
    phase.drop_objection(this);

  endtask
endclass

`endif // FIFO_SBTX_BASE_TEST_SVH
