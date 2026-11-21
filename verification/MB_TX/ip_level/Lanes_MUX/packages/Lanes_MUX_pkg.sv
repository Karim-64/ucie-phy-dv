`timescale 1ns/1ps
package Lanes_MUX_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // Shared design parameters

  // Configuration Objects (bottom-up: drv/mon -> agt -> env)
  `include "cfg_obj/Lanes_MUX_drv_mon_cfg_obj.svh"
  `include "cfg_obj/Lanes_MUX_agt_cfg_obj.svh"
  `include "cfg_obj/Lanes_MUX_env_cfg_obj.svh"

  // Sequence Items
  `include "sequences/Lanes_MUX_sequence_item.svh"

  // UVM Sequencer to be able to uvm_declare_p_sequencer
  `include "components/Lanes_MUX_sequencer.svh"

  // Sequences

  `include "sequences/Lanes_MUX_corner_sequence.svh"
  `include "sequences/Lanes_MUX_isolation_sequence.svh"
  `include "sequences/Lanes_MUX_rand_sequence.svh"
  `include "sequences/Lanes_MUX_base_sequence.svh"

  // UVM Components (bottom-up)
  `include "components/Lanes_MUX_driver.svh"
  `include "components/Lanes_MUX_monitor.svh"
  `include "components/Lanes_MUX_agent.svh"

  `include "components/Lanes_MUX_scoreboard.svh"
  `include "components/Lanes_MUX_subscriber.svh"
  `include "components/Lanes_MUX_environment.svh"

  // Base Test
  `include "components/Lanes_MUX_base_test.svh"
endpackage
