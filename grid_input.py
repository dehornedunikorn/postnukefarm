"""
Egér ↔ rács koordináták, elérési távolság (reach).
"""

from __future__ import annotations

import heapq

from config import GRID_CELL_SIZE, GRID_COLS, GRID_ROWS, SCREEN_HEIGHT, SCREEN_WIDTH

# Maximum 1 cella távolság (vízszint, függő, átló — Chebyshev)
REACH_MAX_CHEBYSHEV = 1


def pixel_to_grid(mouse_x: int, mouse_y: int) -> tuple[int, int] | None:
    """
    Pygame egérpozíció → (col, row).

    A cellamérettel osztva; a játéktéren kívül None.
    """
    if mouse_x < 0 or mouse_y < 0:
        return None
    if mouse_x >= SCREEN_WIDTH or mouse_y >= SCREEN_HEIGHT:
        return None

    col = mouse_x // GRID_CELL_SIZE
    row = mouse_y // GRID_CELL_SIZE

    if col < 0 or col >= GRID_COLS or row < 0 or row >= GRID_ROWS:
        return None

    return col, row


def chebyshev_distance(
    col_a: int, row_a: int, col_b: int, row_b: int
) -> int:
    """Rácsbeli távolság (8 irány, max(|Δcol|, |Δrow|))."""
    return max(abs(col_a - col_b), abs(row_a - row_b))


def is_within_reach(
    player_col: int,
    player_row: int,
    target_col: int,
    target_row: int,
) -> bool:
    """A célcella legfeljebb 1 cellányira van (átlósan is)."""
    return (
        chebyshev_distance(player_col, player_row, target_col, target_row)
        <= REACH_MAX_CHEBYSHEV
    )


def _get_neighbors(col: int, row: int) -> list[tuple[int, int]]:
    return [
        (col - 1, row - 1),
        (col - 1, row),
        (col - 1, row + 1),
        (col, row - 1),
        (col, row + 1),
        (col + 1, row - 1),
        (col + 1, row),
        (col + 1, row + 1),
    ]


def find_path(
    world,
    start: tuple[int, int],
    goal: tuple[int, int],
) -> list[tuple[int, int]] | None:
    """Legrövidebb útvonal keresése akadályok kikerülésével (A*)."""
    start_col, start_row = start
    goal_col, goal_row = goal

    if not world.is_walkable(goal_col, goal_row):
        return None

    open_set: list[tuple[int, int, tuple[int, int]]] = []
    heapq.heappush(
        open_set,
        (
            chebyshev_distance(start_col, start_row, goal_col, goal_row),
            0,
            start,
        ),
    )

    came_from: dict[tuple[int, int], tuple[int, int]] = {}
    g_score: dict[tuple[int, int], int] = {start: 0}

    while open_set:
        _, current_g, current = heapq.heappop(open_set)
        if current == goal:
            path = [current]
            while current in came_from:
                current = came_from[current]
                path.append(current)
            return list(reversed(path))

        if current_g > g_score.get(current, 0):
            continue

        for neighbor in _get_neighbors(*current):
            col, row = neighbor
            if col < 0 or col >= GRID_COLS or row < 0 or row >= GRID_ROWS:
                continue
            if not world.is_walkable(col, row):
                continue

            tentative_g = current_g + 1
            if tentative_g < g_score.get(neighbor, float("inf")):
                came_from[neighbor] = current
                g_score[neighbor] = tentative_g
                priority = (
                    tentative_g
                    + chebyshev_distance(col, row, goal_col, goal_row)
                )
                heapq.heappush(open_set, (priority, tentative_g, neighbor))

    return None
