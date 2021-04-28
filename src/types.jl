
struct BIOM
    data::SparseMatrixCSC
    sample::NamedTuple
    observation::NamedTuple
end


function BIOM(data::SparseMatrixCSC,
        sample::Union{Nothing, NamedTuple}=nothing,
        observation::Union{Nothing, NamedTuple}=nothing)::BIOM
    if isnothing(sample)
        sample = (ids=Array([]), metadata=Dict(), groupmetadata=Dict())
    end
    if isnothing(observation)
        observation = (ids=Array([]), metadata=Dict(), groupmetadata=Dict())
    end
    
    required_keys = (:ids, :metadata, :groupmetadata)
    if  keys(sample) != required_keys
        throw(ArgumentError("sample should have keys: $(required_keys), but has keys: $(keys(sample))"))
    end
    if  keys(observation) != required_keys
        throw(ArgumentError("observation should have keys: $(required_keys), but has keys: $(keys(observation))"))
    end
    
    BIOM(data, sample, observation)
end

function BIOM(data::Matrix,
        sample::Union{Nothing, NamedTuple}=nothing,
        observation::Union{Nothing, NamedTuple}=nothing)::BIOM
    BIOM(sparse(data), sample, observation)
end

function BIOM(biom::Dict)
    #= parse data =#
    ptrs = biom["sample"]["matrix"]["indptr"]
    s = cat([fill(i-1, ptrs[i] - ptrs[i-1]) for i in 2:length(ptrs)]..., dims=1)
    o = biom["sample"]["matrix"]["indices"] .+ 1
    d = biom["sample"]["matrix"]["data"]
    data = sparse(s, o, d)
    #= read metadata =#
    si = biom["sample"]["ids"]
    sm = biom["sample"]["metadata"]
    sg = biom["sample"]["group-metadata"]
    oi = biom["observation"]["ids"]
    om = biom["observation"]["metadata"]
    og = biom["observation"]["group-metadata"]
    sample      = (ids=si, metadata=sm, groupmetadata=sg)
    observation = (ids=oi, metadata=om, groupmetadata=og)
    #= struct =#
    BIOM(data, sample, observation)
end

function BIOM(s::String)::BIOM
    biomdict = h5open(s, "r") do h5
        read(h5)
    end
    BIOM(biomdict)
end

Base.size(S::BIOM, i...) = Base.size(S.data, i...)

"""
    getindex(biom::BIOM, sample_ind, observation_ind) -> BIOM

return a subset of the data, and metadata in `BIOM` as specified by `sample_ind` and `observation_ind`.

Requires exactly two indices, but otherwise behaves the same as `getindex()` 
"""
function Base.getindex(S::BIOM, i, j) 
	function dict_subset(dic, sub)
		K =  keys(dic)
		subdict = Dict()
		for k in K
            # if size(dic(k)) == 0 || dic(k) === nothing
            #     subdict[k] = dic[k]
            if ndims(dic[k]) == 1
				subdict[k] = dic[k][sub]
			elseif ndims(dic[k]) == 2
				subdict[k] = dic[k][:, sub]
			else
				throw(error("$(ndims(dic[k])) dims in dict not implemented"))
			end
		end
		return subdict
	end
    data = SparseMatrixCSC(Base.getindex(S.data, i, j))
	sample = (
		ids = S.sample.ids[i],
		metadata = dict_subset(S.sample.metadata, i),
		groupmetadata = dict_subset(S.sample.groupmetadata, i)
	)
	observation = (
		ids = S.observation.ids[j],
		metadata = dict_subset(S.observation.metadata, j),
		groupmetadata = dict_subset(S.observation.groupmetadata, j)
	)

	return BIOM(data, sample, observation)
end

function Base.hash(S::BIOM)
    d = hash(S.data)
    s = hash(S.sample, d)
    o = hash(S.observation, s)
    return o
end

function Base.isequal(S::BIOM, T::BIOM)
    hash(S) == hash(T)
end

function (==)(S::BIOM, T::BIOM) 
    Base.isequal(S, T) 
end

Base.setindex!(S::BIOM, v, i, j) = Base.setindex!(S.data, v, i, j)