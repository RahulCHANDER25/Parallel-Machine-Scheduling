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

var int: makespan = sum(i in 0..m-1) (sum (j in schedule[i]) (release_fix[j,i] +duration_fix[j, i]));
array[0..m-1] of var set of 1..n: schedule;
constraint unique_accross_sets_unless_empty(schedule);
constraint makespan <= horizon;

predicate unique_accross_sets_unless_empty(array[int] of var set of int: sets) =
    forall(i, j in index_set(sets) where i != j) (
       disjoint(sets[i],sets[j])
    );

% Get which job each machine is capable of processing
array[0..m-1] of set of 1..n: capable_jobs = array1d(0..m-1, [ { j | j in 1..n where (i - 1) in capable[j] } | i in 1..m ]);

% get earliest job
array[0..m-1] of int: earliest_job =  array1d(0..m-1, [
    (set2array(capable_jobs[k])[arg_min([ release_fix[j,k] | j in capable_jobs[k]])]) | k in 0..m-1
]);

% get job order
array[0..m-1] of array[int] of int: job_order = array1d(0..m-1, [
    sort_by([ j | j in capable_jobs[k] ], [release_fix[j,k] | j in capable_jobs[k]]) | k in 0..m-1
]);

% assign each job to one machine

constraint forall (i in 1..n) (
    exists (k in 0..m-1) (
        i in schedule[k] /\ i in capable_jobs[k]
    )
);


solve minimize makespan;

output[
    "makespan: \(makespan)\n",
    "capable_jobs: \(capable_jobs)\n",
    "earliest_job: \(earliest_job)\n",
    "job_order: \(job_order)\n",
    "capable: \(capable)\n",
    "schedule: {\n",
    concat(
        ["  \(i): \([k | k in schedule[i]]),\n" | i in 0..m-1]
    ),
    "}\n"
];
