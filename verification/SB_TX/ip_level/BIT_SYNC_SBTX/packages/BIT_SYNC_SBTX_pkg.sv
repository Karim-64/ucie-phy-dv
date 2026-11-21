`timescale 1ns/1ps
package BIT_SYNC_SBTX_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // Shared design parameters
  parameter NUM_STAGES = 2;
  parameter BUS_WIDTH = 5;

  // Configuration Objects (bottom-up: drv/mon -> agt -> env)
  `include "cfg_obj/BIT_SYNC_SBTX_drv_mon_cfg_obj.svh"
  `include "cfg_obj/BIT_SYNC_SBTX_agt_cfg_obj.svh"
  `include "cfg_obj/BIT_SYNC_SBTX_env_cfg_obj.svh"

  // Sequence Items
  `include "sequences/BIT_SYNC_SBTX_sequence_item.svh"

  // UVM Sequencer to be able to uvm_declare_p_sequencer
  `include "components/BIT_SYNC_SBTX_sequencer.svh"

  // Sequences
  `include "sequences/BIT_SYNC_SBTX_base_sequence.svh"

  // UVM Components (bottom-up)
  `include "components/BIT_SYNC_SBTX_driver.svh"
  `include "components/BIT_SYNC_SBTX_monitor.svh"
  `include "components/BIT_SYNC_SBTX_agent.svh"

  `include "components/BIT_SYNC_SBTX_scoreboard.svh"
  `include "components/BIT_SYNC_SBTX_subscriber.svh"
  `include "components/BIT_SYNC_SBTX_environment.svh"

  // Base Test
  `include "components/BIT_SYNC_SBTX_base_test.svh"
endpackage
