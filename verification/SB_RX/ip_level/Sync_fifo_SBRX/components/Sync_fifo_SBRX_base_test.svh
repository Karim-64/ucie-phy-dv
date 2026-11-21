`ifndef SYNC_FIFO_SBRX_BASE_TEST_SVH
`define SYNC_FIFO_SBRX_BASE_TEST_SVH

class Sync_fifo_SBRX_base_test extends uvm_test;
  `uvm_component_utils(Sync_fifo_SBRX_base_test)

  Sync_fifo_SBRX_environment env;
  Sync_fifo_SBRX_env_cfg_obj env_cfg;

  function new(string name = "Sync_fifo_SBRX_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Create and configure the environment config object
    env_cfg = Sync_fifo_SBRX_env_cfg_obj::type_id::create("env_cfg");

    // Retrieve the virtual interface from config_db (set in tb_top)
    if (!uvm_config_db#(virtual Sync_fifo_SBRX_if#(DATA_WIDTH, FIFO_DEPTH))::get(
            this, "", "SYNC_FIFO_SBRX_VIF", env_cfg.Sync_fifo_SBRX_vif))
      `uvm_fatal("SYNC_FIFO_SBRX_TEST", "SYNC_FIFO_SBRX_VIF not found in config_db")

    // Enable all components
    env_cfg.Sync_fifo_SBRX_has_agent      = 1;
    env_cfg.Sync_fifo_SBRX_has_scoreboard = 1;
    env_cfg.Sync_fifo_SBRX_has_subscriber = 1;
    env_cfg.active_passive_agents["Sync_fifo_SBRX"] = UVM_ACTIVE;

    uvm_config_db#(Sync_fifo_SBRX_env_cfg_obj)::set(this, "env", "cfg", env_cfg);

    env = Sync_fifo_SBRX_environment::type_id::create("env", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

  task run_phase(uvm_phase phase);
    Sync_fifo_SBRX_base_sequence seq;
    super.run_phase(phase);
    seq = Sync_fifo_SBRX_base_sequence::type_id::create("seq");
    phase.raise_objection(this);
    seq.start(env.agt.seqr);
    phase.drop_objection(this);
  endtask
endclass

`endif // SYNC_FIFO_SBRX_BASE_TEST_SVH
