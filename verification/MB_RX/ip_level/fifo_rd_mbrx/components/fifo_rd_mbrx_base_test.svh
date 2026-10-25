`ifndef FIFO_RD_MBRX_BASE_TEST_SVH
`define FIFO_RD_MBRX_BASE_TEST_SVH

class fifo_rd_mbrx_base_test extends uvm_test;
  `uvm_component_utils(fifo_rd_mbrx_base_test)

  fifo_rd_mbrx_environment env;
  fifo_rd_mbrx_env_cfg_obj env_cfg;

  function new(string name = "fifo_rd_mbrx_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Create and configure the environment config object
    env_cfg = fifo_rd_mbrx_env_cfg_obj::type_id::create("env_cfg");

    // Retrieve the virtual interface from config_db (set in tb_top)
    if (!uvm_config_db#(virtual fifo_rd_mbrx_if#(P_SIZE))::get(
            this, "", "FIFO_RD_MBRX_VIF", env_cfg.fifo_rd_mbrx_vif))
      `uvm_fatal("FIFO_RD_MBRX_TEST", "FIFO_RD_MBRX_VIF not found in config_db")

    // Enable all components
    env_cfg.fifo_rd_mbrx_has_agent      = 1;
    env_cfg.fifo_rd_mbrx_has_scoreboard = 1;
    env_cfg.fifo_rd_mbrx_has_subscriber = 1;
    env_cfg.active_passive_agents["fifo_rd_mbrx"] = UVM_ACTIVE;

    uvm_config_db#(fifo_rd_mbrx_env_cfg_obj)::set(this, "env", "cfg", env_cfg);

    env = fifo_rd_mbrx_environment::type_id::create("env", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    // TODO: Start sequences on the sequencer
    // e.g. fifo_rd_mbrx_base_sequence seq = fifo_rd_mbrx_base_sequence::type_id::create("seq");
    // phase.raise_objection(this);
    // seq.start(env.agt.seqr);
    // phase.drop_objection(this);
  endtask
endclass

`endif // FIFO_RD_MBRX_BASE_TEST_SVH
