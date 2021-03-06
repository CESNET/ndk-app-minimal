proc dts_application {base eth_streams mem_ports} {
    set mi_ports_raw [expr $eth_streams + $mem_ports]

    # Round to nearest power of 2
    set mi_ports 1
    while {$mi_ports < $mi_ports_raw} {
        set mi_ports [expr {$mi_ports * 2}]
    }

    set subaddr_w [expr 0x02000000 / $mi_ports]

	set ret ""
	append ret "nic_application {"
	append ret "reg = <$base [expr $subaddr_w * $eth_streams]>;"
    # TODO: why it was commented?
    append ret "compatible = \"netcope,application,nic\";"

    for {set i 0} {$i < $mem_ports} {incr i} {
            set mem_tester_base [expr $base + $subaddr_w * ($eth_streams + $i)]
            append ret "mem_tester_$i:" [mem_tester $mem_tester_base $i]
    }

	append ret "};"
	return $ret
}

proc dts_build_project {} {
	return [dts_build_netcope]
}
