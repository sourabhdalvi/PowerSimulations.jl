struct EconomicDispatch<:AbstractOperationModel end
struct SCEconomicDispatch<:AbstractOperationModel end

function EconomicDispatch(sys::PSY.System, transmission::Type{S}; optimizer::Union{Nothing, JuMP.OptimizerFactory}=nothing, kwargs...) where {S<:PM.AbstractPowerModel}

    devices = Dict{Symbol, DeviceModel}(:ThermalGenerators => DeviceModel(PSY.ThermalGen, ThermalDispatch),
                                            :RenewableGenerators => DeviceModel(PSY.RenewableGen, RenewableFullDispatch),
                                            :Loads => DeviceModel(PSY.PowerLoad, StaticPowerLoad))

    branches = Dict{Symbol, DeviceModel}(:Lines => DeviceModel(PSY.Branch, SeriesLine))
    services = Dict{Symbol, ServiceModel}(:Reserves => ServiceModel(PSY.Reserve, AbstractReservesFormulation))

    return OperationModel(EconomicDispatch,
                                   transmission,
                                    devices,
                                    branches,
                                    services,
                                    system,
                                    optimizer = optimizer; kwargs...)

end

function SCEconomicDispatch(sys::PSY.System; optimizer::Union{Nothing, JuMP.OptimizerFactory}=nothing, kwargs...)

    if :PTDF in keys(kwargs)

        PTDF = kwargs[:PTDF]

    else
        @info "PTDF matrix not provided. It will be constructed using PowerSystems.PTDF"
        PTDF, A = PowerSystems.buildptdf(get_components(PSY.Branch, system), get_components(PSY.Bus, system));
    end

    devices = Dict{Symbol, DeviceModel}(:ThermalGenerators => DeviceModel(PSY.ThermalGen, ThermalDispatch),
    :RenewableGenerators => DeviceModel(PSY.RenewableGen, RenewableFullDispatch),
    :Loads => DeviceModel(PSY.PowerLoad, StaticPowerLoad))

    branches = Dict{Symbol, DeviceModel}(:Lines => DeviceModel(PSY.Branch, SeriesLine))
    services = Dict{Symbol, ServiceModel}(:Reserves => ServiceModel(PSY.Reserve, AbstractReservesFormulation))

    return OperationModel(EconomicDispatch,
                                    StandardPTDFModel,
                                    devices,
                                    branches,
                                    services,
                                    system,
                                    optimizer = optimizer; PTDF = PTDF, kwargs...)

end
