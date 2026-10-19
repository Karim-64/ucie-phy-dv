`timescale 1ns/1ps
package DMUX_1x4_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // Shared design parameters
  parameter DATA_WIDTH = 64;
  parameter DESTINATION_SEL = 2;

  // Configuration Objects (bottom-up: drv/mon -> agt -> env)
  `include "cfg_obj/DMUX_1x4_drv_mon_cfg_obj.svh"
  `include "cfg_obj/DMUX_1x4_agt_cfg_obj.svh"
  `include "cfg_obj/DMUX_1x4_env_cfg_obj.svh"

  // Sequence Items
  `include "sequences/DMUX_1x4_sequence_item.svh"

  // UVM Sequencer to be able to uvm_declare_p_sequencer
  `include "components/DMUX_1x4_sequencer.svh"

  // Sequences
  `include "sequences/DMUX_1x4_base_sequence.svh"

  // UVM Components (bottom-up)
  `include "components/DMUX_1x4_driver.svh"
  `include "components/DMUX_1x4_monitor.svh"
  `include "components/DMUX_1x4_agent.svh"

  `include "components/DMUX_1x4_scoreboard.svh"
  `include "components/DMUX_1x4_subscriber.svh"
  `include "components/DMUX_1x4_environment.svh"

  // Base Test
  `include "components/DMUX_1x4_base_test.svh"
endpackage
