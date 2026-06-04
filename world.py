"""
Pálya (világ) állapota: cellánkénti típusok, akadályok, földművelés.

A World osztály a játéktér teljes rácsának állapotát tárolja és kezeli.
"""

from __future__ import annotations

import random
from enum import Enum, auto
from typing import Iterable

import pygame

from config import (
    COLOR_OBSTACLE,
    COLOR_PLANTED_MARKER,
    COLOR_SOIL,
    COLOR_WASTELAND_BG,
    GRID_CELL_SIZE,
    GRID_COLS,
    GRID_ROWS,
    OBSTACLE_COUNT_MAX,
    OBSTACLE_COUNT_MIN,
    PLANTED_MARKER_RADIUS,
)


class CellType(Enum):
    """Egy rácscella lehetséges állapota."""

    EMPTY = auto()      # üres pusztaság
    OBSTACLE = auto()   # szikla — nem járható, nem művelhető
    SOIL = auto()       # megművelt föld (kapa / SPACE)
    PLANTED = auto()    # megművelt + elültetett mag (E)


# Kirajzolási színek cellatípusonként (PLANTED alapja is sötétbarna)
CELL_COLORS: dict[CellType, tuple[int, int, int]] = {
    CellType.EMPTY: COLOR_WASTELAND_BG,
    CellType.OBSTACLE: COLOR_OBSTACLE,
    CellType.SOIL: COLOR_SOIL,
    CellType.PLANTED: COLOR_SOIL,
}


def grid_to_pixel(col: int, row: int) -> tuple[int, int]:
    """Rácskoordináta → pixel bal felső sarok."""
    return col * GRID_CELL_SIZE, row * GRID_CELL_SIZE


class World:
    """
    A pálya celláinak adatbázisa.

    Minden (col, row) pozícióhoz egy CellType tartozik.
    """

    def __init__(self) -> None:
        self._cells: list[list[CellType]] = [
            [CellType.EMPTY for _ in range(GRID_COLS)]
            for _ in range(GRID_ROWS)
        ]

    def in_bounds(self, col: int, row: int) -> bool:
        return 0 <= col < GRID_COLS and 0 <= row < GRID_ROWS

    def get(self, col: int, row: int) -> CellType:
        return self._cells[row][col]

    def set(self, col: int, row: int, cell_type: CellType) -> None:
        self._cells[row][col] = cell_type

    def is_walkable(self, col: int, row: int) -> bool:
        """Akadályra nem léphet a játékos."""
        if not self.in_bounds(col, row):
            return False
        return self.get(col, row) != CellType.OBSTACLE

    def can_cultivate(self, col: int, row: int) -> bool:
        """Csak üres cellát lehet megművelni; sziklát nem."""
        if not self.in_bounds(col, row):
            return False
        return self.get(col, row) == CellType.EMPTY

    def cultivate(self, col: int, row: int) -> bool:
        """
        Kapa (SPACE): üres → megművelt föld.

        Visszaadja, hogy történt-e változás.
        """
        if not self.can_cultivate(col, row):
            return False
        self.set(col, row, CellType.SOIL)
        return True

    def can_plant(self, col: int, row: int) -> bool:
        """Csak megművelt, még nem ültetett cellára lehet magot tenni."""
        if not self.in_bounds(col, row):
            return False
        return self.get(col, row) == CellType.SOIL

    def plant_seed(self, col: int, row: int) -> bool:
        """
        Ültetés: megművelt föld → elültetett.

        Visszaadja, hogy történt-e változás.
        """
        if not self.can_plant(col, row):
            return False
        self.set(col, row, CellType.PLANTED)
        return True

    def spawn_obstacles(
        self,
        count: int | None = None,
        exclude: Iterable[tuple[int, int]] = (),
    ) -> int:
        """
        Véletlenszerű sziklák elhelyezése a pályán.

        exclude: ezekre a cellákra nem kerül akadály (pl. játékos start).
        Visszaadja a ténylegesen lerakott akadályok számát.
        """
        if count is None:
            count = random.randint(OBSTACLE_COUNT_MIN, OBSTACLE_COUNT_MAX)

        blocked = set(exclude)
        for row in range(GRID_ROWS):
            for col in range(GRID_COLS):
                if self.get(col, row) == CellType.OBSTACLE:
                    blocked.add((col, row))

        candidates = [
            (col, row)
            for row in range(GRID_ROWS)
            for col in range(GRID_COLS)
            if (col, row) not in blocked
        ]
        random.shuffle(candidates)

        placed = 0
        for col, row in candidates:
            if placed >= count:
                break
            self.set(col, row, CellType.OBSTACLE)
            blocked.add((col, row))
            placed += 1

        return placed

    def draw(self, surface: pygame.Surface) -> None:
        """Cellák kitöltése; elültetett cellán zöld jelölő a közepén."""
        for row in range(GRID_ROWS):
            for col in range(GRID_COLS):
                cell_type = self.get(col, row)
                color = CELL_COLORS[cell_type]
                px, py = grid_to_pixel(col, row)
                rect = pygame.Rect(px, py, GRID_CELL_SIZE, GRID_CELL_SIZE)
                pygame.draw.rect(surface, color, rect)

                if cell_type == CellType.PLANTED:
                    pygame.draw.circle(
                        surface,
                        COLOR_PLANTED_MARKER,
                        rect.center,
                        PLANTED_MARKER_RADIUS,
                    )
