`timescale 1ns/1ps
package Packet_buffer_SBRX_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // Shared design parameters
  parameter DATA_WIDTH = 64;
  parameter DEPTH = 2;

  // Configuration Objects (bottom-up: drv/mon -> agt -> env)
  `include "cfg_obj/Packet_buffer_SBRX_drv_mon_cfg_obj.svh"
  `include "cfg_obj/Packet_buffer_SBRX_agt_cfg_obj.svh"
  `include "cfg_obj/Packet_buffer_SBRX_env_cfg_obj.svh"

  // Sequence Items
  `include "sequences/Packet_buffer_SBRX_sequence_item.svh"

  // UVM Sequencer to be able to uvm_declare_p_sequencer
  `include "components/Packet_buffer_SBRX_sequencer.svh"

  // Sequences
  `include "sequences/Packet_buffer_SBRX_base_sequence.svh"
  `include "sequences/Packet_buffer_SBRX_base_sequence.svh"
  `include "sequences/Packet_buffer_SBRX_rst_sequence.svh"
  `include "sequences/Packet_buffer_SBRX_balanced_sequence.svh"
  `include "sequences/Packet_buffer_SBRX_heavy_rd_sequence.svh"
  `include "sequences/Packet_buffer_SBRX_heavy_wr_sequence.svh"
  `include "sequences/Packet_buffer_SBRX_rd_only_sequence.svh"
  `include "sequences/Packet_buffer_SBRX_wr_only_sequence.svh"
  `include "sequences/Packet_buffer_SBRX_wrap_around_sequence.svh"
  `include "sequences/Packet_buffer_SBRX_alternate_sequence.svh"

  // UVM Components (bottom-up)
  `include "components/Packet_buffer_SBRX_driver.svh"
  `include "components/Packet_buffer_SBRX_monitor.svh"
  `include "components/Packet_buffer_SBRX_agent.svh"

  `include "components/Packet_buffer_SBRX_scoreboard.svh"
  `include "components/Packet_buffer_SBRX_subscriber.svh"
  `include "components/Packet_buffer_SBRX_environment.svh"

  // Base Test
  `include "components/Packet_buffer_SBRX_base_test.svh"
endpackage
