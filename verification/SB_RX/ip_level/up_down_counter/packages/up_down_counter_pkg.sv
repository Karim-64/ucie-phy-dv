`timescale 1ns/1ps
package up_down_counter_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // Shared design parameters
  parameter WIDTH = 5;

  // Configuration Objects (bottom-up: drv/mon -> agt -> env)
  `include "cfg_obj/up_down_counter_drv_mon_cfg_obj.svh"
  `include "cfg_obj/up_down_counter_agt_cfg_obj.svh"
  `include "cfg_obj/up_down_counter_env_cfg_obj.svh"

  // Sequence Items
  `include "sequences/up_down_counter_sequence_item.svh"

  // UVM Sequencer to be able to uvm_declare_p_sequencer
  `include "components/up_down_counter_sequencer.svh"

  // Sequences
  `include "sequences/up_down_counter_base_sequence.svh"

  // UVM Components (bottom-up)
  `include "components/up_down_counter_driver.svh"
  `include "components/up_down_counter_monitor.svh"
  `include "components/up_down_counter_agent.svh"

  `include "components/up_down_counter_scoreboard.svh"
  `include "components/up_down_counter_subscriber.svh"
  `include "components/up_down_counter_environment.svh"

  // Base Test
  `include "components/up_down_counter_base_test.svh"
endpackage
