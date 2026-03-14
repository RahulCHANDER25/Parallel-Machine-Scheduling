from minizinc import Instance, Model, Result, Solver
import sys
import json

sys.path.append("../data-structure")
from instance_data import InstanceData


class ZincInstanceData:
    """ZincInstanceData is a class that loads the instance data from a JSON file and provides access to the data."""

    _n: int = 0
    _m: int = 0
    _horizon: int = 0
    _capable: list[list[int]] = []
    _duration: list[list[int]] = []
    _release: list[list[int]] = []
    _setup: list[list[list[int]]] = []

    def __init__(self, raw_instance: InstanceData):
        self.raw_instance = raw_instance
        self._n = raw_instance.json_data["n"]
        self._m = raw_instance.json_data["m"]
        self._horizon = raw_instance.json_data["horizon"]
        self._capable = raw_instance.json_data["capable"]
        self._duration = raw_instance.json_data["duration"]
        self._release = raw_instance.json_data["release"]
        self._setup = raw_instance.json_data["setup"]

    def to_dzn(self) -> str:
        """Convert the instance data to a string in the format of a .dzn file."""
        dzn_str = f"n = {self._n};\n"
        dzn_str += f"m = {self._m};\n"
        dzn_str += f"horizon = {self._horizon};\n"
        dzn_str += f"capable = {[set(n) for n in self._capable]};\n"
        dzn_str += f"duration = {self._duration};\n"
        dzn_str += f"release = {self._release};\n"
        dzn_str += f"setup = {self._setup};\n"
        return dzn_str


class ZincRunner:
    """ZincRunner is responsible for running the model with the instance data."""

    _model: Model
    _data: ZincInstanceData
    _solver: Solver
    _instance: Instance

    def __init__(self, data: ZincInstanceData, model: str, solver: str = "highs"):
        self._model = Model(model)
        self._data = data
        self._solver = Solver.lookup(solver)

        self._instance = Instance(self._solver, self._model)

        self._load_data()

    def _load_data(self) -> None:
        self._instance.add_string(self._data.to_dzn())

    def solve(self):
        return self._instance.solve()


def setup(path: str = "../examples/75_3_5_H.json") -> ZincInstanceData:
    """Setup the instance data for the model."""
    raw_instance = InstanceData(path)
    zinc_instance = ZincInstanceData(raw_instance)
    return zinc_instance


def run():
    data = setup(path=sys.argv[1] if len(sys.argv) > 1 else "../examples/75_3_5_H.json")
    runner = ZincRunner(data, "./model.mzn")
    result = runner.solve()
    result_json = json.loads(str(result))
    print(json.dumps(result_json, indent=4))


if __name__ == "__main__":
    run()
