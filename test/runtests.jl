using BIOMUtils
using DataFrames
using HDF5
using StatsBase
using Test

function generate_testdata(dir::String; overwrite=false)
    small_taxonomy = [
        "k__Bacteria" "k__Bacteria" "k__Bacteria" "k__Bacteria" "k__Bacteria" "k__Bacteria" "k__Bacteria" "k__Bacteria" "k__Bacteria" "k__Bacteria" "k__Bacteria" "k__Bacteria" "k__Bacteria" "k__Bacteria" "k__Bacteria" "k__Bacteria" "k__Bacteria" "k__Bacteria" "k__Bacteria" "k__Bacteria" "k__Bacteria" "k__Bacteria" "k__Bacteria" "k__Bacteria" "k__Bacteria" "k__Bacteria" "k__Bacteria" "k__Bacteria" "k__Bacteria" "k__Bacteria"
        "p__Proteobacteria" "p__Bacteroidetes" "p__Actinobacteria" "p__Firmicutes" "p__Actinobacteria" "p__Acidobacteria" "p__Bacteroidetes" "p__Tenericutes" "p__Proteobacteria" "p__Actinobacteria" "p__Acidobacteria" "p__Proteobacteria" "p__Proteobacteria" "p__Bacteroidetes" "p__Proteobacteria" "p__Bacteroidetes" "p__Chloroflexi" "p__Proteobacteria" "p__Proteobacteria" "p__Bacteroidetes" "p__Firmicutes" "p__Proteobacteria" "p__Proteobacteria" "p__Actinobacteria" "p__Planctomycetes" "p__Proteobacteria" "p__Proteobacteria" "p__Proteobacteria" "p__Bacteroidetes" "p__Proteobacteria"
        "c__Betaproteobacteria" "c__[Saprospirae]" "c__MB-A2-108" "c__Bacilli" "c__Actinobacteria" "c__Solibacteres" "c__[Saprospirae]" "c__Mollicutes" "c__Deltaproteobacteria" "c__Actinobacteria" "c__Acidobacteriia" "c__Deltaproteobacteria" "c__Deltaproteobacteria" "c__[Saprospirae]" "c__Alphaproteobacteria" "c__Sphingobacteriia" "c__Ellin6529" "c__Gammaproteobacteria" "c__Gammaproteobacteria" "c__Flavobacteriia" "c__Bacilli" "c__Alphaproteobacteria" "c__Betaproteobacteria" "c__Thermoleophilia" "c__Planctomycetia" "c__Deltaproteobacteria" "c__Gammaproteobacteria" "c__Betaproteobacteria" "c__[Saprospirae]" "c__Betaproteobacteria"
        "o__MND1" "o__[Saprospirales]" "o__0319-7L14" "o__Bacillales" "o__Actinomycetales" "o__Solibacterales" "o__[Saprospirales]" "o__" "o__Bdellovibrionales" "o__Actinomycetales" "o__Acidobacteriales" "o__Myxococcales" "o__Desulfuromonadales" "o__[Saprospirales]" "o__Rhizobiales" "o__Sphingobacteriales" "o__" "o__PYR10d3" "o__Vibrionales" "o__Flavobacteriales" "o__Lactobacillales" "o__Rhodobacterales" "o__Neisseriales" "o__Solirubrobacterales" "o__Gemmatales" "o__Desulfobacterales" "o__Legionellales" "o__Burkholderiales" "o__[Saprospirales]" "o__Burkholderiales"
        "f__" "f__Chitinophagaceae" "f__" "f__Paenibacillaceae" "f__Corynebacteriaceae" "f__" "f__Chitinophagaceae" "f__" "f__Bacteriovoracaceae" "f__Frankiaceae" "f__Acidobacteriaceae" "f__" "f__Geobacteraceae" "f__Chitinophagaceae" "f__Hyphomicrobiaceae" "f__" "f__" "f__" "f__Pseudoalteromonadaceae" "f__[Weeksellaceae]" "f__Streptococcaceae" "f__Hyphomonadaceae" "f__Neisseriaceae" "f__Conexibacteraceae" "f__Isosphaeraceae" "f__Desulfobulbaceae" "f__Coxiellaceae" "f__Comamonadaceae" "f__Chitinophagaceae" "f__Comamonadaceae"
        "g__" "g__" "g__" "g__Paenibacillus" "g__Corynebacterium" "g__" "g__" "g__" "g__" "g__Frankia" "g__" "g__" "g__Geobacter" "g__" "g__Rhodoplanes" "g__" "g__" "g__" "g__Pseudoalteromonas" "g__Chryseobacterium" "g__Streptococcus" "g__" "g__Neisseria" "g__" "g__" "g__" "g__Aquicella" "g__" "g__" "g__"
        "s__" "s__" "s__" "s__" "s__" "s__" "s__" "s__" "s__" "s__" "s__" "s__" "s__" "s__" "s__" "s__" "s__" "s__" "s__" "s__" "s__" "s__" "s__" "s__" "s__" "s__" "s__" "s__" "s__" "s__"
    ]

    tiny_taxonomy = [
        "k__Bacteria" "k__Bacteria" "k__Bacteria" "k__Bacteria" "k__Bacteria" "k__Bacteria" "k__Bacteria" "k__Bacteria" "k__Bacteria" 
        "p__Proteobacteria" "p__Bacteroidetes" "p__Actinobacteria" "p__Firmicutes" "p__Actinobacteria" "p__Acidobacteria" "p__Bacteroidetes" "p__Tenericutes" "p__Proteobacteria" 
        "c__Betaproteobacteria" "c__[Saprospirae]" "c__MB-A2-108" "c__Bacilli" "c__Actinobacteria" "c__Solibacteres" "c__[Saprospirae]" "c__Mollicutes" "c__Deltaproteobacteria" 
        "o__MND1" "o__[Saprospirales]" "o__0319-7L14" "o__Bacillales" "o__Actinomycetales" "o__Solibacterales" "o__[Saprospirales]" "o__" "o__Bdellovibrionales" 
        "f__" "f__Chitinophagaceae" "f__" "f__Paenibacillaceae" "f__Corynebacteriaceae" "f__" "f__Chitinophagaceae" "f__" "f__Bacteriovoracaceae" 
        "g__" "g__" "g__" "g__Paenibacillus" "g__Corynebacterium" "g__" "g__" "g__" "g__" 
        "s__" "s__" "s__" "s__" "s__" "s__" "s__" "s__" "s__" 
    ]
    
    if !isfile(joinpath(dir, "small.biom")) || overwrite
        smalldf = DataFrame(data=Array{Float64}([]), observation=Array{Int32}([]), sample=Array{Int32}([]))
        w = Weights(Array{Float64}([50,50,10,10,10,10,5,5,5,5,5,5,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1]))
        exes = (
            countmap(sample(UnitRange{Int32}(1,30), w, 188)),
            countmap(sample(UnitRange{Int32}(1,30), w, 188)),
            countmap(sample(UnitRange{Int32}(1,30), w, 188))
        )
        for i in UnitRange{Int32}(1,30)
            for j in UnitRange{Int32}(1,3)
                if haskey(exes[j], i)
                    push!(smalldf, (exes[j][i], i, j))
                end
            end
        end
        writeBIOM(joinpath(dir, "small.biom"), smalldf)
    end
    if !isfile(joinpath(dir, "tiny.biom")) || overwrite
        tinydf = DataFrame( data=Array{Float64}([1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0]),
                            observation=Array{Int32}([1, 2, 3, 4, 1, 2, 4, 3, 4]), 
                            sample=Array{Int32}([1, 1, 1, 1, 2, 2, 2, 3, 3]) )
        writeBIOM(joinpath(dir, "tiny.biom"), tinydf)
    end
end


@testset "Utils.jl" begin

    if !isfile(joinpath("data", "small.biom")) || !isfile(joinpath("data", "tiny.biom"))
        generate_testdata("data")
    end


    ID   = 990
    ROOT = "/home/jonas/Repos/Thesis/data/"
    path = "$(ROOT)$(ID)/processed_data/99_otu_table.biom"
    df = readCooccurrence(path) 
    di = h5open(path, "r") do h5 
        read(h5)
    end

    @testset "readCooccurrence" begin
        @test df isa DataFrame
        @test df.data isa Array{Float64}
        @test df.observation isa Array{Int32}
        @test df.sample isa Array{Int32}
        @test_throws ArgumentError readCooccurrence(path, "nonsense")
        samOcc = readCooccurrence(path, "sample")
        obsOcc = readCooccurrence(path, "observation")
        @test sort(samOcc.data) == sort(obsOcc.data)
        @test sort(samOcc.data) == sort(obsOcc.data)
        @test sort(samOcc.data) == sort(obsOcc.data)
        @test_throws ArgumentError readCooccurrence(path; rel_cutoff=2)
        @test_throws ArgumentError readCooccurrence(path; abs_cutoff=length(samOcc.data)+1)
        @test_throws ArgumentError readCooccurrence(path; rel_cutoff=.2, abs_cutoff=20) 
    end

    @testset "readBIOM" begin
        @test readBIOM(path) isa Dict{String, Any}
    end

    @testset "isBIOM" begin
        @test isBIOM(path) == true
        @test isBIOM(di)   == true
    end

    @testset "writeBIOM" begin
        tiny_taxonomy = [
            "k__Bacteria" "k__Bacteria" "k__Bacteria" "k__Bacteria" "k__Bacteria" "k__Bacteria" "k__Bacteria" "k__Bacteria" "k__Bacteria" 
            "p__Proteobacteria" "p__Bacteroidetes" "p__Actinobacteria" "p__Firmicutes" "p__Actinobacteria" "p__Acidobacteria" "p__Bacteroidetes" "p__Tenericutes" "p__Proteobacteria" 
            "c__Betaproteobacteria" "c__[Saprospirae]" "c__MB-A2-108" "c__Bacilli" "c__Actinobacteria" "c__Solibacteres" "c__[Saprospirae]" "c__Mollicutes" "c__Deltaproteobacteria" 
            "o__MND1" "o__[Saprospirales]" "o__0319-7L14" "o__Bacillales" "o__Actinomycetales" "o__Solibacterales" "o__[Saprospirales]" "o__" "o__Bdellovibrionales" 
            "f__" "f__Chitinophagaceae" "f__" "f__Paenibacillaceae" "f__Corynebacteriaceae" "f__" "f__Chitinophagaceae" "f__" "f__Bacteriovoracaceae" 
            "g__" "g__" "g__" "g__Paenibacillus" "g__Corynebacterium" "g__" "g__" "g__" "g__" 
            "s__" "s__" "s__" "s__" "s__" "s__" "s__" "s__" "s__" 
        ]
        file = tempname("data", cleanup=true)
        tinydf = DataFrame( data=Array{Float64}([1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0]),
                            observation=Array{Int32}([1, 2, 3, 4, 1, 2, 4, 3, 4]), 
                            sample=Array{Int32}([1, 1, 1, 1, 2, 2, 2, 3, 3]) )
        writeBIOM(file, tinydf, obs_meta=Dict("taxonomy" => tiny_taxonomy))
        @test isfile(file)
        @test HDF5.ishdf5(file)
        di = h5open(file) do h5 
            read(h5)
        end
        @test di isa Dict{String, Any}
        @test ["sample", "observation"] ⊆ keys(di)
        @test isBIOM(file)
        @test di["observation"]["metadata"]["taxonomy"] == tiny_taxonomy
    end

    @testset "collapseBIOM" begin
        tiny_taxonomy = [
            "k__Bacteria" "k__Bacteria" "k__Bacteria" "k__Bacteria" "k__Bacteria" "k__Bacteria" "k__Bacteria" "k__Bacteria" 
            "p__Proteobacteria" "p__Bacteroidetes" "p__Actinobacteria" "p__Actinobacteria" "p__Proteobacteria" "p__Bacteroidetes" "p__Actinobacteria" "p__Actinobacteria" 
            "c__Betaproteobacteria" "c__[Saprospirae]" "c__MB-A2-108" "c__MB-A2-108" "c__Betaproteobacteria" "c__[Saprospirae]" "c__MB-A2-108" "c__MB-A2-108"  
            "o__MND1" "o__[Saprospirales]" "o__0319-7L14" "o__0319-7L14" "o__MND1" "o__[Saprospirales]" "o__0319-7L14" "o__0319-7L14" 
            "f__" "f__Chitinophagaceae" "f__" "f__" "f__" "f__Chitinophagaceae" "f__" "f__"           
            "g__" "g__" "g__" "g__" "g__" "g__" "g__" "g__" 
            "s__" "s__" "s__" "s__" "s__" "s__" "s__" "s__"
        ]
        tiny_colapsed_taxonomy = [
            "k__Bacteria" "k__Bacteria" "k__Bacteria" "k__Bacteria" "k__Bacteria" "k__Bacteria"  
            "p__Proteobacteria" "p__Bacteroidetes" "p__Actinobacteria" "p__Proteobacteria" "p__Bacteroidetes" "p__Actinobacteria"  
            "c__Betaproteobacteria" "c__[Saprospirae]" "c__MB-A2-108" "c__Betaproteobacteria" "c__[Saprospirae]" "c__MB-A2-108"   
            "o__MND1" "o__[Saprospirales]" "o__0319-7L14" "o__MND1" "o__[Saprospirales]" "o__0319-7L14"  
        ]
        tiny_colapse_unknown_taxonomy = [
            "k__Bacteria" "k__Bacteria" "k__Bacteria" "k__Bacteria" 
            "p__" "p__Bacteroidetes" "p__" "p__Bacteroidetes"  
            "c__" "c__[Saprospirae]" "c__" "c__[Saprospirae]"   
            "o__" "o__[Saprospirales]" "o__" "o__[Saprospirales]"  
            "f__" "f__Chitinophagaceae" "f__" "f__Chitinophagaceae"           
        ]
        tiny_df = DataFrame( 
            data=Array{Float64}([1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0]),
            observation=Array{Int32}([1, 2, 3, 4, 1, 2, 4, 3]), 
            sample=Array{Int32}([1, 1, 1, 1, 2, 2, 2, 2]) )
        tiny_collapsed_df = DataFrame( 
            data=Array{Float64}([1.0, 1.0, 2.0, 1.0, 1.0, 2.0]),
            observation=Array{Int32}([1, 2, 3, 1, 2, 3]), 
            sample=Array{Int32}([1, 1, 1, 2, 2, 2]) )
        tiny_collapse_unknown_df = DataFrame( 
            data=Array{Float64}([3.0, 1.0, 3.0, 1.0]),
            observation=Array{Int32}([1, 2, 1, 2]), 
            sample=Array{Int32}([1, 1, 2, 2]) )
        
        metaless_biom         = tempname("data", cleanup=true)
        fresh_biom            = tempname("data", cleanup=true)
        collapse_biom         = tempname("data", cleanup=true)
        collapse_unknown_biom = tempname("data", cleanup=true)
        writeBIOM(fresh_biom, tiny_df, obs_meta=Dict("taxonomy" => tiny_taxonomy))
        writeBIOM(metaless_biom, tiny_df)
        @test_throws KeyError collapseBIOM(metaless_biom, collapse_biom, "taxonomy", on=4)
        @test_throws BoundsError collapseBIOM(fresh_biom, collapse_biom, "taxonomy", on=8)
        @test_throws ArgumentError collapseBIOM(fresh_biom, fresh_biom, "taxonomy", on=4)
        @test_throws ErrorException collapseBIOM(fresh_biom, collapse_biom, "not-taxonomy", on=4)
        di_fresh = readBIOM(fresh_biom)
        collapseBIOM(fresh_biom, collapse_biom, "taxonomy", on=4)
        @test di_fresh == readBIOM(fresh_biom)
        di_collapse = readBIOM(collapse_biom)
        @test sum(di_fresh["sample"]["matrix"]["data"]) == sum(di_collapse["sample"]["matrix"]["data"])
        @test di_fresh["observation"]["metadata"]["taxonomy"] == tiny_taxonomy

        @test di_collapse["sample"]["metadata"]["taxonomy"] == tiny_colapsed_taxonomy
        @test size(di_collapse["sample"]["metadata"]["taxonomy"]) == size(tiny_colapsed_taxonomy)

    end
end