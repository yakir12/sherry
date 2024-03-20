using Dates
using Autotrack
using CSV, DataFrames

tosecond(t::T) where {T} = t / convert(T, Dates.Second(1))

df = CSV.read("runs.csv", DataFrame)
transform!(df, [:start, :stop] .=> ByRow(x -> tosecond(x - Time(0))); renamecols=false)

for (i, row) in enumerate(eachrow(df))
    name = string(i)
    track(row.file, row.start, row.stop; csv_file=name, debug_file=name, temporal_step=0.5)
end
