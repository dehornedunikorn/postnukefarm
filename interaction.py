"""
Point-and-click interakció — a játékos célcellára érkezése után történik.
"""

from __future__ import annotations

from farming import try_plant_ash_seed
from inventory import ITEM_ASH_SEED, Inventory
from world import World


def try_interact_cell(
    world: World,
    col: int,
    row: int,
    inventory: Inventory,
) -> bool:
    """
    A kattintott cellán az aktív hotbar alapján végrehajtott művelet.

    - Üres aktív rekesz → kapa (megművelés)
    - Hamu-mag az aktív rekeszben → ültetés
    - Egyéb tárgy vagy érvénytelen cél → nincs hatás
    """
    if inventory.active_has_item(ITEM_ASH_SEED):
        return try_plant_ash_seed(world, col, row, inventory)

    if inventory.get_active_item() is None:
        return world.cultivate(col, row)

    return False
