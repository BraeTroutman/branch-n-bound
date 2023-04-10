using JuMP
using HiGHS

function knapsack(W, w, v)
	model = Model(HiGHS.Optimizer)
    set_silent(model)
	n = length(w)

	@variable(model, items[1:n], Bin)
	@objective(model, Max, sum(v[i]*items[i] for i in 1:n))
	@constraint(model, sum(w[i]*items[i] for i in 1:n) <= W)

	optimize!(model)
	return JuMP.value.(items)
end

getitems(items) = findall(x -> x > 0.5, items)

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

    return (W, w, v)
end

W, w, v = readwv(ARGS[1])
@time items = knapsack(W,w,v)
print(getitems(items))

