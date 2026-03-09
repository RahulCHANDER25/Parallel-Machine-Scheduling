import json
import math
from pathlib import Path
from typing import Any, Dict, Mapping

import matplotlib.pyplot as plt
from matplotlib.patches import Patch

from checker import check_and_evaluate

def _as_dict(data_or_path: str | Path | Mapping[str, Any]) -> Dict[str, Any]:
    if isinstance(data_or_path, Mapping):
        return dict(data_or_path)
    with open(Path(data_or_path), "r", encoding="utf-8") as f:
        return json.load(f)


def plot_schedule_from_json(
    instance_path: str | Path | Mapping[str, Any],
    solution_path: str | Path | Mapping[str, Any],
    *,
    show_plot: bool = True,
    legend_columns: int | None = None,
) -> Dict[str, Any]:
    instance = _as_dict(instance_path)
    solution = _as_dict(solution_path)

    feasible, check_result = check_and_evaluate(instance, solution)
    machine_count = instance["m"]
    schedule = solution.get("schedule", {})

    _, ax = plt.subplots(figsize=(14, max(5, machine_count + 2)))

    if schedule:
        cmap = plt.cm.get_cmap("tab20")
        jobs_sorted = sorted(job for jobs in schedule.values() for job in jobs)
        colors = {job_id: cmap(i % 20) for i, job_id in enumerate(jobs_sorted)}

        for machine_str, jobs in schedule.items():
            machine = int(machine_str)
            current_time = 0
            prev_job_idx = None

            for idx, job_id in enumerate(jobs):
                job_idx = job_id - 1
                release_time = instance["release"][job_idx][machine]

                if idx == 0:
                    start = max(current_time, release_time)
                else:
                    setup_time = instance["setup"][prev_job_idx][job_idx][machine]
                    start = max(release_time, current_time + setup_time)

                end = start + instance["duration"][job_idx][machine]
                width = end - start

                ax.barh(machine, width, left=start, height=0.65, color=colors[job_id], edgecolor="black")
                ax.text(start + width / 2, machine, f"J{job_id}", ha="center", va="center", fontsize=9, weight="bold")

                current_time = end
                prev_job_idx = job_idx

        legend_handles = [
            Patch(facecolor=colors[job_id], edgecolor="black", label=f"Job {job_id}")
            for job_id in jobs_sorted
        ]
        if legend_columns is None:
            legend_columns = max(1, math.ceil(len(jobs_sorted) / 75))

        ax.legend(
            legend_handles,
            [h.get_label() for h in legend_handles],
            title="Jobs",
            loc="upper left",
            bbox_to_anchor=(1.02, 1.0),
            borderaxespad=0.0,
            ncol=legend_columns,
            columnspacing=1.0,
            handletextpad=0.5,
        )

    ax.set_yticks(range(machine_count))
    ax.set_yticklabels([f"Machine {k}" for k in range(machine_count)])
    ax.invert_yaxis()
    ax.set_xlabel("Time")
    ax.set_ylabel("Machines")
    ax.grid(axis="x", linestyle="--", alpha=0.35)

    reported_makespan = solution.get("makespan")
    if feasible:
        computed_makespan = int(check_result)
        match = computed_makespan == reported_makespan
        title = (
            f"Schedule | Feasible: YES | Computed makespan: {computed_makespan}"
            f" | Reported makespan: {reported_makespan}"
            f" | Match: {'YES' if match else 'NO'}"
        )
        status_text = "Feasible"
        status_color = "#1B7F1B"
    else:
        computed_makespan = None
        title = f"Schedule | Feasible: NO | Reason: {check_result}"
        status_text = "Infeasible"
        status_color = "#B22222"

    ax.set_title(title, fontsize=11)
    ax.text(
        0.99,
        1.02,
        status_text,
        transform=ax.transAxes,
        ha="right",
        va="bottom",
        fontsize=10,
        color="white",
        bbox={"boxstyle": "round,pad=0.3", "facecolor": status_color, "edgecolor": "none"},
    )

    plt.tight_layout(rect=[0.0, 0.0, 0.80, 1.0])
    if show_plot:
        plt.show()

    return {
        "feasible": feasible,
        "checker_result": check_result,
        "reported_makespan": reported_makespan,
        "computed_makespan": computed_makespan,
    }
