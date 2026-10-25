`timescale 1ns/1ps
package fifo_rd_mbrx_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // Shared design parameters
  parameter P_SIZE = 4;

  // Configuration Objects (bottom-up: drv/mon -> agt -> env)
  `include "cfg_obj/fifo_rd_mbrx_drv_mon_cfg_obj.svh"
  `include "cfg_obj/fifo_rd_mbrx_agt_cfg_obj.svh"
  `include "cfg_obj/fifo_rd_mbrx_env_cfg_obj.svh"

  // Sequence Items
  `include "sequences/fifo_rd_mbrx_sequence_item.svh"

  // UVM Sequencer to be able to uvm_declare_p_sequencer
  `include "components/fifo_rd_mbrx_sequencer.svh"

  // Sequences
  `include "sequences/fifo_rd_mbrx_base_sequence.svh"

  // UVM Components (bottom-up)
  `include "components/fifo_rd_mbrx_driver.svh"
  `include "components/fifo_rd_mbrx_monitor.svh"
  `include "components/fifo_rd_mbrx_agent.svh"

  `include "components/fifo_rd_mbrx_scoreboard.svh"
  `include "components/fifo_rd_mbrx_subscriber.svh"
  `include "components/fifo_rd_mbrx_environment.svh"

  // Base Test
  `include "components/fifo_rd_mbrx_base_test.svh"
endpackage
