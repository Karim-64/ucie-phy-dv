class Enable_Generator_MBRX_base_test extends uvm_test;
  `uvm_component_utils(Enable_Generator_MBRX_base_test)

  Enable_Generator_MBRX_environment env;
  Enable_Generator_MBRX_env_cfg_obj env_cfg;

  Enable_Generator_MBRX_Reset_Sequence reset_seq;
  Enable_Generator_MBRX_Chunk_Marker_Sequence chunk_marker_seq;
  Enable_Generator_MBRX_Width_Degrade_Sequence width_degrade_seq;
  Enable_Generator_MBRX_Comparison_Type_Sequence comparison_type_seq;
  Enable_Generator_MBRX_Vchk_EN_Sequence vchk_en_seq;
  Enable_Generator_MBRX_Data_Comparator_EN_Sequence data_comparator_en_seq;
  Enable_Generator_MBRX_Descr_EN_Sequence descr_en_seq;
  Enable_Generator_MBRX_LFSR_SEL_Sequence lfsr_sel_seq;
  Enable_Generator_MBRX_inject_error_sequence inject_error_seq;
  Enable_Generator_MBRX_random_stress_sequence random_stress_seq;

  function new(string name = "Enable_Generator_MBRX_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    env_cfg = Enable_Generator_MBRX_env_cfg_obj::type_id::create("env_cfg");

    if (!uvm_config_db#(virtual Enable_Generator_MBRX_if#(NUM_LANES, FRAME_LENGTH))::get(
            this, "", "ENABLE_GENERATOR_MBRX_VIF", env_cfg.Enable_Generator_MBRX_vif))
      `uvm_fatal("ENABLE_GENERATOR_MBRX_TEST", "ENABLE_GENERATOR_MBRX_VIF not found in config_db")

    env_cfg.Enable_Generator_MBRX_has_agent      = 1;
    env_cfg.Enable_Generator_MBRX_has_scoreboard = 1;
    env_cfg.Enable_Generator_MBRX_has_subscriber = 1;
    env_cfg.active_passive_agents["Enable_Generator_MBRX"] = UVM_ACTIVE;

    uvm_config_db#(Enable_Generator_MBRX_env_cfg_obj)::set(this, "env", "cfg", env_cfg);

    env = Enable_Generator_MBRX_environment::type_id::create("env", this);

    reset_seq = Enable_Generator_MBRX_Reset_Sequence::type_id::create("reset_seq");
    chunk_marker_seq = Enable_Generator_MBRX_Chunk_Marker_Sequence::type_id::create("chunk_marker_seq");
    width_degrade_seq = Enable_Generator_MBRX_Width_Degrade_Sequence::type_id::create("width_degrade_seq");
    comparison_type_seq = Enable_Generator_MBRX_Comparison_Type_Sequence::type_id::create("comparison_type_seq");
    vchk_en_seq = Enable_Generator_MBRX_Vchk_EN_Sequence::type_id::create("vchk_en_seq");
    data_comparator_en_seq = Enable_Generator_MBRX_Data_Comparator_EN_Sequence::type_id::create("data_comparator_en_seq");
    descr_en_seq = Enable_Generator_MBRX_Descr_EN_Sequence::type_id::create("descr_en_seq");
    lfsr_sel_seq = Enable_Generator_MBRX_LFSR_SEL_Sequence::type_id::create("lfsr_sel_seq");
    inject_error_seq = Enable_Generator_MBRX_inject_error_sequence::type_id::create("inject_error_seq");
    random_stress_seq = Enable_Generator_MBRX_random_stress_sequence::type_id::create("random_stress_seq");
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    phase.raise_objection(this);

    `uvm_info("run_phase", "Reset sequence start", UVM_MEDIUM)
    reset_seq.start(env.agt.seqr);
    `uvm_info("run_phase", "Reset sequence complete", UVM_MEDIUM)

    `uvm_info("run_phase", "Chunk-marker sequence start", UVM_MEDIUM)
    chunk_marker_seq.start(env.agt.seqr);
    `uvm_info("run_phase", "Chunk-marker sequence complete", UVM_MEDIUM)

    `uvm_info("run_phase", "Width-degrade sequence start", UVM_MEDIUM)
    width_degrade_seq.start(env.agt.seqr);
    `uvm_info("run_phase", "Width-degrade sequence complete", UVM_MEDIUM)

    `uvm_info("run_phase", "Comparison-type sequence start", UVM_MEDIUM)
    comparison_type_seq.start(env.agt.seqr);
    `uvm_info("run_phase", "Comparison-type sequence complete", UVM_MEDIUM)

    `uvm_info("run_phase", "VCHK_EN sequence start", UVM_MEDIUM)
    vchk_en_seq.start(env.agt.seqr);
    `uvm_info("run_phase", "VCHK_EN sequence complete", UVM_MEDIUM)

    `uvm_info("run_phase", "Data_Comparator_EN sequence start", UVM_MEDIUM)
    data_comparator_en_seq.start(env.agt.seqr);
    `uvm_info("run_phase", "Data_Comparator_EN sequence complete", UVM_MEDIUM)

    `uvm_info("run_phase", "Descr_EN sequence start", UVM_MEDIUM)
    descr_en_seq.start(env.agt.seqr);
    `uvm_info("run_phase", "Descr_EN sequence complete", UVM_MEDIUM)

    `uvm_info("run_phase", "LFSR_SEL sequence start", UVM_MEDIUM)
    lfsr_sel_seq.start(env.agt.seqr);
    `uvm_info("run_phase", "LFSR_SEL sequence complete", UVM_MEDIUM)

    `uvm_info("run_phase", "Invalid-width injection sequence start", UVM_MEDIUM)
    inject_error_seq.start(env.agt.seqr);
    `uvm_info("run_phase", "Invalid-width injection sequence complete", UVM_MEDIUM)

    `uvm_info("run_phase", "Random-stress sequence start", UVM_MEDIUM)
    random_stress_seq.start(env.agt.seqr);
    `uvm_info("run_phase", "Random-stress sequence complete", UVM_MEDIUM)

    repeat (1) @(posedge env_cfg.Enable_Generator_MBRX_vif.CLK);
    phase.drop_objection(this);
  endtask
endclass