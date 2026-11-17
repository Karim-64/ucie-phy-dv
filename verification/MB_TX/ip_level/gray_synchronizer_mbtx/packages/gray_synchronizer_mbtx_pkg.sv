`timescale 1ns/1ps
package gray_synchronizer_mbtx_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // Shared design parameters
  parameter DATA_SIZE = 2;

  // Configuration Objects (bottom-up: drv/mon -> agt -> env)
  `include "cfg_obj/gray_synchronizer_mbtx_drv_mon_cfg_obj.svh"
  `include "cfg_obj/gray_synchronizer_mbtx_agt_cfg_obj.svh"
  `include "cfg_obj/gray_synchronizer_mbtx_env_cfg_obj.svh"

  // Sequence Items
  `include "sequences/gray_synchronizer_mbtx_sequence_item.svh"

  // UVM Sequencer to be able to uvm_declare_p_sequencer
  `include "components/gray_synchronizer_mbtx_sequencer.svh"

  // Sequences
  `include "sequences/gray_synchronizer_mbtx_error_injection.svh"
  `include "sequences/gray_synchronizer_mbtx_exhaustive_seq.svh"
  `include "sequences/gray_synchronizer_mbtx_random_seq.svh"
  `include "sequences/gray_synchronizer_mbtx_base_sequence.svh"

  // UVM Components (bottom-up)
  `include "components/gray_synchronizer_mbtx_driver.svh"
  `include "components/gray_synchronizer_mbtx_monitor.svh"
  `include "components/gray_synchronizer_mbtx_agent.svh"

  `include "components/gray_synchronizer_mbtx_scoreboard.svh"
  `include "components/gray_synchronizer_mbtx_subscriber.svh"
  `include "components/gray_synchronizer_mbtx_environment.svh"

  // Base Test
  `include "components/gray_synchronizer_mbtx_base_test.svh"
endpackage
