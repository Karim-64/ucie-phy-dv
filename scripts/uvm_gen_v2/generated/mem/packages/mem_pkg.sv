`timescale 1ns/1ps
package mem_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // Shared design parameters
  parameter DATA_WIDTH = 128;
  parameter ADDRESS_WIDTH = 4;

  // Configuration Objects (bottom-up: drv/mon -> agt -> env)
  `include "cfg_obj/mem_drv_mon_cfg_obj.svh"
  `include "cfg_obj/mem_agt_cfg_obj.svh"
  `include "cfg_obj/mem_env_cfg_obj.svh"

  // Sequence Items
  `include "sequences/mem_sequence_item.svh"

  // UVM Sequencer to be able to uvm_declare_p_sequencer
  `include "components/mem_sequencer.svh"

  // Sequences
  `include "sequences/mem_base_sequence.svh"

  // UVM Components (bottom-up)
  `include "components/mem_driver.svh"
  `include "components/mem_monitor.svh"
  `include "components/mem_agent.svh"

  `include "components/mem_scoreboard.svh"
  `include "components/mem_subscriber.svh"
  `include "components/mem_environment.svh"

  // Base Test
  `include "components/mem_base_test.svh"
endpackage
