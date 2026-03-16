include "globals.mzn";

int: n;
int: m;
int: horizon;
array[1..n] of set of 0..m-1: capable;
array[1..n,0..m-1] of 0..horizon: duration;
array[1..n,0..m-1] of 0..horizon: release;
array[1..n,1..n,0..m-1] of 0..horizon: setup;

array[0..m-1, 1..n] of var 0..n: schedule;

constraint unique_accross_arrays_unless_0(schedule);

predicate unique_accross_arrays_unless_0(array[0..m-1, 1..n] of var 0..n: jobs_arrays) =
    forall(v in 1..n) (
        sum(i in 0..m-1, j in 1..n) (
            bool2int(jobs_arrays[i,j] == v)
        ) <= 1
    );

% Assign one machine per job
constraint forall (i in 1..n) (
    exists (k in capable[i], pos in 1..n) (
        schedule[k, pos] == i
    )
);

% no hole
constraint forall(k in 0..m-1) (
    forall(p in 1..n-1) (
        (schedule[k, p] == 0) -> (schedule[k, p+1] == 0)
    )
);

% New decision variable to track completion times
array[0..m-1, 0..n] of var 0..horizon: finish_time;

% Base case: Time at position 0 is always 0
constraint forall(k in 0..m-1) (
    finish_time[k, 0] = 0
);

%Iterative calculation (No recursion)
constraint forall(k in 0..m-1, pos in 1..n) (
    let {
        var 0..n: curr = schedule[k, pos],
        var 0..n: prev = if pos > 1 then schedule[k, pos-1] else 0 endif
    } in
    finish_time[k, pos] = if curr == 0 then
        % If no job is scheduled here, the finish time is the same as the previous slot
        finish_time[k, pos-1]
    else
        % Otherwise, it's the max of (Previous Finish + Setup) and (Release Time) + Duration
        max(
            finish_time[k, pos-1] + (if prev > 0 then setup[prev, curr, k] else 0 endif),
            release[curr, k]
        ) + duration[curr, k]
    endif
);

% Your objective now uses the pre-calculated finish_time array
var int: makespan = max(k in 0..m-1) (finish_time[k, n]);
% var int: makespan;
constraint makespan <= horizon;

solve minimize (sum (k in 0..m-1) (finish_time[k, n]) + makespan);

output[
    "{\"makespan\": \(makespan),",
    "\"schedule\": {",
    join(
        ",",
        ["  \"\(i)\": \([schedule[i,k] | k in 1..n where schedule[i, k] != 0])" | i in 0..m-1]
    ),
    "}}"
];
