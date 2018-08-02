#
# (C) Copyright 2018 Xilinx, Inc.
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 2 of
# the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#

proc generate {drv_handle} {
	foreach i [get_sw_cores device_tree] {
		set common_tcl_file "[get_property "REPOSITORY" $i]/data/common_proc.tcl"
		if {[file exists $common_tcl_file]} {
			source $common_tcl_file
			break
		}
	}
	set node [gen_peripheral_nodes $drv_handle]
	if {$node == 0} {
		return
	}
	set compatible [get_comp_str $drv_handle]
	set compatible [append compatible " " "xlnx,mipi-csi2-rx-subsystem-3.0"]
	set_drv_prop $drv_handle compatible "$compatible" stringlist
	set dphy_en_reg_if [get_property CONFIG.DPY_EN_REG_IF [get_cells -hier $drv_handle]]
	if {[string match -nocase $dphy_en_reg_if "true"]} {
		hsi::utils::add_new_dts_param "${node}" "xlnx,dphy-present" "" boolean
	}
	set dphy_lanes [get_property CONFIG.C_DPHY_LANES [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,max-lanes" $dphy_lanes int
	set cmn_vc [get_property CONFIG.CMN_VC [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,vc" $cmn_vc int
	set cmn_pxl_format [get_property CONFIG.CMN_PXL_FORMAT [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,csi-pxl-format" $cmn_pxl_format string
	set csi_en_activelanes [get_property CONFIG.C_CSI_EN_ACTIVELANES [get_cells -hier $drv_handle]]
	if {[string match -nocase $csi_en_activelanes "true"]} {
		hsi::utils::add_new_dts_param "${node}" "xlnx,en-active-lanes" "" boolean
	}
	set cmn_inc_vfb [get_property CONFIG.CMN_INC_VFB [get_cells -hier $drv_handle]]
	if {[string match -nocase $cmn_inc_vfb "true"]} {
		hsi::utils::add_new_dts_param "${node}" "xlnx,vfb" "" boolean
	}
	set cmn_num_pixels [get_property CONFIG.CMN_NUM_PIXELS [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,ppc" "$cmn_num_pixels" int
	set axis_tdata_width [get_property CONFIG.AXIS_TDATA_WIDTH [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,axis-tdata-width" "$axis_tdata_width" int
	set connected_ip [hsi::utils::get_connected_stream_ip [get_cells -hier $drv_handle] "VIDEO_OUT"]
	if {[llength $connected_ip] != 0} {
		set connected_ip_type [get_property IP_NAME $connected_ip]
		if {[llength $connected_ip_type] != 0} {
			if {[string match -nocase $connected_ip_type "axis_subset_converter"]} {
				set ip [hsi::utils::get_connected_stream_ip $connected_ip "M_AXIS"]
				set ip_type [get_property IP_NAME $ip]
				if {[string match -nocase $ip_type "v_demosaic"]} {
					set ports_node [add_or_get_dt_node -n "ports" -l csiss_ports -p $node]
					hsi::utils::add_new_dts_param "$ports_node" "#address-cells" 1 int
					hsi::utils::add_new_dts_param "$ports_node" "#size-cells" 0 int
					set port_node [add_or_get_dt_node -n "port" -l csiss_port0 -u 0 -p $ports_node]
					hsi::utils::add_new_dts_param "$port_node" "reg" 0 int
					hsi::utils::add_new_dts_param "${port_node}" "/* Fill cfa-pattern=rggb for raw data types, other fields video-format and video-width user needs to fill */" "" comment
					hsi::utils::add_new_dts_param "$port_node" "xlnx,video-format" 12 int
					hsi::utils::add_new_dts_param "$port_node" "xlnx,video-width" 8 int
					hsi::utils::add_new_dts_param "$port_node" "xlnx,cfa-pattern" rggb string
					set sdi_rx_node [add_or_get_dt_node -n "endpoint" -l csiss_out -p $port_node]
					hsi::utils::add_new_dts_param "$sdi_rx_node" "remote_end_point" demosaic_in reference
					set port1_node [add_or_get_dt_node -n "port" -l csiss_port1 -u 1 -p $ports_node]
					hsi::utils::add_new_dts_param "$port1_node" "reg" 1 int
					hsi::utils::add_new_dts_param "${port1_node}" "/* Fill cfa-pattern=rggb for raw data types, other fields video-format,video-width user needs to fill */" "" comment
					hsi::utils::add_new_dts_param "${port1_node}" "/* User need to add something like remote_end_point=<&out> under the node csiss_in:endpoint */" "" comment
					hsi::utils::add_new_dts_param "$port1_node" "xlnx,video-format" 12 int
					hsi::utils::add_new_dts_param "$port1_node" "xlnx,video-width" 8 int
					hsi::utils::add_new_dts_param "$port1_node" "xlnx,cfa-pattern" rggb string
					set csiss_rx_node [add_or_get_dt_node -n "endpoint" -l csiss_in -p $port1_node]
				}
			}
		}
	}
}