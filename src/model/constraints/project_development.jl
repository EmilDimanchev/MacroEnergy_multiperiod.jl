Base.@kwdef mutable struct DevelopmentConstraint <: PlanningConstraint
    value::Union{Missing,Vector{Float64}} = missing
    lagrangian_multiplier::Union{Missing,Vector{Float64}} = missing
    constraint_ref::Union{Missing,JuMPConstraint} = missing
end


function add_model_constraint!(ct::DevelopmentConstraint, y::Union{AbstractEdge,AbstractStorage}, model::Model)

    curr_period = period_index(y)
    prev_period = curr_period - 1

    if curr_period == 1
        # Track cumulative developed capacity
        # Definition and evaluation (DE)
        ct.constraint_ref = @constraint(model, de_capacity_track(y, curr_period) == new_de_capacity_track(y, curr_period))
        # Approvals and funding (AF)
        ct.constraint_ref = @constraint(model, new_af_capacity_track(y, curr_period) <= 0)
        ct.constraint_ref = @constraint(model, af_capacity_track(y, curr_period) == new_af_capacity_track(y, curr_period))
        # Construction and commissioning (CC)
        ct.constraint_ref = @constraint(model, new_cc_capacity_track(y, curr_period) <= 0)
        ct.constraint_ref = @constraint(model, cc_capacity_track(y, curr_period) == new_cc_capacity_track(y, curr_period))

        ct.constraint_ref = @constraint(model, new_capacity_track(y, curr_period) <= 0)

    elseif curr_period >= 2
        # Track cumulative developed capacity
        # Definition and evaluation (DE)
        ct.constraint_ref = @constraint(model, de_capacity_track(y, curr_period) == de_capacity_track(y, prev_period) + new_de_capacity_track(y, curr_period) - new_af_capacity_track(y, curr_period))
        # Approvals and funding (AF)
        ct.constraint_ref = @constraint(model, af_capacity_track(y, curr_period) == af_capacity_track(y, prev_period) + new_af_capacity_track(y, curr_period) - new_cc_capacity_track(y, curr_period))
        # Construction and commissioning (CC)
        ct.constraint_ref = @constraint(model, cc_capacity_track(y, curr_period) == cc_capacity_track(y, prev_period) + new_cc_capacity_track(y, curr_period) - new_capacity_track(y, curr_period))
        # Projects proceeding to next stage
        # Definition and evaluation (DE)
        ct.constraint_ref = @constraint(model, new_af_capacity_track(y, curr_period) <= de_capacity_track(y, prev_period))
        # Approvals and funding (AF)
        ct.constraint_ref = @constraint(model, new_cc_capacity_track(y, curr_period) <= af_capacity_track(y, prev_period))
        # Construction and commissioning (CC)
        ct.constraint_ref = @constraint(model, new_capacity_track(y, curr_period) <= cc_capacity_track(y, prev_period))
    end

    return nothing

end
