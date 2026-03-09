import json

class InstanceData:
    """InstanceData is a class that loads the instance data from a JSON file and provides access to the data."""

    def __init__(self, json_path: str = '../examples/75_3_5_H.json'):
        self.json_data = {}
        with open(json_path, 'r') as f:
            self.json_data = json.load(f)

    def __str__(self):
        return "\n".join(
            [
                f"Number of Jobs: {self.json_data['n']}",
                f"Number of Machines: {self.json_data['m']}",
                f"Horizon: {self.json_data['horizon']}",
                f"Capable: {self.json_data['capable']}",
                f"Duration: {self.json_data['duration']}",
                f"Release: {self.json_data['release']}",
                f"Setup: {self.json_data['setup']}",
            ]
        )
