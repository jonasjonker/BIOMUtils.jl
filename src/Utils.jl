"""
    read data, sample ID;s and observation ID's to DataFrame.
"""
function readCooccurrence(source::String, sort_on=nothing; abs_cutoff=nothing, rel_cutoff=nothing, uncommon_observation=-1)::DataFrame
    #= parse parameters =#
    if sort_on === nothing || startswith(lowercase(sort_on), "sample")
        x = "sample"
        y = "observation"
    elseif startswith(lowercase(sort_on), "observation")
        x = "observation"
        y = "sample"
    else
        throw(ArgumentError("Can't sort on $(sort_on). Choose sample [default] or observation"))
    end
    if abs_cutoff !== nothing && rel_cutoff !== nothing
        throw(ArgumentError("Can't have both a relative and absolute cutoff."))
    end
    if rel_cutoff !== nothing && (0 > rel_cutoff || rel_cutoff > 1)
        throw(ArgumentError("rel_cutoff is $(rel_cutoff), but should `nothing` or be between 0 and 1."))
    end
    #= read HDF5 file =#
    h5file = HDF5.h5open(source, "r") do h5
        read(h5)
    end
    #= set preprocess parameters =#
    n_obs = length(h5file["sample"]["matrix"]["indptr"])-1
    if abs_cutoff !== nothing && (0 > abs_cutoff || abs_cutoff > n_obs)
        throw(ArgumentError("abs_cutoff is $(abs_cutoff), but should be `nothing` or between 0 and $(n_obs)."))
    end
    if abs_cutoff !== nothing
        preprocess = true
        min_obs = abs_cutoff
    elseif rel_cutoff !== nothing
        preprocess = true
        min_obs = n_obs*rel_cutoff
    else
        preprocess = false
    end
    #= write data to dataframe =#
    indptr = h5file[x]["matrix"]["indptr"]
    # x_col  = [parse(Int, h5file[y]["ids"][i+1]) for i in h5file[x]["matrix"]["indices"]]
    x_col  = [i for i in h5file[x]["matrix"]["indices"]]
    y_col  = [Int32(i) for a  in 1:length(indptr)-1 for i in fill(a, indptr[a+1]-indptr[a])] 
    data   = h5file[x]["matrix"]["data"]
    if x == "sample"
        df = DataFrame(data = data, observation = x_col, sample = y_col)
    else
        df = DataFrame(data = data, observation = y_col, sample = x_col)
    end

    # df.observation = parse.(Int, df.observation)
    #= preprocess rare/uncommon observations =#
    c = countmap(df.observation)
    if preprocess
        for i in 1:length(df.observation)
            if c[df.observation[i]] < min_obs
                df.observation[i] = uncommon_observation
            end
        end
    end
    return df
end

function readBIOM(path::String)::Dict{String, Any}
    dict = h5open(path, "r") do h5
        read(h5)
    end
end

function isBIOM(path::String)::Bool
    di = readBIOM(path)
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
    if  ["sample", "observation"] ⊈ names(df)
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


function collapse()
end

# function preprocessBIOM!(inpath::String, outpath::String, rel_cutoff::Float64; uncommon_observation=-1)
#     @warn "This function is not very well tested yet. Please don't overwrite files that shouldn't be potentially corrupted"
#     if rel_cutoff !== nothing && (0 > rel_cutoff || rel_cutoff > 1)
#         throw(ArgumentError("rel_cutoff is $(rel_cutoff), but should `nothing` or be between 0 and 1."))
#     end
#     #= read HDF5 file =#
#     h5in = HDF5.h5open(inpath, "r") do h5
#         read(h5)
#     end
#     #= set preprocess parameters =#
#     n_obs = length(h5in["sample"]["matrix"]["indptr"])-1
#     min_obs = n_obs*rel_cutoff
#     #= add synthetic observation =#
#     push!(hdin["observation"]["ids"], "synthetic")
#     syn_id = length(hdin["observation"]["ids"])
#     #= change observation under cut off to synthetic =#
#     observations = hdin["sample"]["matrix"]["indices"]
#     obs_count = countmap(observations)
#     removed_ids = Set()
#     if preprocess
#         for i in 1:length(observations)
#             if obs_count[i] < min_obs
#                 push!(observations[i])
#                 observations[i] = syn_id
#             end
#         end
#     end
#     #= adjust ids index =#
#     obs_indptr = hdin["observation"]["matrix"]["indptr"]
#     updated_obs_indptr = [i for i in obs_indptr if !contains(removed_ids, i)]

#     #= sort data for hdf5 =#
#     sample_indptr = h5in["sample"]["matrix"]["indptr"]
#     df = DataFrame(observation = observations,
#                    data        = h5in["sample"]["matrix"]["data"], 
#                    sample      = [i-1 for a  in 1:length(sample_indptr)-1 for i in fill(a, sample_indptr[a+1]-sample_indptr[a])] )
#     sort!(df, :observation)
#     h5in["observation"]["matrix"]["data"] = df.data
#     h5in["observation"]["matrix"]["indices"] = df.sample

# end