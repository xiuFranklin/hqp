#
# Double integrator (continuous) example
#   providing the model via MEX S-function
#   and solving for an integer-valued control input
#

## compile sfun_dic.c to a MEX S-function

puts "Compiling MEX S-function..."
source mex.tcl
if {![file exists sfun_dic[mex_extension]]
    || [file mtime sfun_dic.c] > [file mtime sfun_dic[mex_extension]]} {
    mex sfun_dic.c
}

## run optimization

puts "Running optimization..."
package require Omuses

## configure problem

# optimization program and model name
prg_name SFunctionOpt
mdl_name sfun_dic
mdl_path ./sfun_dic[mex_extension sfun_dic]

# setup stages and sample periods per stage
#prg_KK 60
prg_KK 40
#prg_KK 10

prg_sps 1
prg_multistage 1
prg_setup_stages

# model inputs and sample time points
set KK [prg_KK]
set dt [expr 1.0/$KK]
set us {}
set ts {}
for {set kk 0} {$kk <= $KK} {incr kk} {
    lappend us -2.0
    lappend ts [expr $dt*$kk]
}
mdl_us $us
prg_ts $ts

# initial states
mdl_x0 		{1.0 0.0}

# path constraints at all times
mdl_y_max 	{Inf 0.1}

# constraints at final time
mdl_yf_min 	{-1.0 0.0}
mdl_yf_max 	{-1.0 0.0}

# interpolation order for inputs
mdl_u_order 	{0}

# determine controlled (active) inputs
mdl_u_active 	{1}
mdl_u_integer 	{1}
mdl_u_min       {-10}
mdl_u_max       {2}

# define optimization objective
#mdl_u_weight2 	{1.0} ;# note: can't use non-linear objective with LPSolve!
mdl_y_weight1 	{0.0 1.0}
mdl_y_min       {-Inf, 0.0}

## setup and solve problem

# setup optimization problem
prg_setup

# simulate initial solution
prg_simulate

# setup solver

if 1 {
  # configure MIP solver
  sqp_solver None
  mip_solver LPSolve
  #mip_gap 0.001
  #mip_timeout 1
  #mip_logging 0
} else {
  # initialize SQP solver
  sqp_init
}

# drive solution
catch hqp_solve result

# output results
puts "Result   : $result"
puts "Objective: [prg_f]"
puts "Obj-evals: [prg_fbd_evals]"

puts "Control vector:"
puts [mdl_us]

# plot result
puts "Plotting resulting signals..."
if {[catch {package present Tk}] || [catch {package require BLT}]} {
    puts "Skipping plot as no blt::graph available."
} else {

    # read results and form vector of cumulative times
    set ts [prg_ts]
    set us [mdl_us]
    set ys [mdl_ys]
    set KK [prg_KK]
    set y1 {}
    set y2 {}
    for {set kk 0} {$kk <= $KK} {incr kk} {
	lappend y1 [lindex [lindex $ys $kk] 0]
	lappend y2 [lindex [lindex $ys $kk] 1]
    }
    if {[mdl_u_order] == 0} {
	set usmooth "step"
    } else {
	set usmooth "linear"
    }

    # create blt::graph in a toplevel window and plot data
    destroy .graph
    set graph [blt::graph .graph -title "[prg_name] demo"]
    $graph element create u -xdata $ts -ydata $us -smooth $usmooth \
	-color red -symbol "" 
    $graph element create y1 -xdata $ts -ydata $y1 \
	-color blue -symbol "" -mapy y2
    $graph element create y2 -xdata $ts -ydata $y2 \
	-color green -symbol "" -mapy y2
    $graph axis configure x -title "Time"
    $graph axis configure y -title "Input"
    $graph axis configure y2 -hide false -title "Outputs"
    pack $graph -fill both -expand true
    wm deiconify .	;# bring window to front
}
