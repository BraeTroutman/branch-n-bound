module kp
export ilpknapsack, dncknapsack, readwv

using JuMP
using HiGHS

function ilpknapsack(W, w, v)
	model = Model(HiGHS.Optimizer)
    set_silent(model)
	n = length(w)

	@variable(model, items[1:n], Bin)
	@objective(model, Max, sum(v[i]*items[i] for i in 1:n))
	@constraint(model, sum(w[i]*items[i] for i in 1:n) <= W)

	optimize!(model)
    return findall(x -> x > 0.5, JuMP.value.(items))
end

getitems(items) = findall(x -> x > 0.5, items)

function solve(W::Int64, w::Vector{Int64}, v::Vector{Int64})
    Rows = fill(0, (2, W+1))

    for i = 1:length(v)
        for c = 0:W
            if c == 0
                Rows[2,c+1] = 0
            elseif w[i] <= c
                Rows[2,c+1] = max(Rows[1,(c+1) - w[i]] + v[i], Rows[1,c+1])
            else
                Rows[2,c+1] = Rows[1,c+1]
            end
        end
        Rows[1,:] = copy(Rows[2,:])
    end

    return Rows[2,:]
end

function dncknapsack(W::Int64, i, w::Vector{Int64}, v::Vector{Int64})
    N = length(i)
    if N == 1
        if w[1] <= W
            return [i[1]]
        else
            return []
        end
    end

	il = i[1:div(end,2)]
	ir = i[div(end,2)+1:end]
	wl = w[1:div(end,2)]
	wr = w[div(end,2)+1:end]
	vl = v[1:div(end,2)]
	vr = v[div(end,2)+1:end]

	x1 = solve(W, wl, vl) # O(nW)
	x2 = solve(W, wr, vr) # O(nW)

    k = argmax(map(+, x1, reverse(x2))) - 1

	left  = dncknapsack(k, il, wl, vl)
    right = dncknapsack(W-k, ir, wr, vr)

    return [left ; right]
end

function readwv(filename)
	lines = open(readlines, filename)
	W = parse(Int64, match(r"\d+", lines[1]).match)
	N = parse(Int64, match(r"\d+", lines[2]).match)
	
	w = fill(0, N)
	v = fill(0, N)
	
	for (i,line) in enumerate(lines[3:end])
		matches = collect(eachmatch(r"\d+", line))
		w[i] = parse(Int64, matches[1].match)
		v[i] = parse(Int64, matches[2].match)
	end

    return (W, N, w, v)
end

precompile(readwv, (String,))
precompile(dncknapsack, (Int64, UnitRange{Int64}, Vector{Int64}, Vector{Int64}))
precompile(ilpknapsack, (Int64, Vector{Int64}, Vector{Int64}))

end
