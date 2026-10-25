`ifndef CLK_GATE_SBTX_BASE_TEST_SVH
`define CLK_GATE_SBTX_BASE_TEST_SVH

class clk_gate_sbtx_base_test extends uvm_test;
  `uvm_component_utils(clk_gate_sbtx_base_test)

  clk_gate_sbtx_environment env;
  clk_gate_sbtx_env_cfg_obj env_cfg;
  clk_gate_sbtx_base_sequence seq;

  function new(string name = "clk_gate_sbtx_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Create and configure the environment config object
    env_cfg = clk_gate_sbtx_env_cfg_obj::type_id::create("env_cfg");

    // Retrieve the virtual interface from config_db (set in tb_top)
    if (!uvm_config_db#(virtual clk_gate_sbtx_if#(PULSE_WIDTH))::get(
            this, "", "CLK_GATE_SBTX_VIF", env_cfg.clk_gate_sbtx_vif))
      `uvm_fatal("CLK_GATE_SBTX_TEST", "CLK_GATE_SBTX_VIF not found in config_db")

    // Enable all components
    env_cfg.clk_gate_sbtx_has_agent      = 1;
    env_cfg.clk_gate_sbtx_has_scoreboard = 1;
    env_cfg.clk_gate_sbtx_has_subscriber = 1;
    env_cfg.active_passive_agents["clk_gate_sbtx"] = UVM_ACTIVE;

    uvm_config_db#(clk_gate_sbtx_env_cfg_obj)::set(this, "env", "cfg", env_cfg);

    env = clk_gate_sbtx_environment::type_id::create("env", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    // TODO: Start sequences on the sequencer
    seq = clk_gate_sbtx_base_sequence::type_id::create("seq");
    phase.raise_objection(this);
    seq.start(env.agt.seqr);
    phase.drop_objection(this);
  endtask
endclass

`endif // CLK_GATE_SBTX_BASE_TEST_SVH
