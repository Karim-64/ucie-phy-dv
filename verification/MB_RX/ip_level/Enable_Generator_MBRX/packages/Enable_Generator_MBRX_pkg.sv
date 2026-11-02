`timescale 1ns/1ps
package Enable_Generator_MBRX_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // Shared design parameters
  parameter NUM_LANES = 16;
  parameter FRAME_LENGTH = 8;

  // Configuration Objects (bottom-up: drv/mon -> agt -> env)
  `include "cfg_obj/Enable_Generator_MBRX_drv_mon_cfg_obj.svh"
  `include "cfg_obj/Enable_Generator_MBRX_agt_cfg_obj.svh"
  `include "cfg_obj/Enable_Generator_MBRX_env_cfg_obj.svh"

  // Sequence Items
  `include "sequences/Enable_Generator_MBRX_sequence_item.svh"

  // UVM Sequencer to be able to uvm_declare_p_sequencer
  `include "components/Enable_Generator_MBRX_sequencer.svh"

  // Sequences
  `include "sequences/Enable_Generator_MBRX_base_sequence.svh"

  // UVM Components (bottom-up)
  `include "components/Enable_Generator_MBRX_driver.svh"
  `include "components/Enable_Generator_MBRX_monitor.svh"
  `include "components/Enable_Generator_MBRX_agent.svh"

  `include "components/Enable_Generator_MBRX_scoreboard.svh"
  `include "components/Enable_Generator_MBRX_subscriber.svh"
  `include "components/Enable_Generator_MBRX_environment.svh"

  // Base Test
  `include "components/Enable_Generator_MBRX_base_test.svh"
endpackage
