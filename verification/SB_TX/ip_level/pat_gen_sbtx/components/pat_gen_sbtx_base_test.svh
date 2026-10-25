`ifndef PAT_GEN_SBTX_BASE_TEST_SVH
`define PAT_GEN_SBTX_BASE_TEST_SVH

class pat_gen_sbtx_base_test extends uvm_test;
  `uvm_component_utils(pat_gen_sbtx_base_test)

  pat_gen_sbtx_environment env;
  pat_gen_sbtx_env_cfg_obj env_cfg;

  function new(string name = "pat_gen_sbtx_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Create and configure the environment config object
    env_cfg = pat_gen_sbtx_env_cfg_obj::type_id::create("env_cfg");

    // Retrieve the virtual interface from config_db (set in tb_top)
    if (!uvm_config_db#(virtual pat_gen_sbtx_if#())::get(
            this, "", "PAT_GEN_SBTX_VIF", env_cfg.pat_gen_sbtx_vif))
      `uvm_fatal("PAT_GEN_SBTX_TEST", "PAT_GEN_SBTX_VIF not found in config_db")

    // Enable all components
    env_cfg.pat_gen_sbtx_has_agent      = 1;
    env_cfg.pat_gen_sbtx_has_scoreboard = 1;
    env_cfg.pat_gen_sbtx_has_subscriber = 1;
    env_cfg.active_passive_agents["pat_gen_sbtx"] = UVM_ACTIVE;

    uvm_config_db#(pat_gen_sbtx_env_cfg_obj)::set(this, "env", "cfg", env_cfg);

    env = pat_gen_sbtx_environment::type_id::create("env", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

  task run_phase(uvm_phase phase);
    pat_gen_rst_seq rst_seq;
    pat_gen_base_seq base_seq;
    pat_gen_error_injec_seq err_seq;

    super.run_phase(phase);

    phase.raise_objection(this);

    rst_seq = pat_gen_rst_seq::type_id::create("rst_seq");
    rst_seq.start(env.agt.seqr);

    base_seq = pat_gen_base_seq::type_id::create("base_seq");
    base_seq.start(env.agt.seqr);

    err_seq = pat_gen_error_injec_seq::type_id::create("err_seq");
    err_seq.start(env.agt.seqr);

    #4ns;
    phase.drop_objection(this);
  endtask
endclass

`endif // PAT_GEN_SBTX_BASE_TEST_SVH
