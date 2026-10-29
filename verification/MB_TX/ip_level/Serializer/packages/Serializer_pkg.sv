`timescale 1ns/1ps
package Serializer_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // Shared design parameters

  // Configuration Objects (bottom-up: drv/mon -> agt -> env)
  `include "cfg_obj/Serializer_drv_mon_cfg_obj.svh"
  `include "cfg_obj/Serializer_agt_cfg_obj.svh"
  `include "cfg_obj/Serializer_env_cfg_obj.svh"

  // Sequence Items
  `include "sequences/Serializer_sequence_item.svh"

  // UVM Sequencer to be able to uvm_declare_p_sequencer
  `include "components/Serializer_sequencer.svh"

  // Sequences
  `include "sequences/Serializer_base_sequence.svh"

  // UVM Components (bottom-up)
  `include "components/Serializer_driver.svh"
  `include "components/Serializer_monitor.svh"
  `include "components/Serializer_agent.svh"

  `include "components/Serializer_scoreboard.svh"
  `include "components/Serializer_subscriber.svh"
  `include "components/Serializer_environment.svh"

  // Base Test
  `include "components/Serializer_base_test.svh"
endpackage
