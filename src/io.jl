
function readBIOM(path::String, type::Type=BIOM)::Dict{String, Any}
    dict = h5open(path, "r") do h5
        read(h5)
    end
    if type == Dict
        return dict
    elseif type == BIOM
        return BIOM(dict)
    else
        throw(ArgumentError("$(type) not implemented."))
    end
end

function isBIOM(path::String)::Bool
    di = readBIOM(path, Dict)
    isBIOM(di)
end

function isBIOM(di::Dict{String, Any})::Bool
    k₁ = keys(di)
    if  length(k₁) != 2 && ["sample", "observation"] ⊆ k₁
        return false
    else
        k₂ₒ = keys(di["observation"])
        k₂ₛ = keys(di["sample"])
        if  length(k₂ₒ) != 4 && ["ids", "matrix", "metadata", "group-metadata"] ⊆ k₂ₒ &&
            length(k₂ₛ) != 4 && ["ids", "matrix", "metadata", "group-metadata"] ⊆ k₂ₛ
            return false
        else
            k₃ₒ = keys(di["observation"]["matrix"])
            k₃ₛ = keys(di["sample"]["matrix"])
            if  length(k₃ₒ) != 3 && ["data", "indptr", "indices"] ⊆ k₃ₒ &&
                length(k₃ₛ) != 3 && ["data", "indptr", "indices"] ⊆ k₃ₛ
                return false
            else
                return true
            end
        end
    end

end


function writeBIOM(path::String, df::DataFrame; 
                    sample_meta::Union{Nothing,Dict{String, <:Any}}       = nothing, 
                    sample_group_meta::Union{Nothing,Dict{String, <:Any}} = nothing, 
                    obs_meta::Union{Nothing,Dict{String, <:Any}}          = nothing, 
                    obs_group_meta::Union{Nothing,Dict{String, <:Any}}    = nothing)
    if  ["sample", "observation", "data"] ⊈ names(df)
        Throw(ArgumentError("Something bad happend."))
    end
    dfₒ   = sort(df, :observation)
    dfₛ   = sort(df, :sample)
	dataₒ = Array{Float64}(dfₒ.data)
	samₒ  = Array{Int32}(dfₒ.sample)
	obsₒ  = Array{Int32}([[findfirst(==(i), dfₒ.observation)-1 for i in unique(dfₒ.observation)]... , length(dfₒ.observation)])
	idₒ   = Array{String}(string.(sort(unique(dfₒ.observation))))
    dataₛ = Array{Float64}(dfₛ.data)
	obsₛ  = Array{Int32}(dfₛ.observation)
	samₛ  = Array{Int32}([[findfirst(==(i), dfₛ.sample)-1 for i in unique(dfₛ.sample)]... , length(dfₛ.sample)])
	idₛ   = Array{String}(string.(sort(unique(dfₛ.sample))))
    HDF5.h5write(path, "sample/ids", idₛ)    
    HDF5.h5write(path, "sample/matrix/data", dataₛ)    
    HDF5.h5write(path, "sample/matrix/indptr", samₛ)    
    HDF5.h5write(path, "sample/matrix/indices",obsₛ)    
    HDF5.h5write(path, "observation/ids", idₒ)    
    HDF5.h5write(path, "observation/matrix/data", dataₒ)    
    HDF5.h5write(path, "observation/matrix/indptr", obsₒ)    
    HDF5.h5write(path, "observation/matrix/indices", samₒ)    
    if sample_meta !== nothing
        for k in keys(sample_meta)
            HDF5.h5write(path, "sample/metadata/$(k)", sample_meta[k])    
        end
    end
    if sample_group_meta !== nothing
        for k in keys(sample_group_meta)
            HDF5.h5write(path, "sample/group-metadata/$(k)", sample_group_meta[k])    
        end
    end
    if obs_meta !== nothing
        for k in keys(obs_meta)
            HDF5.h5write(path, "observation/metadata/$(k)", obs_meta[k])    
        end
    end
    if obs_group_meta !== nothing
        for k in keys(obs_group_meta)
            HDF5.h5write(path, "sample/group-metadata/$(k)", obs_group_meta[k])    
        end
    end
end