`timescale 1ns/1ps
package pat_gen_sbtx_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // Shared design parameters

  // Configuration Objects (bottom-up: drv/mon -> agt -> env)
  `include "cfg_obj/pat_gen_sbtx_drv_mon_cfg_obj.svh"
  `include "cfg_obj/pat_gen_sbtx_agt_cfg_obj.svh"
  `include "cfg_obj/pat_gen_sbtx_env_cfg_obj.svh"

  // Sequence Items
  `include "sequences/pat_gen_sbtx_sequence_item.svh"

  // UVM Sequencer to be able to uvm_declare_p_sequencer
  `include "components/pat_gen_sbtx_sequencer.svh"

  // Sequences
  `include "sequences/pat_gen_rst_seq.svh"
  `include "sequences/pat_gen_base_seq.svh"
  `include "sequences/pat_gen_error_injec_seq.svh"

  // UVM Components (bottom-up)
  `include "components/pat_gen_sbtx_driver.svh"
  `include "components/pat_gen_sbtx_monitor.svh"
  `include "components/pat_gen_sbtx_agent.svh"

  `include "components/pat_gen_sbtx_scoreboard.svh"
  `include "components/pat_gen_sbtx_subscriber.svh"
  `include "components/pat_gen_sbtx_environment.svh"

  // Base Test
  `include "components/pat_gen_sbtx_base_test.svh"
endpackage
