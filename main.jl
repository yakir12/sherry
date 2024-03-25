using SimpTrack

using Dates
using CSV, DataFrames, Dierckx, VideoIO
using CairoMakie

tosecond(t::T) where {T} = t / convert(T, Dates.Second(1))

function plotit(name, track)
    fig = Figure();
    ax = Axis(fig[1,1], aspect=DataAspect())
    t, xy = track
    # scatter!(ax, xy, color=(:gray, 0.3))
    XY = reshape(collect(Iterators.flatten(xy)), 2, :)
    spl = ParametricSpline(t, XY; s = 1000, k = 2)
    ts = range(t[1], t[end], length(t))
    xy2 = Point2f.(spl.(ts))
    xy2 .-= xy2[1]
    lines!(ax, xy2)
    lines!(ax, Circle(zero(Point2f), 350), color=:black)
    save("$name.pdf", fig)
end

function plotthem(names, tracks)
    fig = Figure();
    ax = Axis(fig[1,1], aspect=DataAspect())
    for (name, track) in zip(names, tracks)
        t, xy = track
        # scatter!(ax, xy, color=(:gray, 0.3))
        XY = reshape(collect(Iterators.flatten(xy)), 2, :)
        spl = ParametricSpline(t, XY; s = 1000, k = 2)
        ts = range(t[1], t[end], length(t))
        xy2 = Point2f.(spl.(ts))
        xy2 .-= xy2[1]
        lines!(ax, xy2, label=name)
    end
    lines!(ax, Circle(zero(Point2f), 350), color=:black)
    axislegend(ax)
    save("all.pdf", fig)
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
    seek(vid, t[1])
    framerate = round(Int, 2length(t)/(t[end] - t[1]))
    record(fig, "$name.mp4", zip(xy, vid); framerate) do (xy, frame)
        img[] = rotr90(frame)
        y, x = xy
        point[] = Point2f(x, sz[2] - y)
    end
end

video_folder = "/home/yakir/new_projects/sherry/Exempel/20231128_B1_intact"

runs_file = joinpath(video_folder, "Yakirs program/runs.csv")
df = CSV.read(runs_file, DataFrame)
df.name .= string.(rownumber.(eachrow(df)))
transform!(df, [:start, :stop] .=> ByRow(x -> tosecond(x - Time(0))), :file => ByRow(x -> joinpath(video_folder, x)); renamecols=false)
transform!(df, [:file, :start, :stop] => ByRow(track) => :track)
select(df, [:name, :file, :track] => ByRow(save_vid))
select(df, [:name, :track] => ByRow(plotit))
select(df, [:name, :track] => plotthem)

