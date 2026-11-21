`timescale 1ns/1ps
package gray_synchronizer_sbtx_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // Shared design parameters
  parameter DATA_SIZE = 2;

  // Configuration Objects (bottom-up: drv/mon -> agt -> env)
  `include "cfg_obj/gray_synchronizer_sbtx_drv_mon_cfg_obj.svh"
  `include "cfg_obj/gray_synchronizer_sbtx_agt_cfg_obj.svh"
  `include "cfg_obj/gray_synchronizer_sbtx_env_cfg_obj.svh"

  // Sequence Items
  `include "sequences/gray_synchronizer_sbtx_sequence_item.svh"

  // UVM Sequencer to be able to uvm_declare_p_sequencer
  `include "components/gray_synchronizer_sbtx_sequencer.svh"

  // Sequences
  `include "sequences/gray_synchronizer_sbtx_error_injection.svh"
  `include "sequences/gray_synchronizer_sbtx_exhaustive_seq.svh"
  `include "sequences/gray_synchronizer_sbtx_random_seq.svh"
  `include "sequences/gray_synchronizer_sbtx_base_sequence.svh"

  // UVM Components (bottom-up)
  `include "components/gray_synchronizer_sbtx_driver.svh"
  `include "components/gray_synchronizer_sbtx_monitor.svh"
  `include "components/gray_synchronizer_sbtx_agent.svh"

  `include "components/gray_synchronizer_sbtx_scoreboard.svh"
  `include "components/gray_synchronizer_sbtx_subscriber.svh"
  `include "components/gray_synchronizer_sbtx_environment.svh"

  // Base Test
  `include "components/gray_synchronizer_sbtx_base_test.svh"
endpackage
