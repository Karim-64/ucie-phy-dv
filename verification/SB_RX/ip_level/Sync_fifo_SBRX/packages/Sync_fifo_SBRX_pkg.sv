`timescale 1ns/1ps
package Sync_fifo_SBRX_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // Shared design parameters
  parameter DATA_WIDTH = 64;
  parameter FIFO_DEPTH = 64;

  // Configuration Objects (bottom-up: drv/mon -> agt -> env)
  `include "cfg_obj/Sync_fifo_SBRX_drv_mon_cfg_obj.svh"
  `include "cfg_obj/Sync_fifo_SBRX_agt_cfg_obj.svh"
  `include "cfg_obj/Sync_fifo_SBRX_env_cfg_obj.svh"

  // Sequence Items
  `include "sequences/Sync_fifo_SBRX_sequence_item.svh"

  // UVM Sequencer to be able to uvm_declare_p_sequencer
  `include "components/Sync_fifo_SBRX_sequencer.svh"

  // Sequences
  `include "sequences/Sync_fifo_SBRX_base_sequence.svh"

  // UVM Components (bottom-up)
  `include "components/Sync_fifo_SBRX_driver.svh"
  `include "components/Sync_fifo_SBRX_monitor.svh"
  `include "components/Sync_fifo_SBRX_agent.svh"

  `include "components/Sync_fifo_SBRX_scoreboard.svh"
  `include "components/Sync_fifo_SBRX_subscriber.svh"
  `include "components/Sync_fifo_SBRX_environment.svh"

  // Base Test
  `include "components/Sync_fifo_SBRX_base_test.svh"
endpackage
