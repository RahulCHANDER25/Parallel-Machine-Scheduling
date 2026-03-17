include "globals.mzn";

% inputs
int: n;
int: m;
int: horizon;
array[1..n] of set of 0..m-1: capable;
array[1..n,0..m-1] of 0..horizon: duration;
array[1..n,0..m-1] of 0..horizon: release;
array[1..n,1..n,0..m-1] of 0..horizon: setup;

array[1..n] of var 0..m-1: assigned_m;
array[1..n] of var 0..horizon: start_time;
array[1..n] of var 0..horizon: finish_time;
var int: makespan = max(finish_time);

% assign for each job one machine where its start time will be after its release time and calculate its finish time without setup.
% Also to help the search find better result, the makespan is strictly bigger than the finish time. It puts a hard constraint to be respected.
constraint forall(i in 1..n) (
    assigned_m[i] in capable[i] /\
    start_time[i] >= release[i, assigned_m[i]] /\
    finish_time[i] = start_time[i] + duration[i, assigned_m[i]] /\
    makespan >= finish_time[i]
);

% for each machine, the jobs assigned to it must not overlap. We use the disjunctive global constraint for that.
constraint forall(m_idx in 0..m-1) (
    let {
        array[int] of int: c = [i | i in 1..n where m_idx in capable[i]],
        array[int] of var opt 0..horizon: s_list = [s_opt[i, m_idx] | i in c],
        array[int] of int: d_list = [duration[i, m_idx] | i in c]
    } in
    disjunctive(s_list, d_list)
);

% Define the optional start times for each job and machine.
% s_opt[i, m_idx] is defined if and only if assigned_m[i] == m_idx, and in that case s_opt[i, m_idx] is equal to start_time[i].
% This allows us to use the disjunctive constraint on s_opt while ensuring that it correctly reflects the start times of the jobs on their assigned machines.
array[1..n, 0..m-1] of var opt 0..horizon: s_opt;
constraint forall(i in 1..n, m_idx in 0..m-1) (
    occurs(s_opt[i, m_idx]) <-> (assigned_m[i] == m_idx) /\
    (occurs(s_opt[i, m_idx]) -> s_opt[i, m_idx] == start_time[i])
);

% Ensure that jobs on the same machine do not overlap with their setup times.
constraint forall(i, j in 1..n where i < j) (
    (assigned_m[i] == assigned_m[j]) -> (
        (start_time[j] >= finish_time[i] + setup[i, j, assigned_m[i]]) \/
        (start_time[i] >= finish_time[j] + setup[j, i, assigned_m[i]])
    )
);

% Constraint to lower bound the makespan and help the search find better solutions faster.
% It ensures that the makespan is at least the sum of the durations of the jobs assigned to each machine.
constraint forall(m_idx in 0..m-1) (
    makespan >= sum(i in 1..n) (bool2int(assigned_m[i] == m_idx) * duration[i, m_idx])
);

% Search strategy: we first try to assign machines to jobs using a first-fail strategy, and then we assign start times using a smallest domain strategy. We also use a restart strategy to escape from local minima.
% See https://docs.minizinc.dev/en/latest/lib-stdlib-annotations.html#search-annotations for more info on the search annotations used here.
solve :: seq_search([
    int_search(assigned_m, first_fail, indomain_split),
    int_search(start_time, smallest, indomain_min)
]) :: restart_luby(100)
   minimize makespan;

% displaying
array[0..m-1] of var set of 1..n: schedule;
% the int set channel create achannel such that assigned_m[i] = j and schedule[j] <-> i in schedule[j]
% see https://docs.minizinc.dev/en/latest/lib-globals-channeling.html#int-set-channel for more info
constraint int_set_channel(assigned_m, schedule);

output [
    "{\n  \"makespan\": \(makespan),\n  \"schedule\": {\n",
    join(",\n", [
        "    \"\(i)\": [" ++
            join(", ", [show(v) | v in sort_by(fix(schedule[i]), [fix(start_time[k]) | k in fix(schedule[i])])])
        ++ "]"
        | i in 0..m-1
    ]),
    "\n  }\n}"
];