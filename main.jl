using SimpTrack
using Dates, LinearAlgebra
using CSV, DataFrames, Dierckx, VideoIO
using CairoMakie

tosecond(t::T) where {T} = t / convert(T, Dates.Second(1))

function get_spline(track)
    t, xy = track
    XY = reshape(collect(Iterators.flatten(xy)), 2, :)
    ParametricSpline(t, XY; s = 1000, k = 2)
end

function plotit(name, start, stop, spline)
    fig = Figure();
    ax = Axis(fig[1,1], aspect=DataAspect())
    ts = range(start, stop, 100)
    xy = Point2f.(spline.(ts))
    xy .-= xy[1]
    lines!(ax, xy)
    lines!(ax, Circle(zero(Point2f), 350), color=:black)
    save("$name.pdf", fig)
end

function plotthem(names, starts, stops, splines)
    fig = Figure();
    ax = Axis(fig[1,1], aspect=DataAspect())
    for (name, start, stop, spline) in zip(names, starts, stops, splines)
        ts = range(start, stop, 100)
        xy = Point2f.(spline.(ts))
        xy .-= xy[1]
        lines!(ax, xy, label=name)
    end
    lines!(ax, Circle(zero(Point2f), 350), color=:black)
    axislegend(ax)
    save("all.pdf", fig)
end

function save_csv(name, track)
    t, xy = track
    df = DataFrame(second = t, x = first.(xy), y = last.(xy))
    CSV.write("$name.csv", df)
end

function save_vid(name, file, track)
    t, xy = track
    vid = openvideo(file)
    sz = out_frame_size(vid)
    h = 200
    fig = Figure(size=(h, h*sz[2] ÷ sz[1]), figure_padding=0)
    ax = Axis(fig[1,1], aspect=DataAspect())
    img = Observable(rotr90(read(vid)))
    image!(ax, img)
    y, x = xy[1]
    point = Observable(Point2f(x, sz[2] - y))
    scatter!(ax, point, marker='+', color=:red)
    hidespines!(ax)
    hidedecorations!(ax)
    t₀ = gettime(vid)
    t .+= t₀
    seek(vid, t[1])
    framerate = round(Int, 2length(t)/(t[end] - t[1]))
    record(fig, "$name.mp4", zip(xy, vid); framerate) do (xy, frame)
        img[] = rotr90(frame)
        y, x = xy
        point[] = Point2f(x, sz[2] - y)
    end
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

function tortuosity(t1, t2, spl)
    xy = Point2f.(spl.(range(t1, t2, 1000)))
    cordlength(xy) / curvelength(xy)
end

video_folder = "/home/yakir/B10"

runs_file = joinpath(video_folder, "runs.csv")
df = CSV.read(runs_file, DataFrame)
df.name .= string.(rownumber.(eachrow(df)))
transform!(df, [:start, :stop] .=> ByRow(x -> tosecond(x - Time(0))), :file => ByRow(x -> joinpath(video_folder, x)); renamecols=false)
transform!(df, [:file, :start, :stop] => ByRow(track) => :track)
transform!(df, :track => ByRow(get_spline) => :spline)
transform!(df, [:start, :stop, :spline] => ByRow(tortuosity) => :tortuosity)
select(df, [:name, :track] => ByRow(save_csv))
select(df, [:name, :file, :track] => ByRow(save_vid))
select(df, [:name, :start, :stop, :spline] => ByRow(plotit))
select(df, [:name, :start, :stop, :spline] => plotthem)

