`timescale 1ns/1ps
package wr_control_sbtx_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import packets_pkg::*;

  // Shared design parameters
  parameter NC = 32;

  // Configuration Objects (bottom-up: drv/mon -> agt -> env)
  `include "cfg_obj/wr_control_sbtx_drv_mon_cfg_obj.svh"
  `include "cfg_obj/wr_control_sbtx_agt_cfg_obj.svh"
  `include "cfg_obj/wr_control_sbtx_env_cfg_obj.svh"

  // Sequence Items
  `include "sequences/wr_control_sbtx_sequence_item.svh"

  // UVM Sequencer (needed before sequences using uvm_declare_p_sequencer)
  `include "components/wr_control_sbtx_sequencer.svh"

  // Sequences
  `include "sequences/wr_control_sbtx_base_sequence.svh"
  `include "sequences/wr_control_sbtx_all_opcodes_seq.svh"
  `include "sequences/wr_control_sbtx_directed_seq.svh"
  `include "sequences/wr_control_sbtx_reset_seq.svh"
  `include "sequences/wr_control_sbtx_rar_seq.svh"
  `include "sequences/wr_control_sbtx_msg_seq.svh"
  `include "sequences/wr_control_sbtx_comp_seq.svh"
  `include "sequences/wr_control_sbtx_parity_err_seq.svh"
  `include "sequences/wr_control_sbtx_b2b_pipeline_seq.svh"
  `include "sequences/wr_control_sbtx_mid_pkt_rst_seq.svh"
  `include "sequences/wr_control_sbtx_corner_cases_seq.svh"
  `include "sequences/wr_control_sbtx_full_rand_stress_seq.svh"

  // UVM Components (bottom-up)
  `include "components/wr_control_sbtx_driver.svh"
  `include "components/wr_control_sbtx_monitor.svh"
  `include "components/wr_control_sbtx_agent.svh"

  `include "components/wr_control_sbtx_scoreboard.svh"
  `include "components/wr_control_sbtx_subscriber.svh"
  `include "components/wr_control_sbtx_environment.svh"

  // Tests (Base Test + TC_01 through TC_08; TC_09 omitted per request)
  `include "components/tests/wr_control_sbtx_base_test.svh"
  `include "components/tests/wr_control_sbtx_reset_test.svh"
  `include "components/tests/wr_control_sbtx_rar_test.svh"
  `include "components/tests/wr_control_sbtx_msg_test.svh"
  `include "components/tests/wr_control_sbtx_comp_test.svh"
  `include "components/tests/wr_control_sbtx_parity_err_test.svh"
  `include "components/tests/wr_control_sbtx_b2b_pipeline_test.svh"
  `include "components/tests/wr_control_sbtx_mid_pkt_rst_test.svh"
  `include "components/tests/wr_control_sbtx_corner_cases_test.svh"
  `include "components/tests/wr_control_sbtx_full_rand_stress_test.svh"
endpackage
