include("main.jl")

Base.(:+)(x :: Tuple{Int64,Float64,Bool}, y :: Tuple{Int64,Float64,Bool}) = (x[1] + y[1], x[2] + y[2], x[3] + y[3])
Base.(:+)(x :: Tuple{Int64,Float64,Int64}, y :: Tuple{Int64,Float64,Bool}) = (x[1] + y[1], x[2] + y[2], x[3] + y[3])

function tester()
    out = open("data.log", "w")
    cd("../instances")
    files = readdir()
    for file in files
        name = split(splitext(file)[1], '-')[1]
        if name == "uf20"
            println("$file \t")

            todo  = [file for i in 1:10]
            inf   = (pmap(x -> main(x), todo))
            info  = sum(inf)
            info2 = (info[1]/10, info[2]/10, info[3])

            println(info)
            write(out, "$file $inf $info2\n")
            flush(out)
        end
    end
    cd("../src")
    close(out)
end
