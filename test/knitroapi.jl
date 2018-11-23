
using KNITRO
using Compat.Test

@testset "Knitro C interface" begin
    # get KNITRO.KNITRO release version
    rel = KNITRO.get_release()
    @test isa(rel, String)


    @testset "Definition of model" begin
        m = KNITRO.Model(KNITRO.Env())
        KNITRO.KN_load_param_file(m, "examples/knitro.opt")
        KNITRO.KN_reset_params_to_defaults(m)
    end
end


#= println() =#
#= println() =#
#= println("####################################################################") =#
#= println("### License Manager test") =#
#= println("####################################################################") =#
#= println() =#

#= pLMcontext = KNITRO.KN_checkout_license() =#
#= println(pLMcontext) =#

#= kc = KNITRO.KN_new_lm(pLMcontext) =#
#= KNITRO.KN_free(kc) =#
#= KNITRO.KN_release_license(pLMcontext) =#
function evalAll(kc, cb, evalRequest, evalResult, userParams)
    x = evalRequest.x
    evalRequestCode = evalRequest.evalRequestCode

    if evalRequestCode == KNITRO.KN_RC_EVALFC
        # Evaluate nonlinear objective
        evalResult.obj[1] = x[1] ^ 2 * x[3] + x[2] ^ 3 * x[3] ^ 2
    elseif evalRequestCode == KNITRO.KN_RC_EVALGA
        evalResult.objGrad[1] = 2 * x[1] * x[3]
        evalResult.objGrad[2] = 3 * x[2] ^ 2 * x[3] ^ 2
        evalResult.objGrad[3] = x[1] ^ 2 + 2 * x[2] ^ 3 * x[3]
    elseif evalRequestCode == KNITRO.KN_RC_EVALH
        evalResult.hess[1] = 2 * x[3]
        evalResult.hess[2] = 2 * x[1]
        evalResult.hess[3] = 6 * x[2] * x[3] ^ 2
        evalResult.hess[4] = 6 * x[2] ^ 2 * x[3]
        evalResult.hess[5] = 2 * x[2] ^ 3
    elseif evalRequestCode == KNITRO.KN_RC_EVALHV
        vec = evalRequest.vec
        evalResult.hessVec[1] =(2 * x[3]) * vec[1] +(2 * x[1]) * vec[3]
        evalResult.hessVec[2] =(6 * x[2] * x[3] ^ 2) * vec[2] +(6 * x[2] ^ 2 * x[3]) * vec[3]
        evalResult.hessVec[3] =(2 * x[1]) * vec[1] +(6 * x[2] ^ 2 * x[3]) * vec[2] +(2 * x[2] ^ 3) * vec[3]

    elseif evalRequestCode == KNITRO.KN_RC_EVALH_NO_F
        evalResult.hess[1] = 0
        evalResult.hess[2] = 0
        evalResult.hess[3] = 0
        evalResult.hess[4] = 0
        evalResult.hess[5] = 0

    elseif evalRequestCode == KNITRO.KN_RC_EVALHV_NO_F
        vec = evalRequest.vec
        evalResult.hessVec[1] = 0
        evalResult.hessVec[2] = lambda_[4] * vec[3]
        evalResult.hessVec[3] = lambda_[4] * vec[2]

    else
        return KNITRO.KN_RC_CALLBACK_ERR
    end
    return 0
end


println()
println()
println("####################################################################")
println("### First problem test")
println("####################################################################")
println()


@testset "First problem" begin
    kc = KNITRO.KN_new()
    @test isa(kc, KNITRO.Model)
    println(kc)

    release = KNITRO.get_release()
    println(release)

    KNITRO.KN_reset_params_to_defaults(kc)

    KNITRO.KN_save_param_file(kc, "examples/test_knitro.opt")
    KNITRO.KN_load_param_file(kc, "examples/tuner-fixed.opt")
    KNITRO.KN_load_tuner_file(kc, "examples/tuner-explore.opt")
    KNITRO.KN_set_param(kc, "algorithm", 0)
    KNITRO.KN_set_param(kc, "cplexlibname", ".")
    KNITRO.KN_set_param(kc, "xtol", 1e-15)
    KNITRO.KN_set_param(kc, KNITRO.KN_PARAM_ALG, KNITRO.KN_ALG_BAR_DIRECT)
    KNITRO.KN_set_param(kc, KNITRO.KN_PARAM_CPLEXLIB, ".")
    KNITRO.KN_set_param(kc, KNITRO.KN_PARAM_XTOL, 1e-15)

    @test KNITRO.KN_get_int_param(kc, "algorithm") == KNITRO.KN_ALG_BAR_DIRECT
    @test KNITRO.KN_get_double_param(kc, "xtol") == 1e-15
    @test KNITRO.KN_get_int_param(kc, KNITRO.KN_PARAM_ALG) == KNITRO.KN_ALG_BAR_DIRECT
    @test KNITRO.KN_get_double_param(kc, KNITRO.KN_PARAM_XTOL) == 1e-15
    @test KNITRO.KN_get_param_name(kc, KNITRO.KN_PARAM_XTOL)  == "xtol"

    @test KNITRO.KN_get_param_doc(kc, KNITRO.KN_PARAM_XTOL) == "# Step size tolerance used for terminating the optimization.\n"
    @test KNITRO.KN_get_param_type(kc, KNITRO.KN_PARAM_XTOL) == KNITRO.KN_PARAMTYPE_FLOAT
    @test KNITRO.KN_get_num_param_values(kc, KNITRO.KN_PARAM_XTOL) == 0

    @test KNITRO.KN_get_param_value_doc(kc, KNITRO.KN_PARAM_GRADOPT, 1) == "exact"

    @test KNITRO.KN_get_param_id(kc, "xtol") == KNITRO.KN_PARAM_XTOL

    # START: Some specific parameter settings
    KNITRO.KN_set_param(kc, "hessopt", 1)
    KNITRO.KN_set_param(kc, "presolve", 0)
    KNITRO.KN_set_param(kc, "outlev", 4)
    # END:   Some specific parameter settings

    # Perform a derivative check.
    KNITRO.KN_set_param(kc, KNITRO.KN_PARAM_DERIVCHECK, KNITRO.KN_DERIVCHECK_ALL)

    function newpt_callback(kc_ptr, x, lambda_, kc)
        println("Rel Feas Error = ", KNITRO.KN_get_rel_feas_error(kc))
        println("Rel Opt Error  = ", KNITRO.KN_get_rel_opt_error(kc))
        return 0
    end

    # Define objective goal
    objGoal = KNITRO.KN_OBJGOAL_MAXIMIZE
    KNITRO.KN_set_obj_goal(kc, objGoal)

    # Add the variables and set their bounds.
    nV = 3
    KNITRO.KN_add_vars!(kc, nV)
    KNITRO.KN_set_var_lobnds(kc, [0, 0.1, 0])
    KNITRO.KN_set_var_upbnds(kc, [0., 2, 2])

    # Define an initial point.
    KNITRO.KN_set_var_primal_init_values(kc, [1., 1, 1.5])
    KNITRO.KN_set_var_dual_init_values(kc,   [1., 1, 1, 1])

    # Add the constraints and set their bounds.
    nC = 1
    KNITRO.KN_add_cons!(kc, nC)
    KNITRO.KN_set_con_lobnds(kc,  [0.1])
    KNITRO.KN_set_con_upbnds(kc,  [2*2*0.99])

    # Load quadratic structure x1*x2 for the constraint.
    KNITRO.KN_add_con_quadratic_struct(kc, 0, 1, 2, 1.0)

    # Define callback functions.
    cb = KNITRO.KN_add_eval_callback(kc, evalAll)
    KNITRO.KN_set_cb_grad(kc, cb, evalAll)
    KNITRO.KN_set_cb_hess(kc, cb, 5, evalAll,
                          hessIndexVars1=Int32[0, 0, 1, 1, 2],
                          hessIndexVars2=Int32[0, 2, 1, 2, 2])

    KNITRO.KN_set_newpt_callback(kc, newpt_callback)

    # Add complementarity constraints.
    KNITRO.KN_set_compcons(kc, [KNITRO.KN_CCTYPE_VARVAR], Int32[0], Int32[1])

    # Solve the problem.
    KNITRO.KN_solve(kc)

    # Restart using the previous solution.
    nStatus, objSol, x, lambda_ = KNITRO.KN_get_solution(kc)
    KNITRO.KN_set_var_primal_init_values(kc, x)
    KNITRO.KN_set_var_dual_init_values(kc, lambda_)
    KNITRO.KN_solve(kc)

    # Restart with new variable bounds
    KNITRO.KN_set_var_lobnds(kc,  Float64[0., 0, 0])
    KNITRO.KN_set_var_upbnds(kc,  Float64[2., 2, 2])
    KNITRO.KN_solve(kc)

    # Retrieve relevant solve information
    println("FC_evals       = ", KNITRO.KN_get_number_FC_evals(kc))
    println("GA_evals       = ", KNITRO.KN_get_number_GA_evals(kc))
    println("H_evals        = ", KNITRO.KN_get_number_H_evals(kc))
    println("HV_evals       = ", KNITRO.KN_get_number_HV_evals(kc))
    println("number_iters   = ", KNITRO.KN_get_number_iters(kc))
    println("cg_iters       = ", KNITRO.KN_get_number_cg_iters(kc))
    println("abs_feas_error = ", KNITRO.KN_get_abs_feas_error(kc))
    println("rel_feas_error = ", KNITRO.KN_get_rel_feas_error(kc))
    println("abs_opt_error  = ", KNITRO.KN_get_abs_opt_error(kc))
    println("rel_opt_error  = ", KNITRO.KN_get_rel_opt_error(kc))
    println("csol           = ", KNITRO.KN_get_con_values(kc))

    nStatus, objSol, x, lambda_ = KNITRO.KN_get_solution(kc)
    println("nStatus        = ", nStatus)
    println("objSol         = ", objSol)
    println("x              = ", x)
    println("lambda_        = ", lambda_)

    KNITRO.KN_free(kc)
end

println()
println()
println("####################################################################")
println("### Second problem test")
println("####################################################################")
println()

kc = KNITRO.KN_new()
println(kc)

function prettyPrinting(str, userParams)
    s = "KNITRO-Julia: " * str
    println(s)
    return length(s)
end

KNITRO.KN_set_puts_callback(kc, prettyPrinting)

# START: Some specific parameter settings
KNITRO.KN_set_param(kc, "presolve", 0)
KNITRO.KN_set_param(kc, "ms_enable", 1)
KNITRO.KN_set_param(kc, "ms_maxsolves", 5)
KNITRO.KN_set_param(kc, "hessian_no_f", 1)
KNITRO.KN_set_param(kc, "hessopt", KNITRO.KN_HESSOPT_PRODUCT)
# END:   Some specific parameter settings

# Define objective goal
objGoal = KNITRO.KN_OBJGOAL_MAXIMIZE
KNITRO.KN_set_obj_goal(kc, objGoal)

# Add the variables and set their bounds.
nV = 3
KNITRO.KN_add_vars!(kc, nV)
KNITRO.KN_set_var_lobnds(kc, [0, 0.1, 0])
KNITRO.KN_set_var_upbnds(kc, [0., 2, 2])

# Define an initial point.
KNITRO.KN_set_var_primal_init_values(kc, [1, 1, 1.5])
KNITRO.KN_set_var_dual_init_values(kc, [1, 1, 1, 1.])

# Add the constraints and set their lower bounds.
nC = 1
KNITRO.KN_add_cons!(kc, nC)
KNITRO.KN_set_con_lobnds(kc,  [0.1])
KNITRO.KN_set_con_upbnds(kc,  [2*2*0.99])

# Load quadratic structure x1*x2 for the constraint.
KNITRO.KN_add_con_quadratic_struct(kc, 0, 1, 2, 1.0)

# Define callback functions.
cb = KNITRO.KN_add_eval_callback(kc, evalAll)
KNITRO.KN_set_cb_grad(kc, cb, evalAll)
KNITRO.KN_set_cb_hess(kc, cb, KNITRO.KN_DENSE_ROWMAJOR, evalAll)

function callback(name)
    function callbackFn(kc, x, lambda_, userParams)
        println(name)
        return 0
    end
    return callbackFn
end

KNITRO.KN_set_ms_process_callback(kc, callback("ms_process"))


function ms_initpt_callbackFn(kc, nSolveNumber, x, lambda_, userParams)
    println("ms_initpt_callback ", nSolveNumber)
    x[:] = [1, 1, 1.1 + 0.1 * nSolveNumber]
    lambda_[:] = [1., 1, 1, 1]
    return 0
end

# Set multistart initial point callback
KNITRO.KN_set_ms_initpt_callback(kc, ms_initpt_callbackFn)

# Add complementarity constraints.
KNITRO.KN_set_compcons(kc, [KNITRO.KN_CCTYPE_VARVAR], Int32[0], Int32[1])

# Solve the problem.
KNITRO.KN_solve(kc)

KNITRO.KN_free(kc)


println()
println()
println("####################################################################")
println("### Third problem test")
println("####################################################################")
println()

kc = KNITRO.KN_new()
println(kc)

KNITRO.KN_set_param(kc, "presolve", KNITRO.KN_PRESOLVEDBG_NONE)

# Define objective goal
objGoal = KNITRO.KN_OBJGOAL_MAXIMIZE
KNITRO.KN_set_obj_goal(kc, objGoal)

# Add the variables and set their bounds.
nV = 3
KNITRO.KN_add_vars!(kc, nV)
KNITRO.KN_set_var_lobnds(kc,  [0, 0.1, 0])
KNITRO.KN_set_var_upbnds(kc,  [0., 2, 2])

# Define an initial point.
KNITRO.KN_set_var_primal_init_values(kc, [1, 1, 1.5])
KNITRO.KN_set_var_dual_init_values(kc, [1., 1, 1, 1])

# Add the constraints and set their lower bounds.
nC = 1
KNITRO.KN_add_cons!(kc, nC)
KNITRO.KN_set_con_lobnds(kc, [0.1])
KNITRO.KN_set_con_upbnds(kc, [2*2*0.99])

# Load quadratic structure x1*x2 for the constraint.
KNITRO.KN_add_con_quadratic_struct(kc, 0, 1, 2, 1.0)

# Define callback functions.
cb = KNITRO.KN_add_eval_callback(kc, evalAll)
KNITRO.KN_set_cb_grad(kc, cb, evalAll)
KNITRO.KN_set_cb_hess(kc, cb, KNITRO.KN_DENSE_ROWMAJOR, evalAll)

KNITRO.KN_set_compcons(kc, [KNITRO.KN_CCTYPE_VARVAR], Int32[0], Int32[1])

KNITRO.KN_set_var_honorbnds(kc,
                            [KNITRO.KN_HONORBNDS_ALWAYS,
                             KNITRO.KN_HONORBNDS_INITPT,
                             KNITRO.KN_HONORBNDS_NO])

KNITRO.KN_set_var_scalings(kc, Int32[1,2,3],  [1.,1,1])
KNITRO.KN_set_con_scalings(kc,  [0.5])
KNITRO.KN_set_compcon_scalings(kc, [2.])
KNITRO.KN_set_obj_scaling(kc, 10.)

KNITRO.KN_solve(kc)

# Retrieve derivatives values
println("objGrad = ", KNITRO.KN_get_objgrad_values(kc))
println("jac     = ", KNITRO.KN_get_jacobian_values(kc))
println("hess    = ", KNITRO.KN_get_hessian_values(kc))

KNITRO.KN_free(kc)


println()
println()
println("####################################################################")
println("### Fourth problem test")
println("####################################################################")
println()

kc = KNITRO.KN_new()

# START: Some specific parameter settings
KNITRO.KN_set_param(kc, "presolve", 0)
KNITRO.KN_set_param(kc, "outlev", 6)
KNITRO.KN_set_param(kc, "gradopt", 2)
KNITRO.KN_set_param(kc, "hessopt", 2)
# END:   Some specific parameter settings

function evalF_evalGA(kc, cb, evalRequest, evalResult, userParams)
    x = evalRequest.x
    evalRequestCode = evalRequest.evalRequestCode

    if evalRequestCode == KNITRO.KN_RC_EVALFC
        # Evaluate nonlinear objective
        evalResult.obj[1] = x[1] ^ 2 * x[3] + x[2] ^ 3 * x[3] ^ 2
    elseif evalRequestCode == KNITRO.KN_RC_EVALGA
        evalResult.objGrad[1] = 2 * x[1] * x[3]
        evalResult.objGrad[2] = 3 * x[2] ^ 2 * x[3] ^ 2
        evalResult.objGrad[3] = x[1] ^ 2 + 2 * x[2] ^ 3 * x[3]
    else
        return KNITRO.KN_RC_CALLBACK_ERR
    end
    return 0
end

# Define objective goal
objGoal = KNITRO.KN_OBJGOAL_MAXIMIZE
KNITRO.KN_set_obj_goal(kc, objGoal)

# Add the variables and set their bounds.
nV = 3
KNITRO.KN_add_vars!(kc, nV)
KNITRO.KN_set_var_lobnds(kc,  [0, 0.1, 0])
KNITRO.KN_set_var_upbnds(kc,  [0., 2, 2])
KNITRO.KN_set_var_types(kc,  [KNITRO.KN_VARTYPE_CONTINUOUS, KNITRO.KN_VARTYPE_INTEGER, KNITRO.KN_VARTYPE_INTEGER])

# Define an initial point.
KNITRO.KN_set_var_primal_init_values(kc, [1, 1, 1.5])
KNITRO.KN_set_var_dual_init_values(kc, [1., 1, 1, 1])

# Add the constraints and set their lower bounds.
nC = 1
KNITRO.KN_add_cons!(kc, nC)
KNITRO.KN_set_con_lobnds(kc, [0.1])
KNITRO.KN_set_con_upbnds(kc, [2*2*0.99])

# Load quadratic structure x1*x2 for the constraint.
KNITRO.KN_add_con_quadratic_struct(kc, 0, 1, 2, 1.0)

# Define callback functions.
cb = KNITRO.KN_add_eval_callback(kc, evalF_evalGA)
KNITRO.KN_set_cb_grad(kc, cb, evalF_evalGA)

# Define complementarity constraints
KNITRO.KN_set_compcons(kc, [KNITRO.KN_CCTYPE_VARVAR], Int32[0], Int32[1])

# Set MIP parameters
KNITRO.KN_set_mip_branching_priorities(kc, Int32[0, 1, 2])
# KNITRO.KN_set_mip_intvar_strategies(kc, 2, KNITRO.KN_MIP_INTVAR_STRATEGY_MPEC) # not compatible with MPEC constraint as a variable cannot be involved in two different complementarity constraints.
KNITRO.KN_set_mip_node_callback(kc, callback("mip_node"))

# Set var, con and obj names
KNITRO.KN_set_var_names(kc,  ["myvar1", "myvar2", "myvar3"])
KNITRO.KN_set_con_names(kc,  ["mycon1"])
KNITRO.KN_set_obj_name(kc,  "myobj")

# Set feasibility tolerances
KNITRO.KN_set_var_feastols(kc,  [0.1, 0.001, 0.1])
KNITRO.KN_set_con_feastols(kc, [0.1])
KNITRO.KN_set_compcon_feastols(kc,  [0.1])

# Set finite differences step size
KNITRO.KN_set_cb_relstepsizes(kc, cb,  [0.1, 0.001, 0.1])

# Solve the problem.
KNITRO.KN_solve(kc)

println("number of nodes         = ", KNITRO.KN_get_mip_number_nodes(kc))
println("number of solves        = ", KNITRO.KN_get_mip_number_solves(kc))
println("absolute gap            = ", KNITRO.KN_get_mip_abs_gap(kc))
println("relative gap            = ", KNITRO.KN_get_mip_rel_gap(kc))
println("mip relaxation bound    = ", KNITRO.KN_get_mip_relaxation_bnd(kc))
println("lastnode objective      = ", KNITRO.KN_get_mip_lastnode_obj(kc))
println("csol                    = ", KNITRO.KN_get_con_values(kc))
println("mip incumbent objective = ", KNITRO.KN_get_mip_incumbent_obj(kc))
println("mip incumbent x         = ", KNITRO.KN_get_mip_incumbent_x(kc))

KNITRO.KN_free(kc)

println()
println()
println("####################################################################")
println("### Fifth problem test")
println("####################################################################")
println()

kc = KNITRO.KN_new()

# START: Some specific parameter settings
KNITRO.KN_set_param(kc, "outlev", 6)
KNITRO.KN_set_param(kc, "gradopt", 1)
# END:   Some specific parameter settings

function evalR(kc, cb, evalRequest, evalResult, userParams)
    x = evalRequest.x
    evalResult.rsd[1] = x[1] * x[2]^1.309 - 2.138
    evalResult.rsd[2] = x[1] * x[2]^1.471 - 3.421
    evalResult.rsd[3] = x[1] * x[2]^1.49 - 3.597
    evalResult.rsd[4] = x[1] * x[2]^1.565 - 4.34
    evalResult.rsd[5] = x[1] * x[2]^1.611 - 4.882
    evalResult.rsd[6] = x[1] * x[2]^1.68 - 5.66
    return 0
end

function evalJ(kc, cb, evalRequest, evalResult, userParams)
    x = evalRequest.x
    evalResult.rsdJac[1] = x[2]^1.309
    evalResult.rsdJac[2] = x[1] * log(1.309) * x[2]^1.309
    evalResult.rsdJac[3] = x[2]^1.471
    evalResult.rsdJac[4] = x[1] * log(1.471) * x[2]^1.471
    evalResult.rsdJac[5] = x[2]^1.49
    evalResult.rsdJac[6] = x[1] * log(1.49) * x[2]^1.49
    evalResult.rsdJac[7] = x[2]^1.565
    evalResult.rsdJac[8] = x[1] * log(1.565) * x[2]^1.565
    evalResult.rsdJac[9] = x[2]^1.611
    evalResult.rsdJac[10] = x[1] * log(1.611) * x[2]^1.611
    evalResult.rsdJac[11] = x[2]^1.68
    evalResult.rsdJac[12] = x[1] * log(1.68) * x[2]^1.68
    return 0
end

# Add the variables and set their bounds.
nV = 2
KNITRO.KN_add_vars!(kc, nV)
KNITRO.KN_set_var_lobnds(kc,  [ -1.0, -1.0 ])
KNITRO.KN_set_var_upbnds(kc,  [ 1.0, 1.0 ])
KNITRO.KN_set_var_primal_init_values(kc,  [ 1.0, 5.0 ])

# Add the residuals
KNITRO.KN_add_rsds!(kc, 6)

# Define callbacks
cb = KNITRO.KN_add_lsq_eval_callback(kc,  evalR)
nnzJ = 12
KNITRO.KN_set_cb_rsd_jac(kc, cb, nnzJ, evalJ,
                         jacIndexRsds=Int32[ 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5 ],
                         jacIndexVars=Int32[ 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1 ])

# Solve the problem.
KNITRO.KN_solve(kc)

println("jac     = ", KNITRO.KN_get_rsd_jacobian_values(kc))

nStatus, objSol, x, lambda_ = KNITRO.KN_get_solution(kc)
println("nStatus = ", nStatus)
println("objSol  = ", objSol)
println("x       = ", x)
println("lambda_ = ", lambda_)

KNITRO.KN_free(kc)