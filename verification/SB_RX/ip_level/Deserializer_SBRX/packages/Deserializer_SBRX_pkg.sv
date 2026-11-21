`timescale 1ns/1ps
package Deserializer_SBRX_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // Shared design parameters
  parameter DATA_WIDTH = 64;

  // Configuration Objects (bottom-up: drv/mon -> agt -> env)
  `include "cfg_obj/Deserializer_SBRX_drv_mon_cfg_obj.svh"
  `include "cfg_obj/Deserializer_SBRX_agt_cfg_obj.svh"
  `include "cfg_obj/Deserializer_SBRX_env_cfg_obj.svh"

  // Sequence Items
  `include "sequences/Deserializer_SBRX_sequence_item.svh"

  // UVM Sequencers (needed before sequences for uvm_declare_p_sequencer)
  `include "components/Deserializer_SBRX_sequencer.svh"
  `include "components/Deserializer_SBRX_sequencer2.svh"
  `include "components/Deserializer_SBRX_Virtual_sequencer.svh"

  // Sequences
  `include "sequences/Deserializer_SBRX_base_sequence.svh"
  `include "sequences/Deserializer_SBRX_Virtual_sequence.svh"

  // UVM Components (bottom-up)
  `include "components/Deserializer_SBRX_driver.svh"
  `include "components/Deserializer_SBRX_driver2.svh"
  `include "components/Deserializer_SBRX_monitor.svh"
  `include "components/Deserializer_SBRX_monitor2.svh"
  `include "components/Deserializer_SBRX_agent.svh"
  `include "components/Deserializer_SBRX_agent2.svh"

  `include "components/Deserializer_SBRX_scoreboard.svh"
  `include "components/Deserializer_SBRX_subscriber.svh"
  `include "components/Deserializer_SBRX_environment.svh"

  // Base Test
  `include "components/Deserializer_SBRX_base_test.svh"
endpackage
