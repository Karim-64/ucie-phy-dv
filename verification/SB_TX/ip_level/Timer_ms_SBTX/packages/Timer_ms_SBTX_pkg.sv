`timescale 1ns/1ns
package Timer_ms_SBTX_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // Shared design parameters
  parameter CLK_FREQ_HZ = 800_000_000;
  parameter FACTOR = 1000;

  parameter COUNT_MAX = CLK_FREQ_HZ/FACTOR;

  // Configuration Objects (bottom-up: drv/mon -> agt -> env)
  `include "cfg_obj/Timer_ms_SBTX_drv_mon_cfg_obj.svh"
  `include "cfg_obj/Timer_ms_SBTX_agt_cfg_obj.svh"
  `include "cfg_obj/Timer_ms_SBTX_env_cfg_obj.svh"

  // Sequence Items
  `include "sequences/Timer_ms_SBTX_sequence_item.svh"

  // UVM Sequencer to be able to uvm_declare_p_sequencer
  `include "components/Timer_ms_SBTX_sequencer.svh"

  // Sequences
  `include "sequences/Timer_ms_SBTX_reset_sequence.svh"
  `include "sequences/Timer_ms_SBTX_full_counting_sequence.svh"
  `include "sequences/Timer_ms_SBTX_random_sequence.svh"

  // UVM Components (bottom-up)
  `include "components/Timer_ms_SBTX_driver.svh"
  `include "components/Timer_ms_SBTX_monitor.svh"
  `include "components/Timer_ms_SBTX_agent.svh"

  `include "components/Timer_ms_SBTX_scoreboard.svh"
  `include "components/Timer_ms_SBTX_subscriber.svh"
  `include "components/Timer_ms_SBTX_environment.svh"

  // Base Test
  `include "components/Timer_ms_SBTX_base_test.svh"
endpackage
