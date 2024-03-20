using Dates
using Autotrack
using CSV, DataFrames
using CairoMakie

function plotit(t1, t2, spl, ar, name)
    ts = range(t1, t2, 100)
    xy = [Point2f(ar .* spl(t)) for t in ts]
    fig = Figure()
    ax = Axis(fig[1,1], aspect=DataAspect())
    lines!(ax, xy)
    hidedecorations!(ax)
    hidespines!(ax)
    save("$name.eps", fig)
end

tosecond(t::T) where {T} = t / convert(T, Dates.Second(1))

df = CSV.read("runs.csv", DataFrame)
transform!(df, [:start, :stop] .=> ByRow(x -> tosecond(x - Time(0))); renamecols=false)

for (i, row) in enumerate(eachrow(df))
    name = string(i)
    t1, t2, spl, ar = track(row.file, row.start, row.stop; csv_file=name, debug_file=name, temporal_step=0.5)
    plotit(t1, t2, spl, ar, name)
end
