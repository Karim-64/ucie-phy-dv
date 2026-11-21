`timescale 1ns/1ps
package Credits_Handler_SBTX_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // Shared design parameters
  parameter CNT_WIDTH = 4;

  // Configuration Objects (bottom-up: drv/mon -> agt -> env)
  `include "cfg_obj/Credits_Handler_SBTX_drv_mon_cfg_obj.svh"
  `include "cfg_obj/Credits_Handler_SBTX_agt_cfg_obj.svh"
  `include "cfg_obj/Credits_Handler_SBTX_env_cfg_obj.svh"

  // Sequence Items
  `include "sequences/Credits_Handler_SBTX_sequence_item.svh"

  // UVM Sequencer to be able to uvm_declare_p_sequencer
  `include "components/Credits_Handler_SBTX_sequencer.svh"

  // Sequences
  `include "sequences/Credits_Handler_SBTX_rst_sequence.svh"
  `include "sequences/Credits_Handler_SBTX_3_idle_sequence.svh"
  `include "sequences/Credits_Handler_SBTX_protocol_sequence.svh"
  `include "sequences/Credits_Handler_SBTX_concurrent_burst_and_drain_sequence.svh"
  `include "sequences/Credits_Handler_SBTX_mid_drain_rst_sequence.svh"
  `include "sequences/Credits_Handler_SBTX_combinations_sequence.svh"
  `include "sequences/Credits_Handler_SBTX_back_to_back_sequence.svh"
  `include "sequences/Credits_Handler_SBTX_random_sequence.svh"

  // UVM Components (bottom-up)
  `include "components/Credits_Handler_SBTX_driver.svh"
  `include "components/Credits_Handler_SBTX_monitor.svh"
  `include "components/Credits_Handler_SBTX_agent.svh"

  `include "components/Credits_Handler_SBTX_scoreboard.svh"
  `include "components/Credits_Handler_SBTX_subscriber.svh"
  `include "components/Credits_Handler_SBTX_environment.svh"

  // Base Test
  `include "components/Credits_Handler_SBTX_base_test.svh"
endpackage
