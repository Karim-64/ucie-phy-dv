`ifndef WR_CONTROL_SBTX_BASE_TEST_SVH
`define WR_CONTROL_SBTX_BASE_TEST_SVH

class wr_control_sbtx_base_test extends uvm_test;
  `uvm_component_utils(wr_control_sbtx_base_test)

  wr_control_sbtx_environment env;
  wr_control_sbtx_env_cfg_obj env_cfg;

  function new(string name = "wr_control_sbtx_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    env_cfg = wr_control_sbtx_env_cfg_obj::type_id::create("env_cfg");

    if (!uvm_config_db#(virtual wr_control_sbtx_if#(NC))::get(
            this, "", "WR_CONTROL_SBTX_VIF", env_cfg.wr_control_sbtx_vif))
      `uvm_fatal("WR_CONTROL_SBTX_TEST", "WR_CONTROL_SBTX_VIF not found in config_db")

    env_cfg.wr_control_sbtx_has_agent      = 1;
    env_cfg.wr_control_sbtx_has_scoreboard = 1;
    env_cfg.wr_control_sbtx_has_subscriber = 1;
    env_cfg.active_passive_agents["wr_control_sbtx"] = UVM_ACTIVE;

    uvm_config_db#(wr_control_sbtx_env_cfg_obj)::set(this, "env", "cfg", env_cfg);

    env = wr_control_sbtx_environment::type_id::create("env", this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

  virtual task run_phase(uvm_phase phase);
    wr_control_sbtx_base_sequence seq;
    super.run_phase(phase);

    seq = wr_control_sbtx_base_sequence::type_id::create("seq");
    phase.raise_objection(this);
    seq.start(env.agt.seqr);
    phase.drop_objection(this);
  endtask
endclass

`endif // WR_CONTROL_SBTX_BASE_TEST_SVH
