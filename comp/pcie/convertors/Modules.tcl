# Modules.tcl: Components include script
# Copyright (C) 2022 CESNET z. s. p. o.
# Author(s): Daniel Kriz <xkrizd01@vutbr.cz>
#
# SPDX-License-Identifier: BSD-3-Clause

# Packages
lappend PACKAGES "$OFM_PATH/comp/base/pkg/math_pack.vhd"
lappend PACKAGES "$OFM_PATH/comp/base/pkg/type_pack.vhd"

# Source files for implemented component
lappend MOD "$ENTITY_BASE/cq_axi2mfb/pcie_axi2mfb.vhd"
lappend MOD "$ENTITY_BASE/cc_mfb2axi/pcie_mfb2axi.vhd"