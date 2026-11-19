`ifndef PE_SBTX_BASE_TEST_SVH
`define PE_SBTX_BASE_TEST_SVH

class pe_sbtx_base_test extends uvm_test;
  `uvm_component_utils(pe_sbtx_base_test)
  
  pe_sbtx_environment env;
  pe_sbtx_env_cfg_obj env_cfg;
  pe_sbtx_vseq vseq;
  
  function new(string name = "pe_sbtx_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // Create and configure the environment config object
    env_cfg = pe_sbtx_env_cfg_obj::type_id::create("env_cfg");
    
    // Retrieve the virtual interfaces from config_db (set in tb_top)
    if (!uvm_config_db#(virtual pe_sbtx_in_if#(DATA_WIDTH))::get(this, "", "PE_SBTX_PHY_VIF", env_cfg.phy_vif))
      `uvm_fatal("PE_SBTX_TEST", "PE_SBTX_PHY_VIF not found in config_db")
    
    if (!uvm_config_db#(virtual pe_sbtx_in_if#(DATA_WIDTH))::get(this, "", "PE_SBTX_D2D_VIF", env_cfg.d2d_vif))
      `uvm_fatal("PE_SBTX_TEST", "PE_SBTX_D2D_VIF not found in config_db")
    
    if (!uvm_config_db#(virtual pe_sbtx_out_if#(DATA_WIDTH))::get(this, "", "PE_SBTX_FIFO_VIF", env_cfg.fifo_vif))
      `uvm_fatal("PE_SBTX_TEST", "PE_SBTX_FIFO_VIF not found in config_db")
    
    // Assign all env_cfg members for the env
    env_cfg.pe_sbtx_has_D2D_agent = 1;
    env_cfg.pe_sbtx_has_PHY_agent = 1;
    env_cfg.pe_sbtx_has_FIFO_agent = 1;
    env_cfg.pe_sbtx_has_scoreboard = 1;
    env_cfg.pe_sbtx_has_subscriber = 1;
    
    // Set agent active/passive modes
    env_cfg.active_passive_agents["D2D"] = UVM_ACTIVE;
    env_cfg.active_passive_agents["PHY"] = UVM_ACTIVE;
    env_cfg.active_passive_agents["FIFO"] = UVM_PASSIVE;
    
    env = pe_sbtx_environment::type_id::create("env", this);
    uvm_config_db#(pe_sbtx_env_cfg_obj)::set(this, "env", "cfg", env_cfg);
  endfunction
  
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction
  
  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    vseq = pe_sbtx_vseq::type_id::create("vseq");
    
    phase.raise_objection(this);
    vseq.start(env.vseqr);
    phase.drop_objection(this);
    #4ns;
  endtask
endclass

`endif // PE_SBTX_BASE_TEST_SVH