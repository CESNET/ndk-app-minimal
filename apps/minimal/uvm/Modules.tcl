# Modules.tcl: Local include script
# Copyright (C) 2021 CESNET
# Author: Radek Iša <isa@cesnet.cz>
#
# SPDX-License-Identifier: BSD-3-Clause

lappend PACKAGES "$ENTITY_BASE/test_pkg.sv"

#AGENTS
#lappend COMPONENTS [ list "COMMON"     "$OFM_PATH/comp/uvm/common"                    "FULL" ]
#lappend COMPONENTS [ list "RESET"      "$OFM_PATH/comp/uvm/reset"                     "FULL" ]
#lappend COMPONENTS [ list "MVB"        "$OFM_PATH/comp/uvm/logic_vector_mvb"          "FULL" ]
#lappend COMPONENTS [ list "MFB"        "$OFM_PATH/comp/uvm/byte_array_mfb"            "FULL" ]
#lappend COMPONENTS [ list "MI"         "$OFM_PATH/comp/uvm/mi"                        "FULL" ]

#MODELS
#lappend COMPONENTS [ list "CHANNEL_ROUTER_MODEL" "$OFM_PATH/comp/mvb_tools/flow/channel_router/uvm"  "FULL" ]


lappend COMPONENTS [ list "COMMON" "$OFM_PATH/core/comp/app/app_uvm" "FULL" ]


lappend MOD "$ENTITY_BASE/env/pkg.sv"
lappend MOD "$ENTITY_BASE/tests/pkg.sv"
