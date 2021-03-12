using BIOMUtils
using DataFrames
using HDF5
using Test

@testset "Utils.jl" begin
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

end
