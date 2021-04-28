using BIOMUtils: BIOM
using HDF5
using Test
using SparseArrays

@testset "io" begin

end

@testset "parse" begin
    @testset "func" begin
        @test 1 + 1 == 2
    end    
end

@testset "process" begin
    @testset "func" begin
        @test 1 + 1 == 2
    end    
end

@testset "types" begin
    @testset "BIOM" begin
        data = [
            1 1 0 0 
            0 1 1 0
            0 0 1 1 
        ]
        sampleIds = ["S1", "S2", "S3"]
        otuIds = ["otu1", "otu2", "otu3", "otu4"] 
        taxonomy = [
            "k__Bacteria"            "k__Bacteria"           "k__Bacteria"           "k__Bacteria"
            "p__Proteobacteria"      "p__Proteobacteria"     "p__Proteobacteria"     "p__Proteobacteria"
            "c__Alphaproteobacteria" "c__Betaproteobacteria" "c__Betaproteobacteria" "c__Gammaproteobacteria"
            "o__MND"                 "o__MND1"               "o__MND2"               "o__"
            "f__mnd"                 "f__mnd"                "f__"                   "f__"
            "g__mnd"                 "g__"                   "g__"                   "g__"
            "s__"                    "s__"                   "s__"                   "s__"
        ]
        #= Test Types =#
        @test BIOM(data) isa BIOM
        @test BIOM(data).data isa SparseMatrixCSC
        @test BIOM(data).sample isa NamedTuple
        @test BIOM(data).observation isa NamedTuple
        @test BIOM(data).sample.ids isa Array
        @test BIOM(data).sample.metadata isa Dict
        @test BIOM(data).sample.groupmetadata isa Dict
        @test BIOM(data).observation.ids isa Array
        @test BIOM(data).observation.metadata isa Dict
        @test BIOM(data).observation.groupmetadata isa Dict


        @test BIOM(data).sample == BIOM(sparse(data)).sample

    end    
end

@testset "utils" begin
    @testset "func" begin
        @test 1 + 1 == 2
    end    
end