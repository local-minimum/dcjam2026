#!/env/bin/python3
from matplotlib import pyplot as plt
from configparser import ConfigParser
from collections import namedtuple
from pathlib import Path
import re
import numpy as np
import random

_D_PATTERN: re.Pattern = re.compile("^(\\d?)[dD](\\d+)(\\+\\d|-\\d)?$")
_R_PATTERN: re.Pattern = re.compile("^\\{([\\d,]+)\\}$")

class Die:
    _sides: list[int]
    def __init__(self: "Die", sides: list[int]):
        self._sides = sides
    def __str__(self: "Die") -> str:
        return "<Die {}>".format(self._sides)
    def roll(self: "Die") -> int:
        return random.choice(self._sides)
    def roll_many(self: "Die", rolls: int) -> np.ndarray[np.int32]:
        a: np.ndarray[np.int32] = np.zeros(shape=(rolls,), dtype=np.int32)
        for i in range(rolls):
            a[i] = self.roll()
        return a
            
    @classmethod
    def create_from_string(cls: "Die", die_string: str) -> list["Die"]:
        m: re.Match = _D_PATTERN.search(die_string)
        if m:
            n: int = int(m.groups()[0]) if m.groups()[0] else 1
            s: int = int(m.groups()[1])
            off: int = int(m.groups()[2]) if m.groups()[2] else 0
            return list(Die(list(range(off, s + off))) for _ in range(n))
        m = _R_PATTERN.search(die_string)
        if m:
            sides: list[int] = list(int(v) for v in m.groups()[0].split(","))
            return [Die(sides)]
        return []

Enemy = namedtuple("Enemy", ("name", "health", "loot_value", "defence", "attacks"))

_A_PATTERN: re.Pattern = re.compile('"([^"]*)"')
_DIR: Path = Path("../clicker/enemies") 

def get_resource(name: str) -> Enemy:
    print("Loading {}".format(name))
    parser: ConfigParser = ConfigParser()
    parser.read(_DIR / "{}.tres".format(name))
    data = parser['resource'] 
    return Enemy(
        data['monster_name'].strip('"'),
        float(data['max_health']),
        int(data['loot_value']),
        Die.create_from_string(data.get('defence','').strip('"')),
        list(Die.create_from_string(d_string) for d_string in _A_PATTERN.findall(data['attacks']))
    )

e_files: list[str] = [
    "b_ore",
    "buckley_500",
    "buckley_900",
    "d_ore",
    "ingomatic_v1",
    "ingomatic_v3",
    "tintron_mk1",
    "tintron_mk3",
    "brassodon",
    "buckley_600",
    "c_ore",
    "goldiraptor",
    "ingomatic_v2",
    "ironosaurus",
    "tintron_mk2",
]

for f in e_files:
    plt.clf()
    e: Enemy = get_resource(f)
    attacks = [np.array([d.roll_many(10000) for d in atype]).sum(0) for atype in e.attacks]
    attack = np.concatenate(attacks).ravel()
    counts, bins = np.histogram(attack)
    plt.stairs(counts, bins)
    plt.title("{} - {} score ATTACK".format(e.name, e.loot_value))
    plt.savefig("{}.attack.png".format(e.name))
