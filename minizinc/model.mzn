include "globals.mzn";

int: n;
int: m;
int: horizon;
array[1..n] of set of 0..m-1: capable;
% array[1..n] of array[1..m] of int: duration;
array[1..n] of array[1..m] of int: release_raw;
% array[1..n] of array[1..n] of array[1..m] of int: setup;

array[1..n,0..m-1] of int: release = array2d(1..n, 0..m-1, [
    release_raw[i][j+1] | i in 1..n, j in 0..m-1
]);

var int: makespan;
constraint makespan <= horizon;

predicate unique_accross_sets_unless_empty(array[int] of var set of int: sets) =
    forall(i, j in index_set(sets) where i != j) (
       disjoint(sets[i],sets[j])
    );

% Get which job each machine is capable of processing
array[0..m-1] of set of 1..n: capable_jobs = array1d(0..m-1, [ { j | j in 1..n where (i - 1) in capable[j] } | i in 1..m ]);

% get earliest job
array[0..m-1] of int: earliest_job =  array1d(0..m-1, [(set2array(capable_jobs[k])[arg_min([ release[j,k] | j in capable_jobs[k]])]) | k in 0..m-1]);

array[0..m-1] of var set of 1..n: schedule;

constraint unique_accross_sets_unless_empty(schedule);


% solve minimize makespan;

output[
    "makespan: \(makespan)\n",
    "capable_jobs: \(capable_jobs)\n",
    "earliest_job: \(earliest_job)\n",
    "capable: \(capable)\n",
    "schedule: \(schedule)\n"
];
