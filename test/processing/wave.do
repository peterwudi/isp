onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -radix unsigned /tb/clk
add wave -noupdate -radix unsigned /tb/reset
add wave -noupdate -radix unsigned /tb/newFrame
add wave -noupdate -radix unsigned /tb/iValid
add wave -noupdate -radix unsigned /tb/oDoneFilter
add wave -noupdate -radix unsigned /tb/irData
add wave -noupdate -radix unsigned /tb/igData
add wave -noupdate -radix unsigned /tb/ibData
add wave -noupdate -radix unsigned /tb/oReq
add wave -noupdate -radix unsigned /tb/oRdAddress
add wave -noupdate -radix unsigned /tb/oWrAddress
add wave -noupdate -radix unsigned /tb/dut/filter/r_conv/stripeStart
add wave -noupdate -radix unsigned /tb/dut/filter/r_conv/stripeOffset
add wave -noupdate -radix unsigned /tb/pixelCnt
add wave -noupdate -radix unsigned /tb/orData
add wave -noupdate -radix unsigned /tb/ogData
add wave -noupdate -radix unsigned /tb/obData
add wave -noupdate -radix unsigned /tb/g_filter_r
add wave -noupdate -radix unsigned /tb/g_filter_g
add wave -noupdate -radix unsigned /tb/g_filter_b
add wave -noupdate -radix unsigned /tb/dut/filter/r_conv/colShift
add wave -noupdate -radix unsigned /tb/dut/filter/r_conv/rowShift
add wave -noupdate -color Magenta -radix unsigned -radixenum symbolic /tb/oValidFilter
add wave -noupdate -radix unsigned /tb/dut/filter/r_conv/valid
add wave -noupdate -radix unsigned /tb/dut/filter/r_conv/img_done
add wave -noupdate -radix unsigned /tb/dut/filter/r_conv/rowCnt
add wave -noupdate -radix unsigned /tb/dut/filter/r_conv/readyRows
add wave -noupdate -radix unsigned /tb/dut/filter/r_conv/colCnt
add wave -noupdate -radix unsigned /tb/dut/filter/r_conv/ctrlState
add wave -noupdate -radix unsigned /tb/dut/filter/r_conv/pixelCnt
add wave -noupdate -radix decimal -childformat {{{/tb/dut/filter/r_conv/multIn[14]} -radix decimal -childformat {{{/tb/dut/filter/r_conv/multIn[14][3]} -radix decimal} {{/tb/dut/filter/r_conv/multIn[14][2]} -radix decimal} {{/tb/dut/filter/r_conv/multIn[14][1]} -radix decimal} {{/tb/dut/filter/r_conv/multIn[14][0]} -radix decimal}}} {{/tb/dut/filter/r_conv/multIn[13]} -radix decimal} {{/tb/dut/filter/r_conv/multIn[12]} -radix decimal} {{/tb/dut/filter/r_conv/multIn[11]} -radix decimal} {{/tb/dut/filter/r_conv/multIn[10]} -radix decimal} {{/tb/dut/filter/r_conv/multIn[9]} -radix decimal} {{/tb/dut/filter/r_conv/multIn[8]} -radix decimal} {{/tb/dut/filter/r_conv/multIn[7]} -radix decimal} {{/tb/dut/filter/r_conv/multIn[6]} -radix decimal} {{/tb/dut/filter/r_conv/multIn[5]} -radix decimal} {{/tb/dut/filter/r_conv/multIn[4]} -radix decimal} {{/tb/dut/filter/r_conv/multIn[3]} -radix decimal} {{/tb/dut/filter/r_conv/multIn[2]} -radix decimal} {{/tb/dut/filter/r_conv/multIn[1]} -radix decimal} {{/tb/dut/filter/r_conv/multIn[0]} -radix decimal}} -subitemconfig {{/tb/dut/filter/r_conv/multIn[14]} {-height 15 -radix decimal -childformat {{{/tb/dut/filter/r_conv/multIn[14][3]} -radix decimal} {{/tb/dut/filter/r_conv/multIn[14][2]} -radix decimal} {{/tb/dut/filter/r_conv/multIn[14][1]} -radix decimal} {{/tb/dut/filter/r_conv/multIn[14][0]} -radix decimal}}} {/tb/dut/filter/r_conv/multIn[14][3]} {-height 15 -radix decimal} {/tb/dut/filter/r_conv/multIn[14][2]} {-height 15 -radix decimal} {/tb/dut/filter/r_conv/multIn[14][1]} {-height 15 -radix decimal} {/tb/dut/filter/r_conv/multIn[14][0]} {-height 15 -radix decimal} {/tb/dut/filter/r_conv/multIn[13]} {-height 15 -radix decimal} {/tb/dut/filter/r_conv/multIn[12]} {-height 15 -radix decimal} {/tb/dut/filter/r_conv/multIn[11]} {-height 15 -radix decimal} {/tb/dut/filter/r_conv/multIn[10]} {-height 15 -radix decimal} {/tb/dut/filter/r_conv/multIn[9]} {-height 15 -radix decimal} {/tb/dut/filter/r_conv/multIn[8]} {-height 15 -radix decimal} {/tb/dut/filter/r_conv/multIn[7]} {-height 15 -radix decimal} {/tb/dut/filter/r_conv/multIn[6]} {-height 15 -radix decimal} {/tb/dut/filter/r_conv/multIn[5]} {-height 15 -radix decimal} {/tb/dut/filter/r_conv/multIn[4]} {-height 15 -radix decimal} {/tb/dut/filter/r_conv/multIn[3]} {-height 15 -radix decimal} {/tb/dut/filter/r_conv/multIn[2]} {-height 15 -radix decimal} {/tb/dut/filter/r_conv/multIn[1]} {-height 15 -radix decimal} {/tb/dut/filter/r_conv/multIn[0]} {-height 15 -radix decimal}} /tb/dut/filter/r_conv/multIn
add wave -noupdate -radix decimal /tb/dut/filter/r_conv/coefIn
add wave -noupdate /tb/dut/filter/r_conv/rf
add wave -noupdate -radix unsigned /tb/rInput
add wave -noupdate -radix decimal -childformat {{{/tb/dut/filter/r_conv/multRes[14]} -radix decimal} {{/tb/dut/filter/r_conv/multRes[13]} -radix decimal} {{/tb/dut/filter/r_conv/multRes[12]} -radix decimal} {{/tb/dut/filter/r_conv/multRes[11]} -radix decimal} {{/tb/dut/filter/r_conv/multRes[10]} -radix decimal} {{/tb/dut/filter/r_conv/multRes[9]} -radix decimal} {{/tb/dut/filter/r_conv/multRes[8]} -radix decimal} {{/tb/dut/filter/r_conv/multRes[7]} -radix decimal} {{/tb/dut/filter/r_conv/multRes[6]} -radix decimal} {{/tb/dut/filter/r_conv/multRes[5]} -radix decimal} {{/tb/dut/filter/r_conv/multRes[4]} -radix decimal} {{/tb/dut/filter/r_conv/multRes[3]} -radix decimal} {{/tb/dut/filter/r_conv/multRes[2]} -radix decimal} {{/tb/dut/filter/r_conv/multRes[1]} -radix decimal} {{/tb/dut/filter/r_conv/multRes[0]} -radix decimal}} -subitemconfig {{/tb/dut/filter/r_conv/multRes[14]} {-height 15 -radix decimal} {/tb/dut/filter/r_conv/multRes[13]} {-height 15 -radix decimal} {/tb/dut/filter/r_conv/multRes[12]} {-height 15 -radix decimal} {/tb/dut/filter/r_conv/multRes[11]} {-height 15 -radix decimal} {/tb/dut/filter/r_conv/multRes[10]} {-height 15 -radix decimal} {/tb/dut/filter/r_conv/multRes[9]} {-height 15 -radix decimal} {/tb/dut/filter/r_conv/multRes[8]} {-height 15 -radix decimal} {/tb/dut/filter/r_conv/multRes[7]} {-height 15 -radix decimal} {/tb/dut/filter/r_conv/multRes[6]} {-height 15 -radix decimal} {/tb/dut/filter/r_conv/multRes[5]} {-height 15 -radix decimal} {/tb/dut/filter/r_conv/multRes[4]} {-height 15 -radix decimal} {/tb/dut/filter/r_conv/multRes[3]} {-height 15 -radix decimal} {/tb/dut/filter/r_conv/multRes[2]} {-height 15 -radix decimal} {/tb/dut/filter/r_conv/multRes[1]} {-height 15 -radix decimal} {/tb/dut/filter/r_conv/multRes[0]} {-height 15 -radix decimal}} /tb/dut/filter/r_conv/multRes
add wave -noupdate -radix unsigned /tb/dut/filter/r_conv/multlvl1
add wave -noupdate -radix unsigned /tb/dut/filter/r_conv/multlvl2
add wave -noupdate -radix unsigned /tb/dut/filter/r_conv/multlvl3
add wave -noupdate -radix unsigned /tb/dut/filter/r_conv/multlvl4
add wave -noupdate -radix unsigned /tb/dut/filter/r_conv/out
add wave -noupdate -radix unsigned /tb/dut/filter/r_conv/out_cat
add wave -noupdate -radix unsigned /tb/dut/filter/r_conv/moData
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {16017193 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 224
configure wave -valuecolwidth 129
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {15961199 ps} {16181640 ps}
