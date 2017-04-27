using Distributions

include("types.jl")
include("selection.jl")
include("crossover.jl")

function spawn_empty_population()
    new_pop = _population(0, 0, 0, 0,
                         [],
                         0, 0, 0, 0,
                         _ -> _, _ -> _, _ -> _, _ -> _, _ -> _)
end

function init_population( pop :: _population )
    for i in 1:pop.size
        for j in 1:pop.n_genes
            if pop.individuals[i].genetic_code[j].gen_type == bool
                pop.individuals[i].genetic_code[j].value = rand(Bool)
            elseif pop.individuals[i].genetic_code[j].gen_type == int
                pop.individuals[i].genetic_code[j].value = rand(pop.individuals[i].genetic_code[j].lb:pop.individuals[i].genetic_code[j].ub)
            elseif pop.individuals[i].genetic_code[j].gen_type == real
                pop.individuals[i].genetic_code[j].value = rand() * (pop.individuals[i].genetic_code[j].ub - pop.individuals[i].genetic_code[j].lb) + pop.individuals[i].genetic_code[j].lb
            elseif pop.individuals[i].genetic_code[j].gen_type == permut
                #=throw("Not implemented")=#
                pop.individuals[i].genetic_code[j].value = j
            end
        end

        if pop.individuals[i].genetic_code[1].gen_type == permut
            shuffle!(pop.individuals[i].genetic_code)
        end
    end
end

function evaluate( pop :: _population )
    for i in 1:pop.size
        pop.objective_function(pop.individuals[i])

        pop.min_objf = min(pop.min_objf, pop.individuals[i].obj_f)
        pop.max_objf = max(pop.max_objf, pop.individuals[i].obj_f)
    end

    for i in 1:pop.size
        pop.fitness_function( pop, pop.individuals[i] )
    end
end

function clone( guy :: _individual )
    genetic_code = Array{_gene}( guy.n_genes )

    for i in 1:guy.n_genes
        genetic_code[i] = _gene(guy.genetic_code[i].gen_type,
                                guy.genetic_code[i].lb,
                                guy.genetic_code[i].ub,
                                guy.genetic_code[i].value)
    end

    new_guy = _individual(guy.n_genes, guy.fitness, guy.obj_f, genetic_code)

    return new_guy
end

function selection( pop :: _population )
    pop.individuals = pop.selection_function( pop )
end

function crossover( pop :: _population )
    new_guys = []
    for i in 1:pop.size
        p1 = rand(1:pop.size)
        p2 = rand(1:pop.size)

        while p1 == p2
            p1 = rand(1:pop.size)
            p2 = rand(1:pop.size)
        end

        if rand() < pop.cchance
            u, v = pop.crossover_function(pop, p1, p2)

            push!(new_guys, u)
            push!(new_guys, v)
        else
            u, v = clone(pop.individuals[p1]), clone(pop.individuals[p2])

            push!(new_guys, u)
            push!(new_guys, v)
        end
    end

    pop.individuals = new_guys
end

function mutation( pop :: _population )
    d = Normal()

    for i in 1:pop.size
        for j in 1:pop.n_genes
            if rand() < pop.mchance
                if pop.individuals[i].genetic_code[j].gen_type == bool

                    pop.individuals[i].genetic_code[j].value = !pop.individuals[i].genetic_code[j].value

                elseif pop.individuals[i].genetic_code[j].gen_type == int

                    #=dist = Int(ceil((pop.individuals[i].genetic_code[j].ub - pop.individuals[i].genetic_code[j].lb) * 0.01))=#
                    #=pop.individuals[i].genetic_code[j].value += rand(-dist:dist)=#

                    dist = Int(ceil(((pop.individuals[i].genetic_code[j].ub - pop.individuals[i].genetic_code[j].lb) * 0.1)))
                    pop.individuals[i].genetic_code[j].value += Int(ceil(rand(d))) * (dist * 2.0) - dist

                elseif pop.individuals[i].genetic_code[j].gen_type == real

                    dist = (pop.individuals[i].genetic_code[j].ub - pop.individuals[i].genetic_code[j].lb) * 0.01
                    pop.individuals[i].genetic_code[j].value += (rand() * 2.0 - 1.0) * dist

                    #=dist = (pop.individuals[i].genetic_code[j].ub - pop.individuals[i].genetic_code[j].lb) * 0.01=#
                    #=pop.individuals[i].genetic_code[j].value += (rand(d) * 2.0 - 1.0) * dist=#

                elseif pop.individuals[i].genetic_code[j].gen_type == permut
                    a = rand(1:pop.n_genes)

                    t = pop.individuals[i].genetic_code[j].value
                    pop.individuals[i].genetic_code[j].value = pop.individuals[i].genetic_code[a].value
                    pop.individuals[i].genetic_code[a].value = t
                end

            end

            if !(pop.individuals[i].genetic_code[j].gen_type == permut)
                if pop.individuals[i].genetic_code[j].value < pop.individuals[i].genetic_code[j].lb
                    pop.individuals[i].genetic_code[j].value = pop.individuals[i].genetic_code[j].lb
                end

                if pop.individuals[i].genetic_code[j].value > pop.individuals[i].genetic_code[j].ub
                    pop.individuals[i].genetic_code[j].value = pop.individuals[i].genetic_code[j].ub
                end
            end
        end
    end
end

function elitism_get( pop :: _population )
    s = sort( pop.individuals, rev=true )[1:pop.kelitism]
    x = []

    for i in s
        push!(x, clone(i))
    end

    return x
end

function elitism_put_back( pop :: _population, elite )
    if pop.kelitism == 0
        return
    end

    new_guys = []

    for i in elite
        push!(new_guys, i)
    end

    for i in pop.individuals[pop.kelitism:pop.size]
        push!(new_guys, i)
    end

    pop.individuals = new_guys
end

distance(a :: _individual, b :: _individual) = mapfoldr((x) -> (x[1].value - x[2].value) ^ 2 , +, collect(zip(a.genetic_code, b.genetic_code)))

function get_diversity( pop :: _population )
    d, t = 0, 0
    for i in 2:pop.size, j in 1:i-1
        d += distance(pop.individuals[i], pop.individuals[j])
        t += 1
    end

    return d / t
end

function print_pop( pop :: _population )
    for i in 1:pop.size
        for j in 1:pop.n_genes
            print("$(pop.individuals[i].genetic_code[j].value) ")
        end
        println(" = $(pop.individuals[i].fitness) $(pop.individuals[i].obj_f)")
    end
end

function print_status( pop :: _population )
    best_i = 1

    acc = 0.0

    for i in 1:pop.size
        acc += pop.individuals[i].fitness
        if pop.individuals[i].fitness > pop.individuals[best_i].fitness
            best_i = i
        end
    end

    @printf("%4.8f %4.8f %4.8f \n", pop.individuals[best_i].fitness, acc/pop.size, get_diversity(pop))
end
