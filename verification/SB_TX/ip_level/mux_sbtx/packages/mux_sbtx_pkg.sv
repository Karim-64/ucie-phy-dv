`timescale 1ns/1ps
package mux_sbtx_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // Shared design parameters
  parameter INPUT_WIDTH = 5;

  // Configuration Objects (bottom-up: drv/mon -> agt -> env)
  `include "cfg_obj/mux_sbtx_drv_mon_cfg_obj.svh"
  `include "cfg_obj/mux_sbtx_agt_cfg_obj.svh"
  `include "cfg_obj/mux_sbtx_env_cfg_obj.svh"

  // Sequence Items
  `include "sequences/mux_sbtx_sequence_item.svh"

  // UVM Sequencer to be able to uvm_declare_p_sequencer
  `include "components/mux_sbtx_sequencer.svh"

  // Sequences
  `include "sequences/mux_sbtx_corner_seq.svh"
  `include "sequences/mux_sbtx_isolation_seq.svh"
  `include "sequences/mux_sbtx_rand_seq.svh"
  
  // UVM Components (bottom-up)
  `include "components/mux_sbtx_driver.svh"
  `include "components/mux_sbtx_monitor.svh"
  `include "components/mux_sbtx_agent.svh"

  `include "components/mux_sbtx_scoreboard.svh"
  `include "components/mux_sbtx_subscriber.svh"
  `include "components/mux_sbtx_environment.svh"

  // Base Test
  `include "components/mux_sbtx_base_test.svh"
endpackage
