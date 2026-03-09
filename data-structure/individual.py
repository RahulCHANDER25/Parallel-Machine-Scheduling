from typing import Dict, List

class Individual:
    """The Data structure used to represent the population is: `List[List[int]]`,
    a list with each index a machine and each value a list of job id."""
    def __init__(self, scheduling: List[List[int]]):
        self.scheduling = scheduling

    def __str__(self):
        lines = ["Individual schedule:"]
        for machine_id, jobs in enumerate(self.scheduling):
            lines.append(f"- Machine {machine_id}: {jobs}")
        return "\n".join(lines)

    def __repr__(self):
        return self.__str__()

    def copy(self) -> "Individual":
        return Individual([jobs.copy() for jobs in self.scheduling])

    @staticmethod
    def add_one_to_job_ids(job_ids: List[int]) -> List[int]:
        return [job_id + 1 for job_id in job_ids]

    def format_solution(self, makespan: float) -> Dict:
        return {
            "makespan": int(makespan),
            "schedule": {
                str(machine_id): Individual.add_one_to_job_ids(machine_jobs)
                for machine_id, machine_jobs in enumerate(self.scheduling)
            },
        }

# Example:
individual: Individual = Individual([
    [0, 1, 2],  # Machine 0 has jobs 0, 1, and 2
    [3, 4],     # Machine 1 has jobs 3 and 4
    [5]         # Machine 2 has job 5
])
