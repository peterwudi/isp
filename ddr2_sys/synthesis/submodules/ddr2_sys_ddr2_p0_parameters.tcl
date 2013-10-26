#
# AUTO-GENERATED FILE: Do not edit ! ! ! 
#

set ::GLOBAL_ddr2_sys_ddr2_p0_corename "ddr2_sys_ddr2_p0"
set ::GLOBAL_ddr2_sys_ddr2_p0_io_standard "SSTL-18"
set ::GLOBAL_ddr2_sys_ddr2_p0_io_interface_type "HPAD"
set ::GLOBAL_ddr2_sys_ddr2_p0_io_standard_differential "1.8-V SSTL"
set ::GLOBAL_ddr2_sys_ddr2_p0_number_of_dqs_groups 8
set ::GLOBAL_ddr2_sys_ddr2_p0_dqs_group_size 8
set ::GLOBAL_ddr2_sys_ddr2_p0_number_of_ck_pins 2
set ::GLOBAL_ddr2_sys_ddr2_p0_number_of_dm_pins 8
set ::GLOBAL_ddr2_sys_ddr2_p0_dqs_delay_chain_length 2
set ::GLOBAL_ddr2_sys_ddr2_p0_uniphy_temp_ver_code 1953295129
# PLL Parameters

#USER W A R N I N G !
#USER The PLL parameters are statically defined in this
#USER file at generation time!
#USER To ensure timing constraints and timing reports are correct, when you make 
#USER any changes to the PLL component using the MegaWizard Plug-In,
#USER apply those changes to the PLL parameters in this file

set ::GLOBAL_ddr2_sys_ddr2_p0_num_pll_clock 7
set ::GLOBAL_ddr2_sys_ddr2_p0_pll_mult(0) 10
set ::GLOBAL_ddr2_sys_ddr2_p0_pll_div(0) 3
set ::GLOBAL_ddr2_sys_ddr2_p0_pll_phase(0) 0.0
set ::GLOBAL_ddr2_sys_ddr2_p0_pll_mult(PLL_AFI_CLK) 10
set ::GLOBAL_ddr2_sys_ddr2_p0_pll_div(PLL_AFI_CLK) 3
set ::GLOBAL_ddr2_sys_ddr2_p0_pll_phase(PLL_AFI_CLK) 0.0
set ::GLOBAL_ddr2_sys_ddr2_p0_pll_mult(1) 20
set ::GLOBAL_ddr2_sys_ddr2_p0_pll_div(1) 3
set ::GLOBAL_ddr2_sys_ddr2_p0_pll_phase(1) 0.0
set ::GLOBAL_ddr2_sys_ddr2_p0_pll_mult(PLL_MEM_CLK) 20
set ::GLOBAL_ddr2_sys_ddr2_p0_pll_div(PLL_MEM_CLK) 3
set ::GLOBAL_ddr2_sys_ddr2_p0_pll_phase(PLL_MEM_CLK) 0.0
set ::GLOBAL_ddr2_sys_ddr2_p0_pll_mult(2) 20
set ::GLOBAL_ddr2_sys_ddr2_p0_pll_div(2) 3
set ::GLOBAL_ddr2_sys_ddr2_p0_pll_phase(2) 90.0
set ::GLOBAL_ddr2_sys_ddr2_p0_pll_mult(PLL_WRITE_CLK) 20
set ::GLOBAL_ddr2_sys_ddr2_p0_pll_div(PLL_WRITE_CLK) 3
set ::GLOBAL_ddr2_sys_ddr2_p0_pll_phase(PLL_WRITE_CLK) 90.0
set ::GLOBAL_ddr2_sys_ddr2_p0_pll_mult(3) 10
set ::GLOBAL_ddr2_sys_ddr2_p0_pll_div(3) 3
set ::GLOBAL_ddr2_sys_ddr2_p0_pll_phase(3) 270.0
set ::GLOBAL_ddr2_sys_ddr2_p0_pll_mult(PLL_ADDR_CMD_CLK) 10
set ::GLOBAL_ddr2_sys_ddr2_p0_pll_div(PLL_ADDR_CMD_CLK) 3
set ::GLOBAL_ddr2_sys_ddr2_p0_pll_phase(PLL_ADDR_CMD_CLK) 270.0
set ::GLOBAL_ddr2_sys_ddr2_p0_pll_mult(4) 5
set ::GLOBAL_ddr2_sys_ddr2_p0_pll_div(4) 3
set ::GLOBAL_ddr2_sys_ddr2_p0_pll_phase(4) 0.0
set ::GLOBAL_ddr2_sys_ddr2_p0_pll_mult(PLL_AFI_HALF_CLK) 5
set ::GLOBAL_ddr2_sys_ddr2_p0_pll_div(PLL_AFI_HALF_CLK) 3
set ::GLOBAL_ddr2_sys_ddr2_p0_pll_phase(PLL_AFI_HALF_CLK) 0.0
set ::GLOBAL_ddr2_sys_ddr2_p0_pll_mult(5) 5
set ::GLOBAL_ddr2_sys_ddr2_p0_pll_div(5) 3
set ::GLOBAL_ddr2_sys_ddr2_p0_pll_phase(5) 0.0
set ::GLOBAL_ddr2_sys_ddr2_p0_pll_mult(PLL_NIOS_CLK) 5
set ::GLOBAL_ddr2_sys_ddr2_p0_pll_div(PLL_NIOS_CLK) 3
set ::GLOBAL_ddr2_sys_ddr2_p0_pll_phase(PLL_NIOS_CLK) 0.0
set ::GLOBAL_ddr2_sys_ddr2_p0_pll_mult(6) 5
set ::GLOBAL_ddr2_sys_ddr2_p0_pll_div(6) 12
set ::GLOBAL_ddr2_sys_ddr2_p0_pll_phase(6) 0.0
set ::GLOBAL_ddr2_sys_ddr2_p0_pll_mult(PLL_CONFIG_CLK) 5
set ::GLOBAL_ddr2_sys_ddr2_p0_pll_div(PLL_CONFIG_CLK) 12
set ::GLOBAL_ddr2_sys_ddr2_p0_pll_phase(PLL_CONFIG_CLK) 0.0

set ::GLOBAL_ddr2_sys_ddr2_p0_leveling_capture_phase 72.0

##############################################################
## IP options
##############################################################

set IP(write_dcc) "static"
set IP(write_deskew_range) 15
set IP(read_deskew_range) 15
set IP(write_deskew_range_setup) 3
set IP(write_deskew_range_hold) 15
set IP(read_deskew_range_setup) 15
set IP(read_deskew_range_hold) 15
set IP(mem_if_memtype) "ddr2"
set IP(RDIMM) 0
set IP(LRDIMM) 0
set IP(mp_calibration) 1
set IP(quantization_T9) 0.050
set IP(quantization_T1) 0.050
set IP(quantization_DCC) 0.050
set IP(quantization_T7) 0.050
set IP(quantization_WL) 0.050
set IP(eol_reduction_factor_addr) 1.0
set IP(eol_reduction_factor_read) 1.0
set IP(eol_reduction_factor_write) 1.0
# Can be either dynamic or static
set IP(write_deskew_mode) "dynamic"
set IP(read_deskew_mode) "dynamic"
set IP(discrete_device) 1
set IP(num_ranks) 2
set IP(num_shadow_registers) 1
set IP(tracking_enabled) 0

set IP(num_report_paths) 10
set IP(epr) 0.0
set IP(epw) 0.0
