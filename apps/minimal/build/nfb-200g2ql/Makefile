# Makefile: Makefile for nfb-200g2ql card
# Copyright (C) 2022 CESNET z.s.p.o.
# Author(s): Daniel Kriz <danielkriz@cesnet.cz>
#
# SPDX-License-Identifier: BSD-3-Clause

# NOTE: Usage of the configuration parameters in this file is described
# in the Parametrization section of the NDK-CORE documentation.

# Set path to top-level of NDK-FPGA repository
COMBO_BASE = ../../../..
CARD_BASE = $(COMBO_BASE)/extra/nfb-200g2ql
APP_CONF = app_conf.tcl
OUTPUT_NAME = nfb-200g2ql-minimal

.PHONY: all 100g2 40g2

all: 100g2 40g2

100g2: ETH_PORTS=2
100g2: ETH_PORT_SPEED=100
100g2: ETH_PORT_CHAN=1
100g2: ETH_PORT_TYPE=0
100g2: OUTPUT_NAME:=$(OUTPUT_NAME)-100g2
100g2: build

40g2: ETH_PORTS=2
40g2: ETH_PORT_SPEED=40
40g2: ETH_PORT_CHAN=1
40g2: ETH_PORT_TYPE=0
40g2: OUTPUT_NAME:=$(OUTPUT_NAME)-40g2
40g2: build

include $(CARD_BASE)/src/card.mk
