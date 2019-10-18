
"""
    solve_op_model!(op_model::OperationModel; kwargs...)

This solves the operational model for a single instance and 
outputs results of type OperationModelResult: objective value, time log,
a dictionary of variables and their dataframe of results, and a time stamp.

# Arguments

-`op_model::OperationModel = op_model`: operation model 

# Examples

```julia
results = solve_op_model!(OpModel)
```
# Accepted Key Words 

* save_path::String : If a file path is provided the results 
automatically get written to feather files
* optimizer : The optimizer that is used to solve the model
"""
function solve_op_model!(op_model::OperationModel; kwargs...)

    timed_log = Dict{Symbol, Any}()

    save_path = get(kwargs, :save_path, nothing)

    if op_model.canonical.JuMPmodel.moi_backend.state == MOIU.NO_OPTIMIZER

        if !(:optimizer in keys(kwargs))
            error("No Optimizer has been defined, can't solve the operational problem")
        end

        _, timed_log[:timed_solve_time],
        timed_log[:solve_bytes_alloc],
        timed_log[:sec_in_gc] = @timed JuMP.optimize!(op_model.canonical.JuMPmodel,
                                                        kwargs[:optimizer])

    else

        _, timed_log[:timed_solve_time],
        timed_log[:solve_bytes_alloc],
        timed_log[:sec_in_gc] = @timed JuMP.optimize!(op_model.canonical.JuMPmodel)

    end
    #creating the results to print to memory
    vars_result = get_model_result(op_model)
    optimizer_log = get_optimizer_log(op_model)
    time_stamp = get_time_stamp(op_model)
    n = size(time_stamp,1)
    time_stamp = time_stamp[1:n-1, :]
    obj_value = Dict(:OBJECTIVE_FUNCTION => JuMP.objective_value(op_model.canonical.JuMPmodel))
    merge!(optimizer_log, timed_log)

    #results to be printed to memory
    results = OperationModelResults(vars_result, obj_value, optimizer_log, time_stamp)

    !isnothing(save_path) && write_model_results(results, save_path)

     return results

end

function _run_stage(stage::_Stage, start_time::Dates.DateTime, results_path::String)

    if stage.canonical.JuMPmodel.moi_backend.state == MOIU.NO_OPTIMIZER
        error("No Optimizer has been defined, can't solve the operational problem stage with key $(stage.key)")
    end

    timed_log = Dict{Symbol, Any}()
    _, timed_log[:timed_solve_time],
    timed_log[:solve_bytes_alloc],
    timed_log[:sec_in_gc] = @timed JuMP.optimize!(stage.canonical.JuMPmodel)
    model_status = JuMP.primal_status(stage.canonical.JuMPmodel)
    if model_status != MOI.FEASIBLE_POINT::MOI.ResultStatusCode
        error("Stage $(stage.key) status is $(model_status)")
    end
    _export_model_result(stage, start_time, results_path)
    _export_optimizer_log(timed_log, stage.canonical, results_path)
    stage.execution_count += 1

    return

end

""" 
    run_sim_model!(sim::Simulation; verbose::Bool = false, kwargs...)

Solves the simulation model for sequential Simulations
and populates a nested folder structure created in Simulation()
with a dated folder of featherfiles that contain the results for
each stage and step. 

# Arguments
- `sim::Simulation=sim`: simulation object created by Simulation()

# Example
```julia
sim = Simulation("test", 7, stages, "/Users/lhanig/Downloads/";
verbose = true, system_to_file = false)
run_sim_model!(sim::Simulation; verbose::Bool = false, kwargs...)
```

Accepted Key Words
`no_dict::Bool = true`: if :no_dict is true a reference dictionary is not created.
if no_dict is not used or it's false, a reference dictionary is created.

"""
function run_sim_model!(sim::Simulation; verbose::Bool = false, kwargs...)
    
    if sim.ref.reset
        sim.ref.reset = false
    elseif sim.ref.reset == false
        error("Reset the simulation")
    end
    
    variable_names = Dict()
    steps = get_steps(sim)
    for s in 1:steps
        verbose && println("Step $(s)")
        for (ix, stage) in enumerate(sim.stages)
            verbose && println("Stage $(ix)")
            interval = PSY.get_forecasts_interval(stage.sys)
            for run in 1:stage.executions
                sim.ref.current_time = sim.ref.date_ref[ix]
                verbose && println("Simulation TimeStamp: $(sim.ref.current_time)")
                raw_results_path = joinpath(sim.ref.raw,"step-$(s)-stage-$(ix)","$(sim.ref.current_time)")
                mkpath(raw_results_path)
    
                update_stage!(stage, s, sim)
                _run_stage(stage, sim.ref.current_time, raw_results_path)
                sim.ref.run_count[s][ix] += 1
                sim.ref.date_ref[ix] = sim.ref.date_ref[ix] + interval
            end
            @assert stage.executions == stage.execution_count
            stage.execution_count = 0 # reset stage execution_count
        end
        
    end
    date_run = convert(String,last(split(dirname(sim.ref.raw),"/")))
    references = make_references(sim, date_run)

    if (:no_dict in keys(kwargs)) == true
        return
    else 
        date_run = convert(String,last(split(dirname(sim.ref.raw),"/")))
        references = make_references(sim, date_run)
        return references
    end

end
""" 
    make_references(sim::Simulation, date_run::String)
Creates a dictionary of variables with a dictionary of stages
that contains dataframes of date/step/and desired file path
so that the results can be parsed sequentially by variable
and stage type.
**Note:** make_references can only be run after run_sim_model
or else, the folder structure will not yet be populated with results
# Arguments
-`sim::Simulation = sim`: simulation object created by Simulation()
-`date_run::String = "2019-10-03T09-18-00-test"``: the name of the file created
that contains the specific simulation run of the date run and "-test"
# Example
```julia
sim = Simulation("test", 7, stages, "/Users/lhanig/Downloads/"; verbose = true, system_to_file = false)
run_sim_model!(sim::Simulation; verbose::Bool = false, kwargs...)
references = make_references(sim, "2019-10-03T09-18-00-test")
```
"""

function make_references(sim::Simulation, date_run::String)
  
    sim.ref.date_ref[1] = sim.daterange[1]
    sim.ref.date_ref[2] = sim.daterange[1]

    references = Dict()
    for (ix, stage) in enumerate(sim.stages)

        variables = Dict()
        interval = PSY.get_forecasts_interval(stage.sys)
        variable_names = collect(keys(sim.stages[ix].canonical.variables))
        for n in 1:length(variable_names)
            variables[variable_names[n]] = DataFrames.DataFrame(Date = Dates.DateTime[],
                                           Step = String[], File_Path = String[])
        end
        for s in 1:(sim.steps)
            for run in 1:stage.executions
                sim.ref.current_time = sim.ref.date_ref[ix]
                for n in 1:length(variable_names)
            
                    initial_path = joinpath(dirname(dirname(sim.ref.raw)), date_run, "raw_output")
                    full_path = joinpath(initial_path, "step-$(s)-stage-$(ix)",
                                "$(sim.ref.current_time)", "$(variable_names[n]).feather")
        
                    if isfile(full_path)
                        date_df = DataFrames.DataFrame(Date = sim.ref.current_time, 
                                                       Step = "step-$(s)", File_Path = full_path)
                        variables[variable_names[n]] = vcat(variables[variable_names[n]], date_df)
                    else
                        println("$full_path, no such file")        
                     end
                end
                sim.ref.run_count[s][ix] += 1 
                sim.ref.date_ref[ix] = sim.ref.date_ref[ix] + interval
                
            end
        end
        
        references["stage-$ix"] = variables
        stage.execution_count = 0 
    end
    return references
end

function add_references!(references::Dict, sim::Simulation, date_run::String, file_names::Array{AbstractString})
  
    sim.ref.date_ref[1] = sim.daterange[1]
    sim.ref.date_ref[2] = sim.daterange[1]

    # references = Dict()
    for (ix, stage) in enumerate(sim.stages)
        if stage.key == 2
            variables = Dict()
            interval = PSY.get_forecasts_interval(stage.sys)
            #     variable_names = collect(keys(sim.stages[ix].canonical.variables))
            for n in 1:length(file_names)
                variables[file_names[n]] = DataFrames.DataFrame(Date = Dates.DateTime[],
                                            Step = String[], File_Path = String[])
            end
            for s in 1:(sim.steps)
                for run in 1:stage.executions
                    sim.ref.current_time = sim.ref.date_ref[ix]
                    for n in 1:length(file_names)
                
                        initial_path = joinpath(dirname(dirname(sim.ref.raw)), date_run, "raw_output")
                        full_path = joinpath(initial_path, "step-$(s)-stage-$(ix)",
                                    "$(sim.ref.current_time)", "$(file_names[n]).feather")
            
                        if isfile(full_path)
                            date_df = DataFrames.DataFrame(Date = sim.ref.current_time, 
                                                            Step = "step-$(s)", File_Path = full_path)
                            variables[file_names[n]] = vcat(variables[file_names[n]], date_df)
                        else
                            println("$full_path, no such file")        
                            end
                    end
                    sim.ref.run_count[s][ix] += 1 
                    sim.ref.date_ref[ix] = sim.ref.date_ref[ix] + interval
                    
                end
            end
            for (k,v) in variables
                push!(references, k => v)
            end
        end
    # references["stage-$ix"] = variables
    stage.execution_count = 0 
    end
    return references
end
