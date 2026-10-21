`timescale 1ns/1ps
package wr_control_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // Shared design parameters
  parameter W_D_SIZE = 128;
  parameter WIDTH_DEGRADE_LENGTH = 3;

  // Configuration Objects (bottom-up: drv/mon -> agt -> env)
  `include "cfg_obj/wr_control_drv_mon_cfg_obj.svh"
  `include "cfg_obj/wr_control_agt_cfg_obj.svh"
  `include "cfg_obj/wr_control_env_cfg_obj.svh"

  // Sequence Items
  `include "sequences/wr_control_sequence_item.svh"

  // UVM Sequencer to be able to uvm_declare_p_sequencer
  `include "components/wr_control_sequencer.svh"

  // Sequences
  `include "sequences/wr_control_base_sequence.svh"
  `include "sequences/wr_control_degraded_lower_sequence.svh"
  `include "sequences/wr_control_degraded_upper_sequence.svh"
  `include "sequences/wr_control_reset_sequence.svh"
  `include "sequences/wr_control_full_width_sequence.svh"
  `include "sequences/wr_control_negative_sequence.svh"

  // UVM Components (bottom-up)
  `include "components/wr_control_driver.svh"
  `include "components/wr_control_monitor.svh"
  `include "components/wr_control_agent.svh"

  `include "components/wr_control_scoreboard.svh"
  `include "components/wr_control_subscriber.svh"
  `include "components/wr_control_environment.svh"

  // Base Test
  `include "components/wr_control_base_test.svh"
endpackage
