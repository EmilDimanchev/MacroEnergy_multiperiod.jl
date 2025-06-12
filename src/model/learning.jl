function get_tech_ids(system::System, tech_type::String)
    tech_ids = Vector{Symbol}()
    tech_edges = Dict{Symbol,Vector{AbstractEdge}}()
    edges = get_edges(system)
    for e in edges 
        if tech_type(e) == tech_type
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
