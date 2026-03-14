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

% no hole
constraint forall(k in 0..m-1) (
    forall(p in 1..n-1) (
        (schedule[k, p] == 0) -> (schedule[k, p+1] == 0)
    )
);

function var int: machine_time(int: k, int: pos) =
    let {
        var 0..n: curr = schedule[k, pos],
        var 0..n: prev = if pos > 1 then schedule[k, pos-1] else 0 endif
    } in
    if curr == 0 then
        if pos > 1 then machine_time(k, pos-1) else 0 endif
    else
        max(
            % Path A: Wait for the machine to be free + setup
            (if pos > 1 then machine_time(k, pos-1) + (if prev > 0 then setup_fix[prev, curr, k] else 0 endif) else 0 endif),
            % Path B: Wait for the job to be released
            release_fix[curr, k]
        ) + duration_fix[curr, k]
    endif;

var int: makespan = max(k in 0..m-1) (machine_time(k, n));
constraint makespan <= horizon;

solve minimize makespan;

output[
    "{\"makespan\": \(makespan),",
    "\"schedule\": {",
    join(
        ",",
        ["  \"\(i)\": \([schedule[i,k] | k in 1..n where schedule[i, k] != 0])" | i in 0..m-1]
    ),
    "}}"
];
