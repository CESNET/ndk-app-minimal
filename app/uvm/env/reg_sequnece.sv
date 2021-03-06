/*
 * file       : sequence.sv
 * Copyright (C) 2021 CESNET z. s. p. o.
 * description: sequence for application core register model
 * date       : 2021
 * author     : Radek Iša <isa@cesnet.ch>
 *
 * SPDX-License-Identifier: BSD-3-Clause
*/


class reg_sequence#(STREAMS, CHANNELS, DMA_RX_CHANNELS) extends uvm_sequence;
    `uvm_object_param_utils(app_core::reg_sequence#(STREAMS, CHANNELS, DMA_RX_CHANNELS))

    regmodel #(STREAMS, CHANNELS, DMA_RX_CHANNELS) m_regmodel;

    function new (string name = "reg_sequence");
        super.new(name);
    endfunction

    task body();
        string msg;
        uvm_status_e   status;
        uvm_reg_data_t data;
        uvm_reg        regs[$];

        for (int unsigned it = 0; it < STREAMS; it++) begin
            for (int unsigned jt = 0; jt < CHANNELS; jt++) begin
                if(!m_regmodel.stream[it].channel[jt].randomize() with {ch_min.value <= ch_max.value; ch_max.value < DMA_RX_CHANNELS; incr.value dist {[0:5] :/ 30, [6:255] :/ 1};
                $countones(ch_max.value-ch_min.value+1) <= 1;}) begin
                    `uvm_fatal(m_regmodel.get_full_name(), "\n\treg_sequence cannot randomize");
                end

                $swrite(msg, "%s\n\t\tPORT [%0d] CHANNEL [%0d] :  min %0d max %0d inc %0d", msg, it, jt, m_regmodel.stream[it].channel[jt].ch_min.value, m_regmodel.stream[it].channel[jt].ch_max.value, m_regmodel.stream[it].channel[jt].incr.value);
            end
        end
        `uvm_info(this.get_full_name(), {msg, "\n"}, UVM_LOW);

        //update in defined order
        //m_regmodel.update(status);
        //update in random order
        m_regmodel.get_registers(regs);
        regs.shuffle();
        foreach (regs[it]) begin
            regs[it].update(status);
        end

		//just for synchronization
        m_regmodel.stream[0].channel[0].read(status, data, .parent(this));
		$write("TEST DATA %h\n", data);

        //m_regmodel.stream[0].channel[0].write(status, 'h0, .parent(this));
        //$write("============================================\n");
        //$write("TEST WRITE DATA GET STATUS %s\n\n", status);

        //m_regmodel.stream[0].channel[0].read(status, data, .parent(this));
        //$write("============================================\n");
        //$write("TEST READ DATA %h GET STATUS %s\n\n", data, status);
    endtask
endclass


