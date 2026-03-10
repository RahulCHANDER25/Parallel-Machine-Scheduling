include "globals.mzn";

int: n;
int: m;
int: horizon;
array[1..n] of set of 0..m-1: capable;
array[1..n] of array[1..m] of int: duration;
array[1..n] of array[1..m] of int: release;
array[1..n] of array[1..n] of array[1..m] of int: setup;

array[1..n,0..m-1] of int: duration_fix = array2d(1..n, 0..m-1, [
    duration[i][j+1] | i in 1..n, j in 0..m-1
]);

array[1..n,0..m-1] of int: release_fix = array2d(1..n, 0..m-1, [
    release[i][j+1] | i in 1..n, j in 0..m-1
]);

array[1..n,1..n,0..m-1] of int: setup_fix = array3d(1..n, 1..n, 0..m-1, [
    setup[i][k][j+1] | i in 1..n, k in 1..n, j in 0..m-1
]);

array[0..m-1, 1..n] of var 0..n: schedule;

constraint unique_accross_arrays_unless_0(schedule);

predicate unique_accross_arrays_unless_0(array[0..m-1, 1..n] of var 0..n: jobs_arrays) =
    forall(v in 1..n) (
        sum(i in 0..m-1, j in 1..n) (
            bool2int(jobs_arrays[i,j] == v)
        ) <= 1
    );

% Get which job each machine is capable of processing
array[0..m-1] of set of 1..n: capable_jobs = array1d(0..m-1, [ { j | j in 1..n where (i - 1) in capable[j] } | i in 1..m ]);

% Assign one machine per job
constraint forall (i in 1..n) (
    exists (k in 0..m-1) (
        exists(pos in 1..n) (schedule[k,pos] == i)
        /\ i in capable_jobs[k]
    )
);

function var int: machine_time(int: k) =
    sum(p in 1..n) (
        if schedule[k, p] > 0 then duration_fix[schedule[k, p], k] else 0 endif
    ) + sum(p1 in 1..n, p2 in 1..n where p1 < p2) (
        if schedule[k,p1] > 0 /\ schedule[k,p2] > 0
        then setup_fix[schedule[k,p1], schedule[k,p2], k] else 0 endif
    );

var int: makespan = max(k in 0..m-1) (machine_time(k));
constraint makespan <= horizon;

solve minimize makespan;

output[
    "makespan: \(makespan)\n",
    "capable_jobs: \(capable_jobs)\n",
    "capable: \(capable)\n",
    "schedule: {\n",
    concat(
        ["  \(i): \([schedule[i,k] | k in 1..n where schedule[i,k] != 0]),\n" | i in 0..m-1]
    ),
    "}\n"
];
