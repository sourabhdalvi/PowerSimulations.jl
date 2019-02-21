
@test try
ps_model = PSI.CanonicalModel(Model(GLPK_optimizer),
                              Dict{String, JuMP.Containers.DenseAxisArray{JuMP.VariableRef}}(),
                              Dict{String, JuMP.Containers.DenseAxisArray}(),
                              nothing,
                              Dict{String, PSI.JumpAffineExpressionArray}("var_active" => PSI.JumpAffineExpressionArray(undef, 14, 24),
                                                                         "var_reactive" => PSI.JumpAffineExpressionArray(undef, 14, 24)),
                              Dict{String,Any}(),
                              Dict());
PSI.constructdevice!(ps_model, PSY.ThermalGen, PSI.ThermalUnitCommitment, PM.DCPlosslessForm, sys5b);
true finally end

@test try
ps_model = PSI.CanonicalModel(Model(),
                              Dict{String, JuMP.Containers.DenseAxisArray{JuMP.VariableRef}}(),
                              Dict{String, JuMP.Containers.DenseAxisArray}(),
                              nothing,
                              Dict{String, PSI.JumpAffineExpressionArray}("var_active" => PSI.JumpAffineExpressionArray(undef, 14, 24),
                                                                         "var_reactive" => PSI.JumpAffineExpressionArray(undef, 14, 24)),
                              Dict{String,Any}(),
                              Dict());
PSI.constructdevice!(ps_model, PSY.ThermalGen, PSI.ThermalUnitCommitment, PM.StandardACPForm, sys5b);
true finally end

@test try
    ps_model = PSI.CanonicalModel(Model(GLPK_optimizer),
                                  Dict{String, JuMP.Containers.DenseAxisArray{JuMP.VariableRef}}(),
                                  Dict{String, JuMP.Containers.DenseAxisArray}(),
                                  nothing,
                              Dict{String, PSI.JumpAffineExpressionArray}("var_active" => PSI.JumpAffineExpressionArray(undef, 14, 24),
                                                                         "var_reactive" => PSI.JumpAffineExpressionArray(undef, 14, 24)),
                              Dict{String,Any}(),
                              Dict());
    PSI.constructdevice!(ps_model, PSY.ThermalGen, PSI.ThermalDispatch, PM.DCPlosslessForm, sys5b);
    true finally end

@test try
    ps_model = PSI.CanonicalModel(Model(ipopt_optimizer),
                                  Dict{String, JuMP.Containers.DenseAxisArray{JuMP.VariableRef}}(),
                                  Dict{String, JuMP.Containers.DenseAxisArray}(),
                                  nothing,
                              Dict{String, PSI.JumpAffineExpressionArray}("var_active" => PSI.JumpAffineExpressionArray(undef, 14, 24),
                                                                         "var_reactive" => PSI.JumpAffineExpressionArray(undef, 14, 24)),
                              Dict{String,Any}(),
                              Dict());
    PSI.constructdevice!(ps_model, PSY.ThermalGen, PSI.ThermalDispatch, PM.StandardACPForm, sys5b);
    true finally end

@test try
    ps_model = PSI.CanonicalModel(Model(GLPK_optimizer),
                                    Dict{String, JuMP.Containers.DenseAxisArray{JuMP.VariableRef}}(),
                                    Dict{String, JuMP.Containers.DenseAxisArray}(),
                                    nothing,
                              Dict{String, PSI.JumpAffineExpressionArray}("var_active" => PSI.JumpAffineExpressionArray(undef, 14, 24),
                                                                         "var_reactive" => PSI.JumpAffineExpressionArray(undef, 14, 24)),
                              Dict{String,Any}(),
                              Dict());
    PSI.constructdevice!(ps_model, PSY.ThermalGen, PSI.ThermalDispatchNoMin, PM.DCPlosslessForm, sys5b);
    true finally end

@test try
    ps_model = PSI.CanonicalModel(Model(ipopt_optimizer),
                                    Dict{String, JuMP.Containers.DenseAxisArray{JuMP.VariableRef}}(),
                                    Dict{String, JuMP.Containers.DenseAxisArray}(),
                                    nothing,
                              Dict{String, PSI.JumpAffineExpressionArray}("var_active" => PSI.JumpAffineExpressionArray(undef, 14, 24),
                                                                         "var_reactive" => PSI.JumpAffineExpressionArray(undef, 14, 24)),
                              Dict{String,Any}(),
                              Dict());
    PSI.constructdevice!(ps_model, PSY.ThermalGen, PSI.ThermalDispatchNoMin, PM.StandardACPForm, sys5b);
    true finally end