from typing import List

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

# Example:
individual: Individual = Individual([
    [0, 1, 2],  # Machine 0 has jobs 0, 1, and 2
    [3, 4],     # Machine 1 has jobs 3 and 4
    [5]         # Machine 2 has job 5
])
