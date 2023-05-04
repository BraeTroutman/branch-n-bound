module Knapsack

using JuMP
using HiGHS

"""merge two linked lists iteratively into one"""
function merge(left, right)
	out = fill((0,0), length(left) + length(right))

    l = 1
    r = 1

	for i in 1:length(out)
        if l > length(left)
			out[i:end] = right[r:end]
            break
		end
        if r > length(right)
			out[i:end] = left[l:end]
            break
		end
        if left[l] < right[r]
            out[i] = left[l]
            l += 1
        else
            out[i] = right[r]
            r += 1
		end
	end
    
	return out
end

addtuple((x,y), (a,b)) = (x+a,y+b)
showrow(row) = join(["<$(w),$(v)>" for (w,v) in row], " ")

"""add a vector of tuples pairwise to another"""
function add(row, w, v)
	[addtuple(tp, (w,v)) for tp ∈ row]
end

"""delete tuples from an ordered vector that are not strictly increasing in their second entry"""
function kill(row, W)
	(wp, vp) = row[1]
	out = [(wp, vp)]

	for (w, v) in row[2:end]
		if w <= W && v >= vp
			push!(out, (w,v))
			wp, vp = w, v
		end
	end

	return out
end

"""add-merge-kill algorithm to find optimal knapsack value given weights, values, and capacity"""
function amk(W, w, v)
	row = [(0,0)]
	i::Int32 = 0	
	W <= 20 && println("$(i): ", showrow(row))

	for i in 1:length(w)
		next = add(row, w[i], v[i])
		row = merge(row, next)
		row = kill(row, W)
		W <= 20 && println("$(i): ", showrow(row))
	end

	return row
end


"""solve the 0/1 knapsack problem as a (binary) integer linear program"""
function ilp(W, w, v)
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

"""space efficient dynamic programming to calculate optimal value for 0/1 knapsack"""
function dp(W::Int64, w::AbstractVector{Int64}, v::AbstractVector{Int64})
    Rows = zeros(2, W+1)

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
        Rows[1,:] .= @view Rows[2,:]
    end

    return @view Rows[2,:]
end

function dnc(W::Int64, w::AbstractVector{Int64}, v::AbstractVector{Int64})
    N = length(w)
    return dnc(W, 1:N, w, v)
end


"""space efficient divide-and-conquer utilizing dp-knapsack to calculate optimal value and subset of items to choose"""
function dnc(W::Int64, i, w::AbstractVector{Int64}, v::AbstractVector{Int64})
    N = length(i)
    if N == 1
        if w[1] <= W
            return [i[1]]
        else
            return []
        end
    end

    il = @view i[1:div(end,2)]
	ir = @view i[div(end,2)+1:end]
	wl = @view w[1:div(end,2)]
	wr = @view w[div(end,2)+1:end]
	vl = @view v[1:div(end,2)]
	vr = @view v[div(end,2)+1:end]

	x1 = dp(W, wl, vl) # O(nW)
	x2 = dp(W, wr, vr) # O(nW)

    k = argmax(map(+, x1, reverse(x2))) - 1

	left  = dnc(k, il, wl, vl)
    right = dnc(W-k, ir, wr, vr)

    return [left ; right]
end

"""read capacity, num items, weights, values from file"""
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


end # module Knapsack
