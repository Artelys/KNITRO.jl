#*******************************************************
#* Copyright (c) 2018 by Artelys                       *
#* All Rights Reserved                                 *
#*******************************************************

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#  This example demonstrates how to use Knitro to solve the following
#  simple linear programming problem (LP).
#  (This example from "Numerical Optimization", J. Nocedal and S. Wright)
#
#     minimize     -4*x0 - 2*x1
#     subject to   x0 + x1 + x2        = 5
#                  2*x0 + 0.5*x1 + x3  = 8
#                 0 <= (x0, x1, x2, x3)
#  The optimal solution is:
#     obj=17.333 x=[3.667,1.333,0,0]
#
#  The purpose is to illustrate how to invoke Knitro using the C
#  language API.
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


using KNITRO

# Create a new Knitro solver instance.
kc = KNITRO.KN_new()

# Illustrate how to override default options by reading from
# the knitro.opt file.
KNITRO.KN_load_param_file(kc, "examples/knitro.opt")

# Initialize Knitro with the problem definition.

# Add the variables and set their bounds.
# Note: unset bounds assumed to be infinite.
xIndices = KNITRO.KN_add_vars!(kc, 4)
for x in xIndices
    KNITRO.KN_set_var_lobnd(kc, x, 0.0)
end

# Add the constraints and set the rhs and coefficients.
KNITRO.KN_add_cons!(kc, 2)
KNITRO.KN_set_con_eqbnds!(kc,  [5., 8.])
# Add Jacobian structure and coefficients.
# First constraint
jacIndexCons = [0, 0, 0]
jacIndexVars = [0, 1, 2]
jacCoefs = [1.0, 1.0, 1.0]
# Second constraint
jacIndexCons = [jacIndexCons; [1, 1, 1]]
jacIndexVars = [jacIndexVars; [0, 1, 3]]
jacCoefs = [jacCoefs; [2.0, 0.5, 1.0]]
KNITRO.KN_add_con_linear_struct(kc, jacIndexCons, jacIndexVars, jacCoefs)

# Set minimize or maximize (if not set, assumed minimize).
KNITRO.KN_set_obj_goal(kc, KNITRO.KN_OBJGOAL_MINIMIZE)

# Set the coefficients for the objective.
objIndices = Int32[0, 1]
objCoefs = [-4.0, -2.0]
KNITRO.KN_add_obj_linear_struct(kc, objIndices, objCoefs)

# Solve the problem.
#
# Return status codes are defined in "kn_defines.jl" and described
# in the Knitro manual.
nStatus = KNITRO.KN_solve(kc)

println("Knitro converged with final status = ", nStatus)

#= # An example of obtaining solution information. =#
#= nStatus, objSol, x, lambda_ =  KNITRO.KN_get_solution(kc) =#
#= println("  optimal objective value  = ", objSol) =#
#= println("  optimal primal values x  = ",   (x[0], x[1], x[2], x[3])) =#
#= #1= print ("  feasibility violation    = ", KNITRO.KN_get_abs_feas_error (kc)) =1# =#
#= #1= print ("  KKT optimality violation = ", KNITRO.KN_get_abs_opt_error (kc)) =1# =#

#= # Delete the Knitro solver instance. =#
KNITRO.KN_free(kc)