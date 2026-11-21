`timescale 1ns/1ps
package Timer_SBTX_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // Shared design parameters
  parameter NO_OF_CYCLES = 32;

  // Configuration Objects (bottom-up: drv/mon -> agt -> env)
  `include "cfg_obj/Timer_SBTX_drv_mon_cfg_obj.svh"
  `include "cfg_obj/Timer_SBTX_agt_cfg_obj.svh"
  `include "cfg_obj/Timer_SBTX_env_cfg_obj.svh"

  // Sequence Items
  `include "sequences/Timer_SBTX_sequence_item.svh"

  // UVM Sequencer to be able to uvm_declare_p_sequencer
  `include "components/Timer_SBTX_sequencer.svh"

  // Sequences
  `include "sequences/Timer_SBTX_base_sequence.svh"

  // UVM Components (bottom-up)
  `include "components/Timer_SBTX_driver.svh"
  `include "components/Timer_SBTX_monitor.svh"
  `include "components/Timer_SBTX_agent.svh"

  `include "components/Timer_SBTX_scoreboard.svh"
  `include "components/Timer_SBTX_subscriber.svh"
  `include "components/Timer_SBTX_environment.svh"

  // Base Test
  `include "components/Timer_SBTX_base_test.svh"
endpackage
