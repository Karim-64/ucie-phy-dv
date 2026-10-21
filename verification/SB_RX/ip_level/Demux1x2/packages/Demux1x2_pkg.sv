`timescale 1ns/1ps
package Demux1x2_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // Shared design parameters
  parameter DATA_WIDTH = 64;

  // Configuration Objects (bottom-up: drv/mon -> agt -> env)
  `include "cfg_obj/Demux1x2_drv_mon_cfg_obj.svh"
  `include "cfg_obj/Demux1x2_agt_cfg_obj.svh"
  `include "cfg_obj/Demux1x2_env_cfg_obj.svh"

  // Sequence Items
  `include "sequences/Demux1x2_sequence_item.svh"

  // UVM Sequencer to be able to uvm_declare_p_sequencer
  `include "components/Demux1x2_sequencer.svh"

  // Sequences
  `include "sequences/Demux1x2_base_sequence.svh"

  // UVM Components (bottom-up)
  `include "components/Demux1x2_driver.svh"
  `include "components/Demux1x2_monitor.svh"
  `include "components/Demux1x2_agent.svh"

  `include "components/Demux1x2_scoreboard.svh"
  `include "components/Demux1x2_subscriber.svh"
  `include "components/Demux1x2_environment.svh"

  // Base Test
  `include "components/Demux1x2_base_test.svh"
endpackage
