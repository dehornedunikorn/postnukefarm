"""
Felhasználói felület — hotbar a képernyő alján, középen.
"""

from __future__ import annotations

import pygame

from config import (
    COLOR_HIGHLIGHT_OUT_OF_REACH,
    COLOR_HIGHLIGHT_REACH,
    COLOR_HOTBAR_BORDER_ACTIVE,
    COLOR_HOTBAR_BORDER_IDLE,
    COLOR_HOTBAR_SLOT,
    COLOR_HOTBAR_TEXT,
    COLOR_HOTBAR_TEXT_EMPTY,
    HOTBAR_BORDER_ACTIVE,
    HIGHLIGHT_BORDER_WIDTH,
    HOTBAR_BORDER_IDLE,
    HOTBAR_MARGIN_BOTTOM,
    GRID_CELL_SIZE,
    HOTBAR_SLOT_GAP,
    HOTBAR_SLOT_SIZE,
    INVENTORY_SLOT_COUNT,
    SCREEN_HEIGHT,
    SCREEN_WIDTH,
)
from inventory import Inventory, ItemStack
from world import grid_to_pixel


class CellHighlightUI:
    """Áttetsző keret az egér alatti rácscellán — fehér / piros (reach)."""

    def draw(
        self,
        surface: pygame.Surface,
        col: int,
        row: int,
        in_reach: bool,
    ) -> None:
        px, py = grid_to_pixel(col, row)
        cell_rect = pygame.Rect(px, py, GRID_CELL_SIZE, GRID_CELL_SIZE)

        overlay = pygame.Surface(
            (GRID_CELL_SIZE, GRID_CELL_SIZE), pygame.SRCALPHA
        )
        border_color = (
            COLOR_HIGHLIGHT_REACH if in_reach else COLOR_HIGHLIGHT_OUT_OF_REACH
        )
        pygame.draw.rect(
            overlay,
            border_color,
            overlay.get_rect(),
            width=HIGHLIGHT_BORDER_WIDTH,
        )
        surface.blit(overlay, cell_rect.topleft)


class HotbarUI:
    """Öt rekeszes hotbar — mindig a játékvilág fölé rajzolandó."""

    def __init__(self) -> None:
        self._font = pygame.font.SysFont("consolas", 16)
        self._font_bold = pygame.font.SysFont("consolas", 16, bold=True)

    def hotbar_rect(self) -> pygame.Rect:
        """Hotbar terület — egér itt nem irányít pályacellát."""
        return self._hotbar_rect()

    def contains_point(self, x: int, y: int) -> bool:
        return self.hotbar_rect().collidepoint(x, y)

    def _hotbar_rect(self) -> pygame.Rect:
        """Az egész hotbar csoport befoglaló téglalapja (középre igazítva)."""
        total_width = (
            INVENTORY_SLOT_COUNT * HOTBAR_SLOT_SIZE
            + (INVENTORY_SLOT_COUNT - 1) * HOTBAR_SLOT_GAP
        )
        x = (SCREEN_WIDTH - total_width) // 2
        y = SCREEN_HEIGHT - HOTBAR_MARGIN_BOTTOM - HOTBAR_SLOT_SIZE
        return pygame.Rect(x, y, total_width, HOTBAR_SLOT_SIZE)

    def _slot_rect(self, index: int, bar_rect: pygame.Rect) -> pygame.Rect:
        x = bar_rect.x + index * (HOTBAR_SLOT_SIZE + HOTBAR_SLOT_GAP)
        return pygame.Rect(x, bar_rect.y, HOTBAR_SLOT_SIZE, HOTBAR_SLOT_SIZE)

    def _format_slot_text(self, stack: ItemStack | None) -> str:
        if stack is None:
            return ""
        return f"{stack.display_label()}: {stack.quantity}"

    def draw(self, surface: pygame.Surface, inventory: Inventory) -> None:
        bar_rect = self._hotbar_rect()

        for i in range(INVENTORY_SLOT_COUNT):
            slot_rect = self._slot_rect(i, bar_rect)
            is_active = i == inventory.active_slot

            pygame.draw.rect(surface, COLOR_HOTBAR_SLOT, slot_rect)

            border_color = (
                COLOR_HOTBAR_BORDER_ACTIVE
                if is_active
                else COLOR_HOTBAR_BORDER_IDLE
            )
            border_width = (
                HOTBAR_BORDER_ACTIVE if is_active else HOTBAR_BORDER_IDLE
            )
            pygame.draw.rect(
                surface, border_color, slot_rect, width=border_width
            )

            stack = inventory.get_slot(i)
            text = self._format_slot_text(stack)
            if not text:
                continue

            font = self._font_bold if is_active else self._font
            color = COLOR_HOTBAR_TEXT if stack else COLOR_HOTBAR_TEXT_EMPTY
            label = font.render(text, True, color)
            label_rect = label.get_rect(center=slot_rect.center)
            surface.blit(label, label_rect)
