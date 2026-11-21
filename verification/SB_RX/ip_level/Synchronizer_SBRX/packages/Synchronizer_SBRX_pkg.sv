`timescale 1ns/1ps
package Synchronizer_SBRX_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // Shared design parameters

  // Configuration Objects (bottom-up: drv/mon -> agt -> env)
  `include "cfg_obj/Synchronizer_SBRX_drv_mon_cfg_obj.svh"
  `include "cfg_obj/Synchronizer_SBRX_agt_cfg_obj.svh"
  `include "cfg_obj/Synchronizer_SBRX_env_cfg_obj.svh"

  // Sequence Items
  `include "sequences/Synchronizer_SBRX_sequence_item.svh"

  // UVM Sequencer to be able to uvm_declare_p_sequencer
  `include "components/Synchronizer_SBRX_sequencer.svh"

  // Sequences
  `include "sequences/Synchronizer_SBRX_base_sequence.svh"

  // UVM Components (bottom-up)
  `include "components/Synchronizer_SBRX_driver.svh"
  `include "components/Synchronizer_SBRX_monitor.svh"
  `include "components/Synchronizer_SBRX_agent.svh"

  `include "components/Synchronizer_SBRX_scoreboard.svh"
  `include "components/Synchronizer_SBRX_subscriber.svh"
  `include "components/Synchronizer_SBRX_environment.svh"

  // Base Test
  `include "components/Synchronizer_SBRX_base_test.svh"
endpackage
