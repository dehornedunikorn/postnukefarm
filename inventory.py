"""
Hátizsák / hotbar — fix számú rekesz, tárgy név + mennyiség.
"""

from __future__ import annotations

from dataclasses import dataclass

from config import INVENTORY_SLOT_COUNT

# Kezdő tárgy (belső név); a UI rövidített címkét használ
ITEM_ASH_SEED = "Hamu-mag"

# Hotbar szöveg: belső név → rövid felirat
ITEM_DISPLAY_LABELS: dict[str, str] = {
    ITEM_ASH_SEED: "Mag",
}


@dataclass
class ItemStack:
    """Egy rekeszben lévő tárgy és darabszáma."""

    name: str
    quantity: int

    def display_label(self) -> str:
        """UI-hoz rövidített név (pl. 'Mag')."""
        return ITEM_DISPLAY_LABELS.get(self.name, self.name[:4])


class Inventory:
    """
    Maximum 5 rekeszes hotbar.

    slots: index 0 = 1-es billentyű, index 4 = 5-ös billentyű.
    """

    def __init__(self) -> None:
        self.slots: list[ItemStack | None] = [None] * INVENTORY_SLOT_COUNT
        self.active_slot: int = 0
        self._init_starting_items()

    def _init_starting_items(self) -> None:
        """Indulás: 1. rekeszben 5 db Hamu-mag."""
        self.slots[0] = ItemStack(name=ITEM_ASH_SEED, quantity=5)

    def select_slot(self, index: int) -> None:
        """Aktív rekesz beállítása (0–4)."""
        if 0 <= index < INVENTORY_SLOT_COUNT:
            self.active_slot = index

    def get_active_item(self) -> ItemStack | None:
        return self.slots[self.active_slot]

    def get_slot(self, index: int) -> ItemStack | None:
        if 0 <= index < INVENTORY_SLOT_COUNT:
            return self.slots[index]
        return None

    def active_has_item(self, item_name: str) -> bool:
        """Az aktív rekeszben van-e a megadott tárgy (mennyiség > 0)."""
        stack = self.get_active_item()
        return (
            stack is not None
            and stack.name == item_name
            and stack.quantity > 0
        )

    def consume_one_from_active(self) -> bool:
        """
        Egy darab levonása az aktív rekeszből.

        Ha a mennyiség 0-ra csökken, a rekesz kiürül. Üres vagy 0 db esetén False.
        """
        stack = self.get_active_item()
        if stack is None or stack.quantity <= 0:
            return False

        stack.quantity -= 1
        if stack.quantity <= 0:
            self.slots[self.active_slot] = None
        return True
