# user_const.tcl: User parameters for fb4cgg3/fb2cgg3 card
# Copyright (C) 2022 CESNET z.s.p.o.
# Author(s): Jakub Cabal <cabal@cesnet.cz>
#
# SPDX-License-Identifier: BSD-3-Clause

# ==============================================================================
# DMA parameters:
# ==============================================================================
# If you do not have access to a non-public repository with DMA IP, set to false.
# If the DMA module is disabled, loopback will be implemented instead.
set DMA_ENABLE           true
# The minimum number of RX/TX DMA channels for this card is 16.
set DMA_RX_CHANNELS      16
set DMA_TX_CHANNELS      16
# In blocking mode, packets are dropped only when the RX DMA channel is off.
# In non-blocking mode, packets are dropped whenever they cannot be sent.
set DMA_RX_BLOCKING_MODE true
# ------------------------------------------------------------------------------

# ==============================================================================
# Other parameters:
# ==============================================================================
set PROJECT_NAME "NDK_MINIMAL"
# Add Ethernet Speed/Ports info to project name...
append PROJECT_NAME "_" $ETH_PORT_SPEED(0) "G" $ETH_PORTS
# ------------------------------------------------------------------------------
