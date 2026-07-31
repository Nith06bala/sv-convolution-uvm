`include "uvm_macros.svh"
import uvm_pkg::*;

interface conv_if (input logic clk);
    logic        rst;
    logic        start;
  logic [14:0]  in_val;
  logic [14:0]  op_val;
  logic [14:0]  din;
  logic [14:0]  dout;
    logic [1:0]  cu_state;
    logic [1:0]  nxt_state;
    logic        mem_rd_en;

    clocking drv_cb @(posedge clk);
        default input #1 output #1;
        output rst;
        output start;
    endclocking

    clocking mon_cb @(posedge clk);
        default input #1;
        input        rst;
        input        start;
        input   in_val;
        input   op_val;
        input   din;
        input   dout;
        input   cu_state;
        input   nxt_state;
        input        mem_rd_en;
    endclocking

    modport drv_mp (clocking drv_cb, input clk);
    modport mon_mp (clocking mon_cb, input clk);
endinterface

class conv_seq extends uvm_sequence_item;
    bit          start;
    bit          rst;
    logic [1:0]  cu_state;
    logic [1:0]  nxt_state;
    logic [6:0]  in_val;
  logic [14:0]  op_val;
    logic [14:0]  din;
    logic [14:0]  dout;
    logic        mem_rd_en;

    `uvm_object_utils(conv_seq)
    function new(string name = "conv_seq");
        super.new(name);
    endfunction
endclass

class conv_sequencer extends uvm_sequencer #(conv_seq);
    `uvm_component_utils(conv_sequencer)
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
endclass

class conv_sequence extends uvm_sequence #(conv_seq);
    `uvm_object_utils(conv_sequence)
    function new(string name = "conv_sequence");
        super.new(name);
    endfunction
    task body();
        conv_seq item;
        item = conv_seq::type_id::create("item");
        start_item(item);
        item.rst   = 1'b1;
        item.start = 1'b0;
        finish_item(item);
    endtask
endclass

class conv_driver extends uvm_driver #(conv_seq);
    `uvm_component_utils(conv_driver)
    virtual conv_if vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(virtual conv_if)::get(this, "", "conv_if", vif))
            `uvm_fatal("NOVIF", "conv_driver: conv_if not found")
    endfunction

    task run_phase(uvm_phase phase);
        vif.drv_cb.rst   <= 0;
        vif.drv_cb.start <= 0;
        @(vif.drv_cb);
        forever begin
            seq_item_port.get_next_item(req);
            drive_item(req);
            seq_item_port.item_done();
        end
    endtask

    task drive_item(conv_seq req);
        begin
            vif.drv_cb.rst   <= 1;
            vif.drv_cb.start <= 0;
            repeat(3) @(vif.drv_cb);
            vif.drv_cb.rst   <= 0;
            vif.drv_cb.start <= 1;
          repeat(81) @(vif.drv_cb);
        end
    endtask
endclass

class conv_monitor extends uvm_monitor;
    `uvm_component_utils(conv_monitor)
    virtual conv_if               vif;
    uvm_analysis_port #(conv_seq) item_col_port;
    conv_seq                      trans_col;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        item_col_port = new("item_col_port", this);
        trans_col     = conv_seq::type_id::create("trans_col");
        if (!uvm_config_db #(virtual conv_if)::get(this, "", "conv_if", vif))
            `uvm_fatal("NOVIF", "conv_monitor: conv_if not found")
    endfunction

    task run_phase(uvm_phase phase);
        forever begin
            @(vif.mon_cb);
            trans_col.nxt_state = vif.mon_cb.nxt_state;
            trans_col.cu_state  = vif.mon_cb.cu_state;
            trans_col.in_val    = vif.mon_cb.in_val;
            trans_col.op_val    = vif.mon_cb.op_val;
            trans_col.din       = vif.mon_cb.din;
            trans_col.dout      = vif.mon_cb.dout;
            trans_col.start     = vif.mon_cb.start;
            trans_col.rst       = vif.mon_cb.rst;
            trans_col.mem_rd_en = vif.mon_cb.mem_rd_en;
            item_col_port.write(trans_col);
        end
    endtask
endclass

class conv_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(conv_scoreboard)

    uvm_analysis_imp #(conv_seq, conv_scoreboard) analysis_export;

    int unsigned clk_counter;
    int unsigned i,j;
  logic [9:0]k;
  logic [14:0]exp_val;
    int unsigned conv_mem_read_count;
    int unsigned conv_mem_write_count;
    int unsigned conv_execution_count;
    int unsigned conv_error_count;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        analysis_export      = new("analysis_export", this);
        clk_counter          = 0;
        i                    = 0;
      j=0;
      k=10'b0;
        conv_mem_read_count  = 0;
        conv_mem_write_count = 0;
        conv_execution_count = 0;
        conv_error_count     = 0;
    endfunction

   
  function void write(conv_seq obs);
        if (obs.start == 1'b1 && obs.rst == 1'b0) begin
            clk_counter++;
    
          if(clk_counter<5)begin

  if (clk_counter == 1 &&
            obs.cu_state  == 2'b00 &&
            obs.nxt_state == 2'b01) begin
            `uvm_info("SB_IDLE",
                $sformatf("clk=%0d  cu=%0b nxt=%0b  [idle->mem_load OK]",
                    clk_counter, obs.cu_state, obs.nxt_state), UVM_LOW)
        end

  else if (clk_counter == 2 &&
                 obs.cu_state  == 2'b01 &&
                 obs.mem_rd_en == 1'b1  &&
                 obs.nxt_state == 2'b10) begin
            `uvm_info("SB_MEM_RD",
                $sformatf("clk=%0d  cu=%0b  mem_rd_en=%0b  [mem_load OK]",
                    clk_counter, obs.cu_state, obs.mem_rd_en), UVM_LOW)
            conv_mem_read_count++;
        end

  else if (clk_counter == 3 &&
                 obs.cu_state  == 2'b10 &&
                 obs.mem_rd_en == 1'b1  &&
                 obs.nxt_state == 2'b11) begin
            `uvm_info("SB_EXEC",
                $sformatf("clk=%0d  cu=%0b  [execute OK]",
                    clk_counter, obs.cu_state), UVM_LOW)
            conv_execution_count++;
        end

  else if (clk_counter == 4 &&
                 obs.cu_state  == 2'b11 &&
                 obs.mem_rd_en == 1'b0  &&
                 obs.nxt_state == 2'b01) begin
            `uvm_info("SB_MEM_WR",
                $sformatf("clk=%0d  cu=%0b  [mem_write OK]",
                    clk_counter, obs.cu_state), UVM_LOW)
            conv_mem_write_count++;
        end
end

else begin
i++;
if(i%3==0)begin
j++;
end

  if (clk_counter >= 5 &&
      (5+3*j==clk_counter) &&
                 obs.cu_state  == 2'b01 &&
                 obs.mem_rd_en == 1'b1  &&
                 obs.nxt_state == 2'b10) begin
            `uvm_info("SB_MEM_RD",
                $sformatf("clk=%0d (iter %0d)  cu=%0b  [mem_load OK]",
                    clk_counter, i, obs.cu_state), UVM_LOW)
            conv_mem_read_count++;
        end

  else if (clk_counter >= 5 &&
           (6+3*j==clk_counter)&&
                 obs.cu_state  == 2'b10 &&
                 obs.mem_rd_en == 1'b1  &&
                 obs.nxt_state == 2'b11) begin
    exp_val=(k+1)*k;
            `uvm_info("SB_EXEC",
                      $sformatf("clk=%0d (iter %0d)  cu=%0b  [execute OK] op_val= %d exp_val=%d",
                    clk_counter, i, obs.cu_state,obs.op_val,exp_val), UVM_LOW)
            conv_execution_count++;
     k++;
        end

  else if (clk_counter >= 5 &&
           (7+3*(j-1)==clk_counter)&&
                 obs.cu_state  == 2'b11 &&
                 obs.mem_rd_en == 1'b0  &&
                 obs.nxt_state == 2'b01) begin
    
            `uvm_info("SB_MEM_WR",
                      $sformatf("clk=%0d (iter %0d)  cu=%0b   [mem_write OK] ",
                    clk_counter, i, obs.cu_state,exp_val), UVM_LOW)
            conv_mem_write_count++;
   
        end

        else begin
            `uvm_error("SB_ERR",
                       $sformatf("clk=%0d  cu=%0b nxt=%0b mem_rd=%0b  i=%d j=%d UNEXPECTED STATE",
                    clk_counter, obs.cu_state, obs.nxt_state, obs.mem_rd_en,i,j))
            conv_error_count++;
        end
end
        end
    endfunction

    function void report_phase(uvm_phase phase);
        `uvm_info("SB_SUMMARY",
            $sformatf("\n  mem_read=%0d  execution=%0d  mem_write=%0d  errors=%0d",
                conv_mem_read_count, conv_execution_count,
                conv_mem_write_count, conv_error_count), UVM_NONE)
    endfunction
endclass

class conv_agent extends uvm_agent;
    `uvm_component_utils(conv_agent)
    conv_sequencer seqr;
    conv_driver    drv;
    conv_monitor   mon;

    function new(string name = "conv_agent", uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        seqr = conv_sequencer::type_id::create("seqr", this);
        drv  = conv_driver::type_id::create("drv",  this);
        mon  = conv_monitor::type_id::create("mon",  this);
    endfunction

    function void connect_phase(uvm_phase phase);
        drv.seq_item_port.connect(seqr.seq_item_export);
    endfunction
endclass

class conv_env extends uvm_env;
    `uvm_component_utils(conv_env)
    conv_agent      agt;
    conv_scoreboard sboard;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agt    = conv_agent::type_id::create("agt",    this);
        sboard = conv_scoreboard::type_id::create("sboard", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        agt.mon.item_col_port.connect(sboard.analysis_export);
    endfunction
endclass

class conv_test extends uvm_test;
    `uvm_component_utils(conv_test)
    conv_env env;

    function new(string name = "conv_test", uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = conv_env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
        conv_sequence rand_seq;
        rand_seq = conv_sequence::type_id::create("rand_seq");
        phase.raise_objection(this);
        `uvm_info("TEST", "Starting conv sequence", UVM_LOW)
        rand_seq.start(env.agt.seqr);
        #200;
        phase.drop_objection(this);
    endtask
endclass

module conv_tb_top;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    logic clk;
    initial clk = 0;
    always #5 clk = ~clk;

    conv_if dut_if(.clk(clk));

    conv dut(
        .clk  (clk),
        .rst  (dut_if.rst),
        .start(dut_if.start)
    );

    assign dut_if.cu_state  = dut.cu_state;
    assign dut_if.nxt_state = dut.nxt_state;
    assign dut_if.mem_rd_en = dut.mem_rd_en;
    assign dut_if.in_val    = dut.in_val;
    assign dut_if.op_val    = dut.op_val;
    assign dut_if.din       = dut.din;
    assign dut_if.dout      = dut.dout;

    initial begin
        uvm_config_db #(virtual conv_if)::set(null, "uvm_test_top.*", "conv_if", dut_if);
        run_test("conv_test");
    end
endmodule
