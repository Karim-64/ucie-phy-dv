`ifndef MEM_BASE_TEST_SVH
`define MEM_BASE_TEST_SVH

class mem_base_test extends uvm_test;
  `uvm_component_utils(mem_base_test)

  mem_environment env;
  mem_env_cfg_obj env_cfg;

  function new(string name = "mem_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Create and configure the environment config object
    env_cfg = mem_env_cfg_obj::type_id::create("env_cfg");

    // Retrieve the virtual interface from config_db (set in tb_top)
    if (!uvm_config_db#(virtual mem_if#(DATA_WIDTH, ADDRESS_WIDTH))::get(
            this, "", "MEM_VIF", env_cfg.mem_vif))
      `uvm_fatal("MEM_TEST", "MEM_VIF not found in config_db")

    // Enable all components
    env_cfg.mem_has_agent      = 1;
    env_cfg.mem_has_scoreboard = 1;
    env_cfg.mem_has_subscriber = 1;
    env_cfg.active_passive_agents["mem"] = UVM_ACTIVE;

    uvm_config_db#(mem_env_cfg_obj)::set(this, "env", "cfg", env_cfg);

    env = mem_environment::type_id::create("env", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    // TODO: Start sequences on the sequencer
    // e.g. mem_base_sequence seq = mem_base_sequence::type_id::create("seq");
    // phase.raise_objection(this);
    // seq.start(env.agt.seqr);
    // phase.drop_objection(this);
  endtask
endclass

`endif // MEM_BASE_TEST_SVH
