using BIOMUtils
using DataFrames
using Test

@testset "BIOMUtils.jl" begin
    ID   = 990
    ROOT = "/home/jonas/Repos/Thesis/data/"
    path = "$(ROOT)$(ID)/processed_data/99_otu_table.biom"

    @testset "readCooccurrence" begin
        df = readCooccurrence(path, "sample") 
        @test df isa DataFrame
        @test df.data isa Array{Float64}
        @test df.observation isa Array{Int}
        @test df.sample isa Array{Int}
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
end
