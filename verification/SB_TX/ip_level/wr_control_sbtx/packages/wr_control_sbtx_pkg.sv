`timescale 1ns/1ps
package wr_control_sbtx_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // Shared design parameters
  parameter NC = 32;

  // Configuration Objects (bottom-up: drv/mon -> agt -> env)
  `include "cfg_obj/wr_control_sbtx_drv_mon_cfg_obj.svh"
  `include "cfg_obj/wr_control_sbtx_agt_cfg_obj.svh"
  `include "cfg_obj/wr_control_sbtx_env_cfg_obj.svh"

  // Sequence Items
  `include "sequences/wr_control_sbtx_sequence_item.svh"
  `include "sequences/wr_control_weighted_seq_item.svh"

  // UVM Sequencer to be able to uvm_declare_p_sequencer
  `include "components/wr_control_sbtx_sequencer.svh"

  // Sequences
  `include "sequences/wr_control_sbtx_base_sequence.svh"
  `include "sequences/wr_control_sbtx_all_opcodes_seq.svh"
  `include "sequences/wr_control_sbtx_directed_seq.svh"
  `include "sequences/wr_control_sbtx_randomized_sequence.svh"


  // UVM Components (bottom-up)
  `include "components/wr_control_sbtx_driver.svh"
  `include "components/wr_control_sbtx_monitor.svh"
  `include "components/wr_control_sbtx_agent.svh"

  `include "components/wr_control_sbtx_scoreboard.svh"
  `include "components/wr_control_sbtx_subscriber.svh"
  `include "components/wr_control_sbtx_environment.svh"

  // Base Test
  `include "components/wr_control_sbtx_base_test.svh"
endpackage
