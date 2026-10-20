`timescale 1ns/1ps
package DEMUX_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // Shared design parameters

  // Configuration Objects (bottom-up: drv/mon -> agt -> env)
  `include "cfg_obj/DEMUX_drv_mon_cfg_obj.svh"
  `include "cfg_obj/DEMUX_agt_cfg_obj.svh"
  `include "cfg_obj/DEMUX_env_cfg_obj.svh"

  // Sequence Items
  `include "sequences/DEMUX_sequence_item.svh"

  // UVM Sequencer to be able to uvm_declare_p_sequencer
  `include "components/DEMUX_sequencer.svh"

  // Sequences
  `include "sequences/DEMUX_base_sequence.svh"

  // UVM Components (bottom-up)
  `include "components/DEMUX_driver.svh"
  `include "components/DEMUX_monitor.svh"
  `include "components/DEMUX_agent.svh"

  `include "components/DEMUX_scoreboard.svh"
  `include "components/DEMUX_subscriber.svh"
  `include "components/DEMUX_environment.svh"

  // Base Test
  `include "components/DEMUX_base_test.svh"
endpackage
