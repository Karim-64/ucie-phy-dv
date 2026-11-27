`timescale 1ns/1ps
package lfsr_per_lane_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // Shared design parameters
  parameter WIDTH = 23;
  parameter Seed = 23'h1DBFBC;

  // Configuration Objects (bottom-up: drv/mon -> agt -> env)
  `include "cfg_obj/lfsr_per_lane_drv_mon_cfg_obj.svh"
  `include "cfg_obj/lfsr_per_lane_agt_cfg_obj.svh"
  `include "cfg_obj/lfsr_per_lane_env_cfg_obj.svh"

  // Sequence Items
  `include "sequences/lfsr_per_lane_sequence_item.svh"

  // UVM Sequencer to be able to uvm_declare_p_sequencer
  `include "components/lfsr_per_lane_sequencer.svh"

  // Sequences
  `include "sequences/lfsr_per_lane_random_sequence.svh"
  `include "sequences/lfsr_per_lane_normal_sequence.svh"
  `include "sequences/lfsr_per_lane_training_sequence.svh"
  `include "sequences/lfsr_per_lane_bypass_sequence.svh"
  `include "sequences/lfsr_per_lane_pn_enable_sequence.svh"
  `include "sequences/lfsr_per_lane_opcode_change_sequence.svh"
  `include "sequences/lfsr_per_lane_error_injection_sequence.svh"
  `include "sequences/lfsr_per_lane_reset_sequence.svh"
  `include "sequences/lfsr_per_lane_base_sequence.svh"

  // UVM Components (bottom-up)
  `include "components/lfsr_per_lane_driver.svh"
  `include "components/lfsr_per_lane_monitor.svh"
  `include "components/lfsr_per_lane_agent.svh"

  `include "components/lfsr_per_lane_scoreboard.svh"
  `include "components/lfsr_per_lane_subscriber.svh"
  `include "components/lfsr_per_lane_environment.svh"

  // Base Test
  `include "components/lfsr_per_lane_base_test.svh"
endpackage
