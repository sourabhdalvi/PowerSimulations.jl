# taking the outputted files for the variable DataFrame and writing them to a featherfile
function write_data(vars_results::Dict{Symbol, DataFrames.DataFrame}, save_path::AbstractString; kwargs...)
    file_type = get(kwargs, :file_type, Feather)
    if file_type == Feather || file_type == CSV
        for (k,v) in vars_results
            file_path = joinpath(save_path,"$(k).$(lowercase("$file_type"))")
            file_type.write(file_path, vars_results[k])
        end
    else
        error("unsupported file type: $file_type")
    end
    return
end

function write_data(data::DataFrames.DataFrame, save_path::AbstractString, file_name::String; kwargs...)
    if isfile(save_path)
        save_path = dirname(save_path)
    end
    file_type = get(kwargs, :file_type, Feather)
    if file_type == Feather || file_type == CSV
        file_path = joinpath(save_path,"$(file_name).$(lowercase("$file_type"))")
        file_type.write(file_path, data)
    else
        error("unsupported file type: $file_type")
    end
    return
end

function _write_optimizer_log(optimizer_log::Dict, save_path::AbstractString)

    optimizer_log[:dual_status] = Int(optimizer_log[:dual_status])
    optimizer_log[:termination_status] = Int(optimizer_log[:termination_status])
    optimizer_log[:primal_status] = Int(optimizer_log[:primal_status])
    optimizer_log = DataFrames.DataFrame(optimizer_log)
    file_path = joinpath(save_path,"optimizer_log.feather")
    Feather.write(file_path, optimizer_log)

    return

end

function _write_data(canonical::CanonicalModel, save_path::AbstractString; kwargs...)
    file_type = get(kwargs, :file_type, Feather)
    if file_type == Feather || file_type == CSV
        for (k, v) in vars(canonical)
            file_path = joinpath(save_path,"$(k).$(lowercase("$file_type"))")
            file_type.write(file_path, _result_dataframe_vars(v))
        end
    else
        error("unsupported file type: $file_type")
    end
    return
end

function _write_data_(canonical::CanonicalModel, save_path::AbstractString; kwargs...)
    file_type = get(kwargs, :file_type, Feather)
    if file_type == Feather || file_type == CSV
        (k, v) =  (:Price,con(canonical,:CopperPlateBalance))
        file_path = joinpath(save_path,"$(k).$(lowercase("$file_type"))")

        file_type.write(file_path, _result_dataframe_duals(v))
    else
        error("unsupported file type: $file_type")
    end
    return
end

function write_data(op_model::OperationModel, save_path::AbstractString; kwargs...)
    _write_data(op_model.canonical, save_path; kwargs...)
    return
end

function write_data(stage::_Stage, save_path::AbstractString; kwargs...)
    if stage.key == 2
        _write_data_(stage.canonical, save_path; kwargs...)
    end
    _write_data(stage.canonical, save_path; kwargs...)
    return
end

# These functions are writing directly to the feather file and skipping printing to memory.
function _export_model_result(stage::_Stage, start_time::Dates.DateTime, save_path::String)
    write_data(stage, save_path)
    write_data(get_time_stamp(stage, start_time), save_path, "time_stamp")
    return
end

function _export_optimizer_log(optimizer_log::Dict{Symbol, Any},
                               canonical_model::CanonicalModel,
                               path::String)

    optimizer_log[:obj_value] = JuMP.objective_value(canonical_model.JuMPmodel)
    optimizer_log[:termination_status] = Int(JuMP.termination_status(canonical_model.JuMPmodel))
    optimizer_log[:primal_status] = Int(JuMP.primal_status(canonical_model.JuMPmodel))
    optimizer_log[:dual_status] = Int(JuMP.dual_status(canonical_model.JuMPmodel))
    try
        optimizer_log[:solve_time] = MOI.get(canonical_model.JuMPmodel, MOI.SolveTime())
    catch
        @warn("SolveTime() property not supported by the Solver")
        optimizer_log[:solve_time] = NaN #"Not Supported by solver"
    end
    _write_optimizer_log(optimizer_log, path)
    return
end

""" Exports Operational Model Results to a path"""
function write_model_results(results::OperationModelResults, save_path::String)
    if !isdir(save_path)
        @error("Specified path is not valid. Run write_results to save results.")
    end
    _new_folder_path = replace_chars("$save_path/$(round(Dates.now(),Dates.Minute))", ":", "-")
    new_folder = mkdir(_new_folder_path)
    folder_path = new_folder
    write_data(results.variables, folder_path)
    _write_optimizer_log(results.optimizer_log, folder_path)
    write_data(results.time_stamp, folder_path, "time_stamp")
    println("Files written to $folder_path folder.")
    return
end

""" Exports the OpModel JuMP object in MathOptFormat"""
function write_op_model(op_model::OperationModel, save_path::String)
    _write_canonical_model(op_model.canonical, save_path)
    return
end

""" Exports the OpModel JuMP object in MathOptFormat"""
function _write_canonical_model(canonical_model::CanonicalModel, save_path::String)
    MOF_model = MOPFM
    MOI.copy_to(MOF_model, JuMP.backend(canonical_model.JuMPmodel))
    MOI.write_to_file(MOF_model, save_path)
    return
end
