using BIOMUtils
using DataFrames
using HDF5
using StatsBase
using Test

function generate_testdata(dir::String; overwrite=false)
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
        file = tempname("data", cleanup=true)
        tinydf = DataFrame( data=Array{Float64}([1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0]),
                            observation=Array{Int32}([1, 2, 3, 4, 1, 2, 4, 3, 4]), 
                            sample=Array{Int32}([1, 1, 1, 1, 2, 2, 2, 3, 3]) )
        writeBIOM(file, tinydf)
        @test isfile(file)
        @test HDF5.ishdf5(file)
        di = h5open(file) do h5 
            read(h5)
        end
        @test di isa Dict{String, Any}
        @test ["sample", "observation"] ⊆ keys(di)
        @test isBIOM(file)
    end

end
