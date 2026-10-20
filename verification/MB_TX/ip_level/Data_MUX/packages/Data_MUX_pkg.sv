`timescale 1ns/1ps
package Data_MUX_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // Shared design parameters

  // Configuration Objects (bottom-up: drv/mon -> agt -> env)
  `include "cfg_obj/Data_MUX_drv_mon_cfg_obj.svh"
  `include "cfg_obj/Data_MUX_agt_cfg_obj.svh"
  `include "cfg_obj/Data_MUX_env_cfg_obj.svh"

  // Sequence Items
  `include "sequences/Data_MUX_sequence_item.svh"

  // UVM Sequencer to be able to uvm_declare_p_sequencer
  `include "components/Data_MUX_sequencer.svh"

  // Sequences
  `include "sequences/Data_MUX_base_sequence.svh"

  // UVM Components (bottom-up)
  `include "components/Data_MUX_driver.svh"
  `include "components/Data_MUX_monitor.svh"
  `include "components/Data_MUX_agent.svh"

  `include "components/Data_MUX_scoreboard.svh"
  `include "components/Data_MUX_subscriber.svh"
  `include "components/Data_MUX_environment.svh"

  // Base Test
  `include "components/Data_MUX_base_test.svh"
endpackage
