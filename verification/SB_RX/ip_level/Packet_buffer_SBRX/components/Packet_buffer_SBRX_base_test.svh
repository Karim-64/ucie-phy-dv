`ifndef PACKET_BUFFER_SBRX_BASE_TEST_SVH
`define PACKET_BUFFER_SBRX_BASE_TEST_SVH

class Packet_buffer_SBRX_base_test extends uvm_test;
  `uvm_component_utils(Packet_buffer_SBRX_base_test)

  Packet_buffer_SBRX_environment env;
  Packet_buffer_SBRX_env_cfg_obj env_cfg;

  Packet_buffer_SBRX_rst_sequence          rst_seq;
  Packet_buffer_SBRX_wr_only_sequence      wr_seq;
  Packet_buffer_SBRX_rd_only_sequence      rd_seq;
  Packet_buffer_SBRX_alternate_sequence   alt_seq;
  Packet_buffer_SBRX_balanced_sequence    bal_seq;
  Packet_buffer_SBRX_heavy_wr_sequence    heavy_wr_seq;
  Packet_buffer_SBRX_heavy_rd_sequence    heavy_rd_seq;
  Packet_buffer_SBRX_wrap_around_sequence wrap_seq;

  function new(string name = "Packet_buffer_SBRX_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Create and configure the environment config object
    env_cfg = Packet_buffer_SBRX_env_cfg_obj::type_id::create("env_cfg");

    // Retrieve the virtual interface from config_db (set in tb_top)
    if (!uvm_config_db#(virtual Packet_buffer_SBRX_if#(DATA_WIDTH, DEPTH))::get(
            this, "", "PACKET_BUFFER_SBRX_VIF", env_cfg.Packet_buffer_SBRX_vif))
      `uvm_fatal("PACKET_BUFFER_SBRX_TEST", "PACKET_BUFFER_SBRX_VIF not found in config_db")

    // Enable all components
    env_cfg.Packet_buffer_SBRX_has_agent      = 1;
    env_cfg.Packet_buffer_SBRX_has_scoreboard = 1;
    env_cfg.Packet_buffer_SBRX_has_subscriber = 1;
    env_cfg.active_passive_agents["Packet_buffer_SBRX"] = UVM_ACTIVE;

    uvm_config_db#(Packet_buffer_SBRX_env_cfg_obj)::set(this, "env", "cfg", env_cfg);

    env = Packet_buffer_SBRX_environment::type_id::create("env", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    phase.raise_objection(this);

    // 1. Reset the FIFO
    rst_seq = Packet_buffer_SBRX_rst_sequence::type_id::create("rst_seq");
    rst_seq.start(env.agt.seqr);

    // 2. Write-only sequence
    wr_seq = Packet_buffer_SBRX_wr_only_sequence::type_id::create("wr_seq");
    wr_seq.start(env.agt.seqr);

    // 3. Read-only sequence
    rd_seq = Packet_buffer_SBRX_rd_only_sequence::type_id::create("rd_seq");
    rd_seq.start(env.agt.seqr);

    // 4. Alternate write and read
    alt_seq = Packet_buffer_SBRX_alternate_sequence::type_id::create("alt_seq");
    alt_seq.start(env.agt.seqr);

    // 5. Balanced traffic
    bal_seq = Packet_buffer_SBRX_balanced_sequence::type_id::create("bal_seq");
    bal_seq.start(env.agt.seqr);

    // 6. Heavy write traffic
    heavy_wr_seq = Packet_buffer_SBRX_heavy_wr_sequence::type_id::create("heavy_wr_seq");
    heavy_wr_seq.start(env.agt.seqr);

    // 7. Heavy read traffic
    heavy_rd_seq = Packet_buffer_SBRX_heavy_rd_sequence::type_id::create("heavy_rd_seq");
    heavy_rd_seq.start(env.agt.seqr);

    // 8. Pointer wrap-around / boundary test
    wrap_seq = Packet_buffer_SBRX_wrap_around_sequence::type_id::create("wrap_seq");
    wrap_seq.start(env.agt.seqr);

    phase.drop_objection(this);
  endtask
endclass

`endif // PACKET_BUFFER_SBRX_BASE_TEST_SVH
