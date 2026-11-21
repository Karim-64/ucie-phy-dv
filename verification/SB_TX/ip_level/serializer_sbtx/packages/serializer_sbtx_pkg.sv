`timescale 1ns/1ps
package serializer_sbtx_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // Shared design parameters
  parameter DATA_WIDTH = 64;

  // Configuration Objects (bottom-up: drv/mon -> agt -> env)
  `include "cfg_obj/serializer_sbtx_drv_mon_cfg_obj.svh"
  `include "cfg_obj/serializer_sbtx_agt_cfg_obj.svh"
  `include "cfg_obj/serializer_sbtx_env_cfg_obj.svh"

  // Sequence Items
  `include "sequences/serializer_sbtx_sequence_item.svh"

  // UVM Sequencer to be able to uvm_declare_p_sequencer
  `include "components/serializer_sbtx_sequencer.svh"

  // Sequences
  `include "sequences/serializer_sbtx_base_sequence.svh"

  // UVM Components (bottom-up)
  `include "components/serializer_sbtx_driver.svh"
  `include "components/serializer_sbtx_monitor.svh"
  `include "components/serializer_sbtx_agent.svh"

  `include "components/serializer_sbtx_scoreboard.svh"
  `include "components/serializer_sbtx_subscriber.svh"
  `include "components/serializer_sbtx_environment.svh"

  // Base Test
  `include "components/serializer_sbtx_base_test.svh"
endpackage
