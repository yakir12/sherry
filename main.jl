using Dates, LinearAlgebra
using Autotrack
using CSV, DataFrames, Missings
using CairoMakie

function plotit(t1, t2, spl, ar, name)
    ts = range(t1, t2, 100)
    xy = [Point2f(ar .* spl(t)) for t in ts]
    fig = Figure()
    ax = Axis(fig[1,1], aspect=DataAspect(),limits=((0,1920),(0,1080)))
    lines!(ax, xy)
    # hidedecorations!(ax)
    # hidespines!(ax)
    save("$name.eps", fig)
end

function plotthem(tracks)
    fig = Figure()
    ax = Axis(fig[1,1], aspect=DataAspect())
    for (t1, t2, spl, ar) in tracks
        ts = range(t1, t2, 100)
        xy = [Point2f(ar .* spl(t)) for t in ts]
        xy .-= xy[1]
        lines!(ax, xy)
    end
    lines!(ax, Circle(zero(Point2f), 500), color=:black)
    # hidedecorations!(ax)
    # hidespines!(ax)
    save("all.eps", fig)
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

get_track(file, start, stop, starting_point, name) = track(file, start, stop; csv_file=name, debug_file=name, starting_point, temporal_step=0.5, smoothing_factor=50)

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

plotthem(df.track)
