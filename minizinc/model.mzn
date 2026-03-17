include "globals.mzn";

int: n;
int: m;
int: horizon;
array[1..n] of set of 0..m-1: capable;
array[1..n,0..m-1] of 0..horizon: duration;
array[1..n,0..m-1] of 0..horizon: release;
array[1..n,1..n,0..m-1] of 0..horizon: setup;

array[1..n] of var 0..m-1: assigned_m;
array[1..n] of var 0..horizon: s;
array[1..n] of var 0..horizon: f;
var int: makespan = max(f);

constraint forall(i in 1..n) (
    assigned_m[i] in capable[i] /\
    s[i] >= release[i, assigned_m[i]] /\
    f[i] = s[i] + duration[i, assigned_m[i]] /\
    makespan >= f[i]
);

constraint forall(m_idx in 0..m-1) (
    let {
        array[int] of int: c = [i | i in 1..n where m_idx in capable[i]],
        array[int] of var opt 0..horizon: s_list = [s_opt[i, m_idx] | i in c],
        array[int] of int: d_list = [duration[i, m_idx] | i in c]
    } in
    disjunctive(s_list, d_list)
);

array[1..n, 0..m-1] of var opt 0..horizon: s_opt;
constraint forall(i in 1..n, m_idx in 0..m-1) (
    occurs(s_opt[i, m_idx]) <-> (assigned_m[i] == m_idx) /\
    (occurs(s_opt[i, m_idx]) -> s_opt[i, m_idx] == s[i])
);

constraint forall(i, j in 1..n where i < j) (
    (assigned_m[i] == assigned_m[j]) -> (
        (s[j] >= f[i] + setup[i, j, assigned_m[i]]) \/
        (s[i] >= f[j] + setup[j, i, assigned_m[i]])
    )
);

constraint forall(m_idx in 0..m-1) (
    makespan >= sum(i in 1..n) (bool2int(assigned_m[i] == m_idx) * duration[i, m_idx])
);

solve :: seq_search([
    int_search(assigned_m, first_fail, indomain_random),
    int_search(s, smallest, indomain_min)
]) :: restart_luby(100)
   minimize makespan;

array[0..m-1] of var set of 1..n: schedule;
constraint int_set_channel(assigned_m, schedule);

output [
    "{\n  \"makespan\": \(makespan),\n  \"schedule\": {\n",
    join(",\n", [
        "    \"\(i)\": [" ++
            join(", ", [show(v) | v in sort_by(fix(schedule[i]), [fix(s[k]) | k in fix(schedule[i])])])
        ++ "]"
        | i in 0..m-1
    ]),
    "\n  }\n}"
];