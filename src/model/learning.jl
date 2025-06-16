function add_learning!(system::System, model::Model)
    
    # Need all edges to define learning across all edges of a certain type
    edges = get_edges(system)

    for e in edges
        
        # Endogenous learning MARK: Learning
        if learning_parameter(e) != 0.0
            # Check if we have maximum capacity
            if max_capacity(e) == Inf
                error("Maximum capacity not specified for learning technology")
            end
    
            # Number of segments
            n_segments = 6
            segment_length = (max_capacity(e)-cumulative_capacity_init(e))/n_segments
            # Define exogenous points describing the piece-wise linear curve (cumulative cost as a function of cumulative capacity added)
            x_points = zeros(n_segments+1)
            y_points = zeros(n_segments+1)
            # First segment represents no new capacity and no learning
            push!(e.pwl_cost_slopes, investment_cost(e))
            # Define points
            for k in 1:n_segments+1
                if k == 1
                    x_points[k] = cumulative_capacity_init(e)
                elseif k >= 2
                    x_points[k] = (k-2)*(segment_length)+cumulative_capacity_init(e)
                end
                cost_point = investment_cost(e)*(x_points[k]/cumulative_capacity_init(e))^(-learning_parameter(e))
                # Estimate cost from fixed capacity points
                y_points[k] = (1/(1-learning_parameter(e)))*(x_points[k]*cost_point-investment_cost(e)*cumulative_capacity_init(e))
            end
            # All slopes on PWL curve
            for k in 2:n_segments
                push!(e.pwl_cost_slopes, (y_points[k+1] - y_points[k])/(x_points[k+1]-x_points[k]))
            end
            
            # SOS1 variables for piece-wise linearization
            e.segments_sos1 = @variable(model, [k in 1:n_segments], lower_bound = 0.0, base_name = "vSOS1SEG_$(id(e))_stage$(period_index(e))_seg_$k")
            @constraint(model, [k in 1:n_segments], segments_sos1(e)[k] <= 1)
            @constraint(model, sum(segments_sos1(e)[k] for k in 1:n_segments) == 1)
            # SOS1 constraint ensuring only one value is nonzero
            @constraint(model, segments_sos1(e) in SOS1())
            # Cumulative experience for estimating movement along the learning curve 
            e.cumulative_experience = @variable(model, [k in 1:n_segments], lower_bound = 0.0, base_name = "vCUMULCAP_$(id(e))_stage$(period_index(e))")
            
            curr_stage = period_index(e)
            # Delay learning
            cost_period = curr_stage - cc_duration(e)
    
            # Set cumulative_experience as sum of existing capacity and all new capacity
            @constraint(model, sum(cumulative_experience(e)[k] for k in 1:n_segments) == sum(new_capacity_track(e,k) for k=1:curr_stage) + cumulative_external_capacity(e))
    
            # Constraints ensuring segments_sos1 is chosen based on capacity decision
            @constraint(model, [k in 1:n_segments], cumulative_experience(e)[k] >= x_points[k]*segments_sos1(e)[k])
    
            @constraint(model, [k in 1:n_segments], cumulative_experience(e)[k] <= x_points[k+1]*segments_sos1(e)[k])
            println("points")
            println(x_points)
            println(y_points)
            println("All slopes")
            println(e.pwl_cost_slopes)
            # Slope reached after building new capacity
            e.learning_pwl_slope = @expression(model, sum(segments_sos1(e)[k] * pwl_cost_slopes(e)[k] for k in 1:n_segments))
            e.learning_pwl_track[period_index(e)] = learning_pwl_slope(e)
            e.segments_sos1_track[period_index(e)] = segments_sos1(e)
            
            # Determine investment cost
            # Depends on learning lag
            if curr_stage <= cc_duration(e)
                # e.endog_investment_cost = annualized_investment_cost(e)
                e.annualized_investment_cost_with_learning = annualized_investment_cost(e)*new_capacity(e)
                e.endog_annualized_cost = annualized_investment_cost(e)
                e.segments_sos1_prev = segments_sos1_track(e, curr_stage)
    
            else
                # e.endog_investment_cost = learning_pwl_track(e, cost_period)*annualization_factor(e)
                
                # Linearize 
                e.segments_sos1_prev = segments_sos1_track(e, cost_period)
                e.aux_new_capacity = @variable(model, [k in 1:n_segments], lower_bound = 0.0)
                # Upper bound on new capacity in a given period
                big_M_capacity = max_new_capacity(e)
                
                @constraint(model, [k in 1:n_segments], e.new_capacity - e.aux_new_capacity[k] >= 0)
                @constraint(model, [k in 1:n_segments], e.new_capacity - e.aux_new_capacity[k] <= big_M_capacity*(1-segments_sos1_prev(e)[k]))
                @constraint(model, [k in 1:n_segments], e.aux_new_capacity[k] <= big_M_capacity*e.segments_sos1_prev[k])
                e.annualized_investment_cost_with_learning = @expression(model, sum(e.pwl_cost_slopes[k]*e.aux_new_capacity[k]*annualization_factor(e) for k in 1:n_segments))
                
                # For reporting purposes
                e.endog_annualized_cost = @expression(model, sum(e.pwl_cost_slopes[k]*e.segments_sos1_prev[k]*annualization_factor(e) for k in 1:n_segments))
                # Enf of linearization
            end
        else
            e.endog_annualized_cost = annualized_investment_cost(e)
            # e.endog_investment_cost = annualized_investment_cost(e)
        end
    end
    return nothing
end


function get_tech_ids(system::System, type::String)
    tech_ids = Vector{Symbol}()
    tech_edges = Dict{Symbol,Vector{AbstractEdge}}()
    edges = get_edges(system)
    for e in edges 
        if tech_type(e) == type
            push!(tech_ids, id(e))
            if !haskey(tech_edges, id(e))
                tech_edges[id(e)] = [e]
            else
                push!(tech_edges[id(e)], e)
            end
        end
    end
    return tech_ids, tech_edges
end
