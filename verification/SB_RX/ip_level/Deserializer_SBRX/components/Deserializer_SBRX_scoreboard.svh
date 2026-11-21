`ifndef DESERIALIZER_SBRX_SCOREBOARD_SVH
`define DESERIALIZER_SBRX_SCOREBOARD_SVH

class Deserializer_SBRX_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(Deserializer_SBRX_scoreboard)
  uvm_analysis_export#(Deserializer_SBRX_sequence_item) exp;
  uvm_tlm_analysis_fifo#(Deserializer_SBRX_sequence_item) fifo;
  uvm_analysis_export#(Deserializer_SBRX_sequence_item) exp2;
  uvm_tlm_analysis_fifo#(Deserializer_SBRX_sequence_item) fifo2;

  // Reference Model & Checking state variables
  protected bit [DATA_WIDTH-1:0] shift_reg;
  protected int unsigned         bit_count;
  protected bit [DATA_WIDTH-1:0] exp_queue[$];
  protected bit                  prev_data_valid;
  protected bit [DATA_WIDTH-1:0] last_valid_data;
  protected bit                  has_received_first_word;
  protected int unsigned         total_words_assembled;

  // Statistics counters
  protected int unsigned total_transactions;
  protected int unsigned match_count;
  protected int unsigned mismatch_count;

  function new(string name = "Deserializer_SBRX_scoreboard", uvm_component parent = null);
    super.new(name, parent);
    total_transactions      = 0;
    match_count             = 0;
    mismatch_count          = 0;
    shift_reg               = '0;
    bit_count               = 0;
    prev_data_valid         = 1'b0;
    last_valid_data         = '0;
    has_received_first_word = 1'b0;
    total_words_assembled   = 0;
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    exp = new("exp", this);
    fifo = new("fifo", this);
    exp2 = new("exp2", this);
    fifo2 = new("fifo2", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    exp.connect(fifo.analysis_export);
    exp2.connect(fifo2.analysis_export);
  endfunction

  task run_phase(uvm_phase phase);
    Deserializer_SBRX_sequence_item item;
    Deserializer_SBRX_sequence_item item2;
    Deserializer_SBRX_sequence_item check_item;
    super.run_phase(phase);
    forever begin
      fifo.get(item);
      fifo2.get(item2);
      check_item = Deserializer_SBRX_sequence_item::type_id::create("check_item");
      check_item.sb_sys_rst = item.sb_sys_rst;
      check_item.deser_data_out = item.deser_data_out;
      check_item.data_valid = item.data_valid;
      check_item.RXDATASB = item2.RXDATASB;
      do_check(check_item);
    end
  endtask

  function void do_check(Deserializer_SBRX_sequence_item t);
    if (t == null) return;

    total_transactions++;
    if (t.sb_sys_rst === 1'b0) begin
      shift_reg               = '0;
      bit_count               = 0;
      exp_queue.delete();
      prev_data_valid         = 1'b0;
      last_valid_data         = '0;
      has_received_first_word = 1'b0;

      if (t.data_valid !== 1'b0) begin
        mismatch_count++;
        `uvm_error("SCB_RST_ERR", $sformatf("data_valid asserted during active reset (sb_sys_rst=0)! data_valid=%0b", t.data_valid))
      end
      if (t.deser_data_out !== '0) begin
        mismatch_count++;
        `uvm_error("SCB_RST_ERR", $sformatf("deser_data_out is non-zero during active reset (sb_sys_rst=0)! deser_data_out=0x%016h", t.deser_data_out))
      end

      return;
    end

    shift_reg[bit_count] = t.RXDATASB;
    bit_count++;

    if (bit_count == DATA_WIDTH) begin
      exp_queue.push_back(shift_reg);
      total_words_assembled++;
      `uvm_info("SCB_REF_MODEL", $sformatf("Reference Model assembled Word #%0d: 0x%016h (Queue size=%0d)",
                total_words_assembled, shift_reg, exp_queue.size()), UVM_HIGH)
      bit_count = 0;
      shift_reg = '0;
    end

    if (t.data_valid === 1'b1 && prev_data_valid === 1'b1) begin
      mismatch_count++;
      `uvm_error("SCB_PULSE_ERR", "data_valid asserted for consecutive cycles! Single-cycle pulse integrity violated.")
    end

    if (t.data_valid === 1'b1) begin
      if (exp_queue.size() > 0) begin
        bit [DATA_WIDTH-1:0] expected_word = exp_queue.pop_front();
        if (t.deser_data_out === expected_word) begin
          match_count++;
          last_valid_data         = t.deser_data_out;
          has_received_first_word = 1'b1;
          // `uvm_info("SCB_MATCH", $sformatf("MATCH [Word #%0d]: deser_data_out=0x%016h matches expected",
          //           match_count, t.deser_data_out), UVM_MEDIUM)
        end else begin
          mismatch_count++;
          `uvm_error("SCB_MISMATCH", $sformatf("MISMATCH [Word #%0d]: Expected deser_data_out=0x%016h, Actual=0x%016h (Diff=0x%016h)",
                     match_count + mismatch_count, expected_word, t.deser_data_out, expected_word ^ t.deser_data_out))
        end
      end else begin
        mismatch_count++;
        `uvm_error("SCB_SPURIOUS_VALID", $sformatf("Spurious data_valid pulse: no assembled word in expected queue! deser_data_out=0x%016h",
                   t.deser_data_out))
      end
    end else begin
      if (has_received_first_word && (t.deser_data_out !== last_valid_data)) begin
        if (exp_queue.size() > 0 && t.deser_data_out === exp_queue[0]) begin
          // deser_data_out settled to final valid value prior to data_valid assertion
        end else begin
          `uvm_warning("SCB_STABILITY_WARN", $sformatf("deser_data_out changed while data_valid=0! Expected stable=0x%016h, Actual=0x%016h",
                       last_valid_data, t.deser_data_out))
        end
      end
    end

    prev_data_valid = t.data_valid;
  endfunction

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);

    `uvm_info("SCB_REPORT", "============================================================", UVM_NONE)
    `uvm_info("SCB_REPORT", "         DESERIALIZER_SBRX SCOREBOARD REPORT                ", UVM_NONE)
    `uvm_info("SCB_REPORT", "============================================================", UVM_NONE)
    `uvm_info("SCB_REPORT", $sformatf(" Total Cycles Monitored      : %0d", total_transactions), UVM_NONE)
    `uvm_info("SCB_REPORT", $sformatf(" Total Words Assembled (Ref) : %0d", total_words_assembled), UVM_NONE)
    `uvm_info("SCB_REPORT", $sformatf(" Total Matches (Words)       : %0d", match_count), UVM_NONE)
    `uvm_info("SCB_REPORT", $sformatf(" Total Mismatches            : %0d", mismatch_count), UVM_NONE)
    `uvm_info("SCB_REPORT", $sformatf(" Remaining Words in Queue    : %0d", exp_queue.size()), UVM_NONE)
    `uvm_info("SCB_REPORT", "------------------------------------------------------------", UVM_NONE)

    if (exp_queue.size() > 0) begin
      `uvm_error("SCB_REPORT", $sformatf("    *** [TEST INCOMPLETE] %0d EXPECTED WORDS WERE NEVER OUTPUT BY DUT! ***", exp_queue.size()))
    end

    if (mismatch_count == 0 && match_count > 0 && exp_queue.size() == 0) begin
      `uvm_info("SCB_REPORT", "        *** [TEST PASSED] ALL CHECKS MATCHED! ***           ", UVM_NONE)
    end else if (match_count == 0 && mismatch_count == 0) begin
      `uvm_warning("SCB_REPORT", "    *** [TEST INCOMPLETE] NO WORDS VERIFIED! ***    ")
    end else begin
      `uvm_error("SCB_REPORT", $sformatf("    *** [TEST FAILED] %0d MISMATCHES DETECTED! ***      ", mismatch_count + exp_queue.size()))
    end
    `uvm_info("SCB_REPORT", "============================================================", UVM_NONE)
  endfunction
endclass

`endif // DESERIALIZER_SBRX_SCOREBOARD_SVH
