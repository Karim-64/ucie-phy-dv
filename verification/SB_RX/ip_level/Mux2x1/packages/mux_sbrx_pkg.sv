`timescale 1ns/1ps
package mux_sbrx_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // Shared design parameters
  parameter INPUT_WIDTH = 5;

  // Configuration Objects (bottom-up: drv/mon -> agt -> env)
  `include "cfg_obj/mux_sbrx_drv_mon_cfg_obj.svh"
  `include "cfg_obj/mux_sbrx_agt_cfg_obj.svh"
  `include "cfg_obj/mux_sbrx_env_cfg_obj.svh"

  // Sequence Items
  `include "sequences/mux_sbrx_sequence_item.svh"

  // UVM Sequencer to be able to uvm_declare_p_sequencer
  `include "components/mux_sbrx_sequencer.svh"

  // Sequences
  `include "sequences/mux_sbrx_corner_seq.svh"
  `include "sequences/mux_sbrx_isolation_seq.svh"
  `include "sequences/mux_sbrx_rand_seq.svh"
  
  // UVM Components (bottom-up)
  `include "components/mux_sbrx_driver.svh"
  `include "components/mux_sbrx_monitor.svh"
  `include "components/mux_sbrx_agent.svh"

  `include "components/mux_sbrx_scoreboard.svh"
  `include "components/mux_sbrx_subscriber.svh"
  `include "components/mux_sbrx_environment.svh"

  // Base Test
  `include "components/mux_sbrx_base_test.svh"
endpackage
