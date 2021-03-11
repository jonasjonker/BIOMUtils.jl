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
    x_col  = [h5file[y]["ids"][i+1] for i in h5file[x]["matrix"]["indices"]]
    y_col  = [i-1 for a  in 1:length(indptr)-1 for i in fill(a, indptr[a+1]-indptr[a])] 
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
