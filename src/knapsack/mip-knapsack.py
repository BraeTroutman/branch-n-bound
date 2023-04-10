import sys
import re
import numpy as np
import gurobipy as grb

filename = sys.argv[1]

f = open(filename, "r")
lines = f.read().split("\n")[:-1]
f.close()

W = int(re.search(r"\d+", lines[0]).group(0))

wtsvals = [list(map(int,re.findall(r"\d+", line))) for line in lines[2:]]
w = np.zeros(len(wtsvals))
v = np.zeros(len(wtsvals))
for i, (wt, vl) in enumerate(wtsvals):
    w[i] = wt
    v[i] = vl

def knapsack(W, w, v):
    n = len(w)
    model = grb.Model()
    item = model.addVars(n, vtype=grb.GRB.BINARY)
    model.setObjective(grb.quicksum(v[i]*item[i] for i in range(n)), grb.GRB.MAXIMIZE)
    model.addConstr(grb.quicksum(w[i]*item[i] for i in range(n)) <= W)

    model.optimize()

    return [i+1 for i in range(n) if item[i].X > 0.5]

print(knapsack(W, w, v))

