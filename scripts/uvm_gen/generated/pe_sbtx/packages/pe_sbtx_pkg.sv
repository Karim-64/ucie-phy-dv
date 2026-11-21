`timescale 1ns/1ps
package pe_sbtx_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // Shared design parameters
  parameter DATA_WIDTH = 64;

  // ---------------------------------------------------------------------------
  // Configuration Objects (cfg_obj/)
  // ---------------------------------------------------------------------------
  `include "cfg_obj/pe_sbtx_D2D_drv_mon_cfg_obj.svh"
  `include "cfg_obj/pe_sbtx_PHY_drv_mon_cfg_obj.svh"
  `include "cfg_obj/pe_sbtx_FIFO_drv_mon_cfg_obj.svh"
  `include "cfg_obj/pe_sbtx_D2D_agt_cfg_obj.svh"
  `include "cfg_obj/pe_sbtx_PHY_agt_cfg_obj.svh"
  `include "cfg_obj/pe_sbtx_FIFO_agt_cfg_obj.svh"
  `include "cfg_obj/pe_sbtx_env_cfg_obj.svh"

  // ---------------------------------------------------------------------------
  // Sequence Items
  // ---------------------------------------------------------------------------
  `include "sequences/sequence_items/pe_sbtx_D2D_sequence_item.svh"
  `include "sequences/sequence_items/pe_sbtx_PHY_sequence_item.svh"
  `include "sequences/sequence_items/pe_sbtx_FIFO_sequence_item.svh"

  // ---------------------------------------------------------------------------
  // Sequencers
  // ---------------------------------------------------------------------------
  `include "components/D2D_agent/pe_sbtx_D2D_sequencer.svh"
  `include "components/PHY_agent/pe_sbtx_PHY_sequencer.svh"
  `include "components/pe_sbtx_vseqr.svh"

  // ---------------------------------------------------------------------------
  // Drivers & Monitors
  // ---------------------------------------------------------------------------
  `include "components/D2D_agent/pe_sbtx_D2D_driver.svh"
  `include "components/D2D_agent/pe_sbtx_D2D_monitor.svh"
  `include "components/PHY_agent/pe_sbtx_PHY_driver.svh"
  `include "components/PHY_agent/pe_sbtx_PHY_monitor.svh"
  `include "components/FIFO_agent/pe_sbtx_FIFO_monitor.svh"

  // ---------------------------------------------------------------------------
  // Agents
  // ---------------------------------------------------------------------------
  `include "components/D2D_agent/pe_sbtx_D2D_agent.svh"
  `include "components/PHY_agent/pe_sbtx_PHY_agent.svh"
  `include "components/FIFO_agent/pe_sbtx_FIFO_agent.svh"

  // ---------------------------------------------------------------------------
  // Sequences
  // ---------------------------------------------------------------------------
  `include "sequences/D2D_seqs/pe_sbtx_D2D_base_seq.svh"
  `include "sequences/PHY_seqs/pe_sbtx_PHY_base_seq.svh"
  `include "sequences/pe_sbtx_vseq.svh"

  // ---------------------------------------------------------------------------
  // Scoreboard, Coverage Collector, Environment
  // ---------------------------------------------------------------------------
  `include "components/pe_sbtx_scoreboard.svh"
  `include "components/pe_sbtx_coverage.svh"
  `include "components/pe_sbtx_environment.svh"

  // ---------------------------------------------------------------------------
  // Base Test
  // ---------------------------------------------------------------------------
  `include "components/pe_sbtx_base_test.svh"

endpackage : pe_sbtx_pkg
