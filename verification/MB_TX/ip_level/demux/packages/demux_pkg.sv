`timescale 1ns/1ps
package demux_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // Shared design parameters

  // Configuration Objects (bottom-up: drv/mon -> agt -> env)
  `include "cfg_obj/demux_drv_mon_cfg_obj.svh"
  `include "cfg_obj/demux_agt_cfg_obj.svh"
  `include "cfg_obj/demux_env_cfg_obj.svh"

  // Sequence Items
  `include "sequences/demux_sequence_item.svh"

  // UVM Sequencer to be able to uvm_declare_p_sequencer
  `include "components/demux_sequencer.svh"

  // Sequences
  `include "sequences/demux_directed_seq.svh"
  `include "sequences/demux_random_seq.svh"

  // UVM Components (bottom-up)
  `include "components/demux_driver.svh"
  `include "components/demux_monitor.svh"
  `include "components/demux_agent.svh"

  `include "components/demux_scoreboard.svh"
  `include "components/demux_subscriber.svh"
  `include "components/demux_environment.svh"

  // Base Test
  `include "components/demux_base_test.svh"
endpackage
