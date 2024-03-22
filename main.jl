using Dates, LinearAlgebra
using Autotrack
using CSV, DataFrames, Missings
using CairoMakie

function plotit(t1, t2, spl, ar, name)
    ts = range(t1, t2, 100)
    xy = [Point2f(ar .* spl(t)) for t in ts]
    xy .-= xy[1]
    fig = Figure()
    ax = Axis(fig[1,1], aspect=DataAspect())
    lines!(ax, xy)
    # hidedecorations!(ax)
    # hidespines!(ax)
    save("$name.eps", fig)
end

cordlength(xy) = norm(diff([xy[1], xy[end]]))

function curvelength(xy)
    p0 = xy[1]
    s = 0.0
    for p1 in xy[2:end]
        s += norm(p1 - p0)
        p0 = p1
    end
    return s
end

function tortuosity(t1, t2, spl, ar)
    ts = range(t1, t2, 100)
    xy = [Point2f(ar .* spl(t)) for t in ts]
    cordlength(xy) / curvelength(xy)
end

get_track(file, start, stop, starting_point, name) = track(file, start, stop; csv_file=name, debug_file=name, starting_point, temporal_step=0.5)

function parse_point(str)
    m = match(r"\((\d+),(\d+)\)", filter(!isspace, str))
    tuple(parse.(Int, m.captures)...)
end

tosecond(t::T) where {T} = t / convert(T, Dates.Second(1))

df = CSV.read("runs.csv", DataFrame)
df.name .= string.(rownumber.(eachrow(df)))
transform!(df, [:start, :stop] .=> ByRow(x -> tosecond(x - Time(0))), :starting_point => ByRow(passmissing(parse_point)); renamecols=false)
transform!(df, [:file, :start, :stop, :starting_point, :name] => ByRow(get_track) => :track)
transform!(df, :track => ByRow(splat(tortuosity)) => :tortuosity)

for row in eachrow(df)
    t1, t2, spl, ar = row.track
    plotit(t1, t2, spl, ar, row.name)
end

