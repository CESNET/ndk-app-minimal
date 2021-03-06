/*
 * file       : test.sv
 * Copyright (C) 2021 CESNET z. s. p. o.
 * description:  base test 
 * date       : 2021
 * author     : Radek Iša <isa@cesnet.ch>
 *
 * SPDX-License-Identifier: BSD-3-Clause
*/

class base#(ETH_STREAMS, ETH_CHANNELS, ETH_PKT_MTU, ETH_RX_HDR_WIDTH, ETH_TX_HDR_WIDTH, DMA_STREAMS, DMA_RX_CHANNELS, DMA_TX_CHANNELS, DMA_HDR_META_WIDTH, DMA_PKT_MTU,
            REGIONS, MFB_REG_SIZE, MFB_BLOCK_SIZE, MFB_ITEM_WIDTH, MEM_PORTS, MEM_ADDR_WIDTH, MEM_BURST_WIDTH, MEM_DATA_WIDTH, MI_DATA_WIDTH, MI_ADDR_WIDTH) extends uvm_test;
    typedef uvm_component_registry#(test::base#(ETH_STREAMS, ETH_CHANNELS, ETH_PKT_MTU, ETH_RX_HDR_WIDTH, ETH_TX_HDR_WIDTH, DMA_STREAMS, DMA_RX_CHANNELS, DMA_TX_CHANNELS, DMA_HDR_META_WIDTH, DMA_PKT_MTU,
                                                REGIONS, MFB_REG_SIZE, MFB_BLOCK_SIZE, MFB_ITEM_WIDTH, MEM_PORTS, MEM_ADDR_WIDTH, MEM_BURST_WIDTH, MEM_DATA_WIDTH, MI_DATA_WIDTH, MI_ADDR_WIDTH),
                                               "test::base") type_id;
    localparam DMA_RX_MVB_WIDTH = $clog2(DMA_PKT_MTU+1)+DMA_HDR_META_WIDTH+$clog2(DMA_TX_CHANNELS);
    localparam DMA_TX_MVB_WIDTH = $clog2(DMA_PKT_MTU+1)+DMA_HDR_META_WIDTH+$clog2(DMA_RX_CHANNELS) + 1;

    //top env for sychnronization
    top_agent::agent m_eth_agent[ETH_STREAMS];
    top_agent::agent m_dma_agent[DMA_STREAMS];

    app_core::env #(ETH_STREAMS, ETH_CHANNELS, ETH_PKT_MTU, ETH_RX_HDR_WIDTH, ETH_TX_HDR_WIDTH, DMA_STREAMS, DMA_RX_CHANNELS, DMA_TX_CHANNELS, DMA_HDR_META_WIDTH, DMA_PKT_MTU,
            REGIONS, MFB_REG_SIZE, MFB_BLOCK_SIZE, MFB_ITEM_WIDTH, MEM_PORTS, MEM_ADDR_WIDTH, MEM_BURST_WIDTH, MEM_DATA_WIDTH, MI_DATA_WIDTH, MI_ADDR_WIDTH) m_env;

    bit   timeout;
    logic event_reset;
    logic event_eth_rx_end[ETH_STREAMS];
    logic event_dma_rx_end[DMA_STREAMS];

    function new (string name, uvm_component parent = null);
        super.new(name, parent);
    endfunction

    static function type_id get_type();
        return type_id::get();
    endfunction

    function string get_type_name();
        return get_type().get_type_name();
    endfunction

    function void build_phase(uvm_phase phase);

        for (int unsigned it = 0; it < ETH_STREAMS; it++) begin
            string it_num;
            it_num.itoa(it);

            m_eth_agent[it] = top_agent::agent::type_id::create({"m_eth_agent_", it_num}, this);
        end

        for (int unsigned it = 0; it < DMA_STREAMS; it++) begin
            string it_num;
            it_num.itoa(it);

            m_dma_agent[it] = top_agent::agent::type_id::create({"m_dma_agent_", it_num}, this);
        end

        m_env = app_core::env #(ETH_STREAMS, ETH_CHANNELS, ETH_PKT_MTU, ETH_RX_HDR_WIDTH, ETH_TX_HDR_WIDTH, DMA_STREAMS, DMA_RX_CHANNELS, DMA_TX_CHANNELS, DMA_HDR_META_WIDTH, DMA_PKT_MTU,
            REGIONS, MFB_REG_SIZE, MFB_BLOCK_SIZE, MFB_ITEM_WIDTH, MEM_PORTS, MEM_ADDR_WIDTH, MEM_BURST_WIDTH, MEM_DATA_WIDTH, MI_DATA_WIDTH, MI_ADDR_WIDTH)::type_id::create("m_env", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        for (int unsigned it = 0; it < ETH_STREAMS; it++) begin
            string it_num;
            top_agent::mvb_config m_config;

            it_num.itoa(it);

            m_config = new();
            m_config.port_min = it     * ETH_CHANNELS;
            m_config.port_max = (it+1) * ETH_CHANNELS-1;

            uvm_config_db#(top_agent::mvb_config)::set(this, {"m_env.m_eth_mvb_rx_", it_num,".m_sequencer"}, "m_config",    m_config);
            uvm_config_db#(mailbox#(uvm_byte_array::sequence_item))::set(this, {"m_env.m_eth_mvb_rx_", it_num,".m_sequencer"}, "hdr_export",    m_eth_agent[it].m_driver.header_export);
            uvm_config_db#(mailbox#(uvm_byte_array::sequence_item))::set(this, {"m_env.m_eth_mfb_rx_", it_num,".m_byte_array_agent.m_sequencer"}, "packet_export", m_eth_agent[it].m_driver.byte_array_export);
            m_env.m_resets_app.sync_connect(m_eth_agent[it].reset_sync);
        end

        for (int unsigned it = 0; it < DMA_STREAMS; it++) begin
            string it_num;
            it_num.itoa(it);
            uvm_config_db#(mailbox#(uvm_byte_array::sequence_item))::set(this, {"m_env.m_dma_mvb_rx_", it_num,".m_sequencer"}, "hdr_export",    m_dma_agent[it].m_driver.header_export);
            uvm_config_db#(mailbox#(uvm_byte_array::sequence_item))::set(this, {"m_env.m_dma_mfb_rx_", it_num,".m_byte_array_agent.m_sequencer"}, "packet_export", m_dma_agent[it].m_driver.byte_array_export);
            m_env.m_resets_app.sync_connect(m_dma_agent[it].reset_sync);
        end
    endfunction

    task run_dma_meta(uvm_byte_array::sequencer sqr);
        top_agent::mvb_sequence_lib#(REGIONS, DMA_RX_MVB_WIDTH)  mvb_seq;

        mvb_seq = top_agent::mvb_sequence_lib#(REGIONS, DMA_RX_MVB_WIDTH)::type_id::create("mvb_seq", this);
        mvb_seq.init_sequence();
        mvb_seq.min_random_count = 5;
        mvb_seq.max_random_count = 13;
        mvb_seq.init_sequence();

        forever begin
            //mvb_seq.set_starting_phase(phase);
            void'(mvb_seq.randomize());
            mvb_seq.start(sqr);
        end
    endtask

    task run_eth_meta(uvm_byte_array::sequencer sqr);
        top_agent::mvb_sequence_lib_eth#(REGIONS, ETH_RX_HDR_WIDTH)  mvb_seq;

        mvb_seq = top_agent::mvb_sequence_lib_eth#(REGIONS, ETH_RX_HDR_WIDTH)::type_id::create("mvb_seq", this);
        mvb_seq.init_sequence();
        mvb_seq.min_random_count = 5;
        mvb_seq.max_random_count = 13;
        mvb_seq.init_sequence();

        forever begin
            //mvb_seq.set_starting_phase(phase);
            void'(mvb_seq.randomize());
            mvb_seq.start(sqr);
        end
    endtask

    task run_packet(uvm_byte_array::sequencer sqr);
        top_agent::byte_array_sequence_simple seq;
        seq = top_agent::byte_array_sequence_simple::type_id::create("seq", this);
        seq.randomize();
        seq.start(sqr);
    endtask

    task run_packet_subsequences();
        for(int unsigned it = 0; it < ETH_STREAMS; it++) begin
            fork
                automatic int index = it;
                run_eth_meta(m_env.m_eth_mvb_rx[index].m_sequencer);
                run_packet  (m_env.m_eth_mfb_rx[index].m_sequencer.m_data);
            join_none;
        end

        // RUN DMA
        for(int unsigned it = 0; it < DMA_STREAMS; it++) begin
            fork
                automatic int index = it;
                run_dma_meta(m_env.m_dma_mvb_rx[index].m_sequencer);
                run_packet  (m_env.m_dma_mfb_rx[index].m_sequencer.m_data);
            join_none;
        end
    endtask

    virtual task eth_tx_sequence(uvm_phase phase, int unsigned index);
        uvm_mfb::sequence_lib_tx#(REGIONS, MFB_REG_SIZE, MFB_BLOCK_SIZE, MFB_ITEM_WIDTH, ETH_TX_HDR_WIDTH) mfb_seq;

        mfb_seq = uvm_mfb::sequence_lib_tx#(REGIONS, MFB_REG_SIZE, MFB_BLOCK_SIZE, MFB_ITEM_WIDTH, ETH_TX_HDR_WIDTH)::type_id::create("mfb_eth_tx_seq", this);
        mfb_seq.init_sequence();
        mfb_seq.min_random_count = 5;
        mfb_seq.max_random_count = 13;

        //RUN ETH
        forever begin
            //mfb_seq.set_starting_phase(phase);
            mfb_seq.randomize();
            mfb_seq.start(m_env.m_eth_mfb_tx[index].m_sequencer);
        end
    endtask

    virtual task eth_rx_sequence(uvm_phase phase, int unsigned index);
        uvm_byte_array::sequence_lib mfb_seq;

        mfb_seq = uvm_byte_array::sequence_lib::type_id::create("mfb_rx_seq", this);
        mfb_seq.init_sequence();
        mfb_seq.min_random_count = 15;
        mfb_seq.max_random_count = 20;

        //SEND PACKETS
        //mfb_seq.set_starting_phase(phase);
        assert(mfb_seq.randomize());
        mfb_seq.start(m_eth_agent[index].m_sequencer);

        //END sequence
        event_eth_rx_end[index] = 1'b0;
    endtask

    virtual task dma_tx_sequence(uvm_phase phase, int unsigned index);
        uvm_mfb::sequence_lib_tx#(REGIONS, MFB_REG_SIZE, MFB_BLOCK_SIZE, MFB_ITEM_WIDTH, 0) mfb_seq;
        uvm_mvb::sequence_lib_tx#(REGIONS, DMA_TX_MVB_WIDTH)                                mvb_seq;

        mfb_seq = uvm_mfb::sequence_lib_tx#(REGIONS, MFB_REG_SIZE, MFB_BLOCK_SIZE, MFB_ITEM_WIDTH, 0)::type_id::create("mfb_dma_tx_seq", this);
        mfb_seq.min_random_count = 5;
        mfb_seq.max_random_count = 13;
        mfb_seq.init_sequence();

        mvb_seq = uvm_mvb::sequence_lib_tx#(REGIONS, DMA_TX_MVB_WIDTH)::type_id::create("mvb_dma_tx_seq", this);
        mvb_seq.min_random_count = 5;
        mvb_seq.max_random_count = 13;
        mvb_seq.init_sequence();

        //RUN ETH
        fork
            forever begin
                //mvb_seq.set_starting_phase(phase);
                void'(mvb_seq.randomize());
                mvb_seq.start(m_env.m_dma_mvb_tx[index].m_sequencer);
            end
            forever begin
                //mfb_seq.set_starting_phase(phase);
                void'(mfb_seq.randomize());
                mfb_seq.start(m_env.m_dma_mfb_tx[index].m_sequencer);
            end
        join_none;
    endtask

    virtual task dma_rx_sequence(uvm_phase phase, int unsigned index);
        uvm_byte_array::sequence_lib                                 mfb_seq;

        mfb_seq = uvm_byte_array::sequence_lib::type_id::create("mfb_dma_rx_seq", this);
        mfb_seq.init_sequence();
        mfb_seq.min_random_count = 15;
        mfb_seq.max_random_count = 20;

        //SEND PACKETS
        //mfb_seq.set_starting_phase(phase);
        assert(mfb_seq.randomize());
        mfb_seq.start(m_dma_agent[index].m_sequencer);

        //END sequence
        event_dma_rx_end[index] = 1'b0;
    endtask

    task test_wait_timeout(int unsigned time_length);
        #(time_length*1us);
    endtask

    task test_wait_result();
        do begin
            #(600ns);
        end while (m_env.m_scoreboard.used() != 0);
        timeout = 0;
    endtask

    virtual task run_reset(uvm_phase phase);
        uvm_reset::sequence_reset reset;
        uvm_reset::sequence_run   run;

        reset = uvm_reset::sequence_reset::type_id::create("reset_reset");
        run   = uvm_reset::sequence_run::type_id::create("reset_run");
        run.length_min = 1000;
        run.length_max = 2000;

        //
        forever begin
            event_reset = 1'b1;
            //reset.set_starting_phase(phase);
            void'(reset.randomize());
            reset.start(m_env.m_resets_gen.m_sequencer);
            event_reset = 1'b0;
            //for (int unsigned it = 0; it < 10; it++) begin
            forever begin
                //run.set_starting_phase(phase);
                void'(run.randomize());
                run.start(m_env.m_resets_gen.m_sequencer);
            end
        end
    endtask

    virtual task dirver_sequence();
        app_core::reg_sequence#(ETH_STREAMS, ETH_CHANNELS, DMA_RX_CHANNELS) seq;

        seq = app_core::reg_sequence#(ETH_STREAMS, ETH_CHANNELS, DMA_RX_CHANNELS)::type_id::create("seq", this);

        seq.m_regmodel = m_env.m_regmodel.m_regmodel;
        seq.start(null);
    endtask

    virtual task run_phase(uvm_phase phase);
        run_packet_subsequences();

        phase.raise_objection(this);
        //// RUN TX
        for(int unsigned it = 0; it < ETH_STREAMS; it++) begin
            fork
                automatic int index = it;
                eth_tx_sequence(phase, index);
            join_none;
        end

        //// RUN TX
        for(int unsigned it = 0; it < DMA_STREAMS; it++) begin
            fork
                automatic int index = it;
                dma_tx_sequence(phase, index);
            join_none;
        end

        // RUN RESET
        fork
            run_reset(phase);
        join_none;

        ////configure egent
        for (int unsigned it = 0; it < 3; it++) begin

            event_eth_rx_end = '{ETH_STREAMS {1'b1}};
            event_dma_rx_end = '{DMA_STREAMS {1'b1}};

            //RUN RIVER SEQUENCE ONLY IF RESET IS NOT SET
            wait(event_reset == 1'b0);
            #(200ns)
            dirver_sequence();
            #(200ns)

            //// RUN ETH
            for(int unsigned it = 0; it < ETH_STREAMS; it++) begin
                fork
                    automatic int index = it;
                    eth_rx_sequence(phase, index);
                join_none;
            end

            //// RUN DMA
            for(int unsigned it = 0; it < DMA_STREAMS; it++) begin
                fork
                    automatic int index = it;
                    dma_rx_sequence(phase, index);
                join_none;
            end

            ////////
            // wait for RX transactions
            for (int unsigned it = 0; it < DMA_STREAMS; it++) begin
                wait(event_dma_rx_end[it] == 1'b0);
            end
            for (int unsigned it = 0; it < ETH_STREAMS; it++) begin
                 wait(event_eth_rx_end[it] == 1'b0);
            end

            //wait for top agetn
            for (int unsigned it = 0; it < DMA_STREAMS; it++) begin
                 wait(m_dma_agent[it].m_driver.byte_array_export.num() == 0 && m_dma_agent[it].m_driver.header_export.num() == 0);
            end
            for (int unsigned it = 0; it < ETH_STREAMS; it++) begin
                 wait(m_eth_agent[it].m_driver.byte_array_export.num() == 0 && m_eth_agent[it].m_driver.header_export.num() == 0);
            end
        end


        timeout = 1;
        fork
            test_wait_timeout(20);
            test_wait_result();
        join_any;

        phase.drop_objection(this);
    endtask

    function void report_phase(uvm_phase phase);
        `uvm_info(this.get_full_name(), {"\n\tTEST : ", this.get_type_name(), " END\n"}, UVM_NONE);
        if (timeout) begin
            `uvm_error(this.get_full_name(), "\n\t===================================================\n\tTIMEOUT SOME PACKET STUCK IN DESIGN\n\t===================================================\n\n");
        end
    endfunction
endclass
