`timescale 1ns/1ps
package demux_SBTX_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // Shared design parameters
  parameter DATA_WIDTH = 64;

  // Configuration Objects (bottom-up: drv/mon -> agt -> env)
  `include "cfg_obj/demux_SBTX_drv_mon_cfg_obj.svh"
  `include "cfg_obj/demux_SBTX_agt_cfg_obj.svh"
  `include "cfg_obj/demux_SBTX_env_cfg_obj.svh"

  // Sequence Items
  `include "sequences/demux_SBTX_sequence_item.svh"

  // UVM Sequencer to be able to uvm_declare_p_sequencer
  `include "components/demux_SBTX_sequencer.svh"

  // Sequences
  `include "sequences/demux_SBTX_base_sequence.svh"

  // UVM Components (bottom-up)
  `include "components/demux_SBTX_driver.svh"
  `include "components/demux_SBTX_monitor.svh"
  `include "components/demux_SBTX_agent.svh"

  `include "components/demux_SBTX_scoreboard.svh"
  `include "components/demux_SBTX_subscriber.svh"
  `include "components/demux_SBTX_environment.svh"

  // Base Test
  `include "components/demux_SBTX_base_test.svh"
endpackage
