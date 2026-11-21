`ifndef SERIALIZER_BASE_TEST_SVH
`define SERIALIZER_BASE_TEST_SVH

class Serializer_base_test extends uvm_test;
  `uvm_component_utils(Serializer_base_test)

  Serializer_environment env;
  Serializer_env_cfg_obj env_cfg;

  Serializer_reset_sequence rst_seq;
  Serializer_directed_sequence directed_seq;
  Serializer_random_sequence   random_seq;
  Serializer_disabled_sequence disabled_seq;

  function new(string name = "Serializer_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Create and configure the environment config object
    env_cfg = Serializer_env_cfg_obj::type_id::create("env_cfg");

    // Retrieve the virtual interface from config_db (set in tb_top)
    if (!uvm_config_db#(virtual Serializer_if#())::get(
            this, "", "SERIALIZER_VIF", env_cfg.Serializer_vif))
      `uvm_fatal("SERIALIZER_TEST", "SERIALIZER_VIF not found in config_db")

    // Enable all components
    env_cfg.Serializer_has_agent      = 1;
    env_cfg.Serializer_has_scoreboard = 1;
    env_cfg.Serializer_has_subscriber = 1;
    env_cfg.active_passive_agents["Serializer"] = UVM_ACTIVE;

    uvm_config_db#(Serializer_env_cfg_obj)::set(this, "env", "cfg", env_cfg);

    env = Serializer_environment::type_id::create("env", this);
    rst_seq       = Serializer_reset_sequence::type_id::create("rst_seq");
    directed_seq  = Serializer_directed_sequence::type_id::create("directed_seq");
    random_seq    = Serializer_random_sequence::type_id::create("random_seq");
    disabled_seq   = Serializer_disabled_sequence::type_id::create("disabled_seq");
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
     phase.raise_objection(this);

    `uvm_info("run_phase", "rst_seq sequence start", UVM_MEDIUM)
    rst_seq.start(env.agt.seqr);
    `uvm_info("run_phase", "rst_seq sequence completed", UVM_MEDIUM)

    `uvm_info("run_phase", "directed_seq sequence start", UVM_MEDIUM)
    directed_seq.start(env.agt.seqr);
    `uvm_info("run_phase", "directed_seq sequence completed", UVM_MEDIUM)

    `uvm_info("run_phase", "random_seq sequence start", UVM_MEDIUM)
    random_seq.start(env.agt.seqr);
    `uvm_info("run_phase", "random_seq sequence completed", UVM_MEDIUM)

    `uvm_info("run_phase", "disabled_seq sequence start", UVM_MEDIUM)
    disabled_seq.start(env.agt.seqr);
    `uvm_info("run_phase", "disabled_seq sequence completed", UVM_MEDIUM)

     repeat(1)@(posedge env.cfg.Serializer_vif.MB_CLK);

     phase.drop_objection(this);
  endtask
endclass

`endif // SERIALIZER_BASE_TEST_SVH
