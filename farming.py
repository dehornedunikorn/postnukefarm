"""
Földművelés és ültetés — pálya + inventory összekötése.
"""

from __future__ import annotations

from inventory import ITEM_ASH_SEED, Inventory
from world import World


def try_plant_ash_seed(
    world: World,
    col: int,
    row: int,
    inventory: Inventory,
) -> bool:
    """
    Mag ültetése a kattintott / célcellára (elérhetőség kívül ellenőrizve).

    Feltételek:
      - cella megművelt föld (SOIL), még nincs elültetve
      - aktív hotbar rekeszben Hamu-mag, mennyiség > 0

    Üres vagy más tárgy az aktív rekeszben: csendes elutasítás (False).
    """
    if not world.can_plant(col, row):
        return False

    if not inventory.active_has_item(ITEM_ASH_SEED):
        return False

    if not world.plant_seed(col, row):
        return False

    inventory.consume_one_from_active()
    return True
