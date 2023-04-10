using JuMP
using HiGHS

function knapsack(W, w, v)
	model = Model(HiGHS.Optimizer)
	n = length(w)

	@variable(model, items[1:n], Bin)
	@objective(model, Max, sum(v[i]*items[i] for i in 1:n))
	@constraint(model, sum(w[i]*items[i] for i in 1:n) <= W)

	optimize!(model)
	return JuMP.value.(items)
end

lines = open(readlines, ARGS[1])
W = parse(Int64, match(r"\d+", lines[1]).match)
N = parse(Int64, match(r"\d+", lines[2]).match)

w = fill(0, N)
v = fill(0, N)

for (i,line) in enumerate(lines[3:end])
	matches = collect(eachmatch(r"\d+", line))
	w[i] = parse(Int64, matches[1].match)
	v[i] = parse(Int64, matches[2].match)
end

println(knapsack(W,w,v))

