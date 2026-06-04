"""

PostNuke Farm — poszt-apokaliptikus farmolós játék alapja.



Funkciók:

  - Pálya állapot (üres / szikla / megművelt föld / elültetett)

  - Grid-alapú WASD mozgás ütközéssel

  - Egér: cella kiemelés (fehér = elérhető, piros = túl messze)

  - Bal klikk: kapa (üres hotbar) vagy ültetés (Hamu-mag) elérhető cellán

  - Hotbar: 1–5 rekesz váltás

  - Kilépés: Escape vagy ablak bezárása

"""



import sys



import pygame



from config import (

    COLOR_GRID_LINE,

    COLOR_PLAYER,

    FPS,

    GRID_CELL_SIZE,

    GRID_COLS,

    GRID_ROWS,

    MOVE_STEPS_PER_SECOND,

    SCREEN_HEIGHT,

    SCREEN_WIDTH,

    WINDOW_TITLE,

)

from grid_input import find_path, is_within_reach, pixel_to_grid

from interaction import try_interact_cell

from inventory import Inventory

from ui import CellHighlightUI, HotbarUI

from world import World, grid_to_pixel





# ---------------------------------------------------------------------------

# Segédfüggvények

# ---------------------------------------------------------------------------



def clamp_grid(col: int, row: int) -> tuple[int, int]:

    """A pozíciót a játéktér rácsterületére korlátozza."""

    col = max(0, min(col, GRID_COLS - 1))

    row = max(0, min(row, GRID_ROWS - 1))

    return col, row





# ---------------------------------------------------------------------------

# Rácsvonalak (a World cellái fölé)

# ---------------------------------------------------------------------------



class GridOverlay:

    """Halvány rácsvonalak a cellák felett."""



    def __init__(self, surface: pygame.Surface) -> None:

        self._surface = surface



    def draw(self) -> None:

        for x in range(0, SCREEN_WIDTH + 1, GRID_CELL_SIZE):

            pygame.draw.line(

                self._surface, COLOR_GRID_LINE, (x, 0), (x, SCREEN_HEIGHT)

            )

        for y in range(0, SCREEN_HEIGHT + 1, GRID_CELL_SIZE):

            pygame.draw.line(

                self._surface, COLOR_GRID_LINE, (0, y), (SCREEN_WIDTH, y)

            )





# ---------------------------------------------------------------------------

# Játékos

# ---------------------------------------------------------------------------



class Player:

    """

    Túlélő karakter — jelenleg zöld négyzet placeholder.



    Pozíció rácskoordinátában; mozgás csak járható cellára.

    """



    def __init__(self, start_col: int, start_row: int) -> None:

        self.col, self.row = clamp_grid(start_col, start_row)

        self._size = GRID_CELL_SIZE

        self._rect = pygame.Rect(0, 0, self._size, self._size)

        self.inventory = Inventory()

        self._update_rect()



    def _update_rect(self) -> None:

        px, py = grid_to_pixel(self.col, self.row)

        self._rect.topleft = (px, py)



    @property

    def position(self) -> tuple[int, int]:

        return self.col, self.row



    @property

    def rect(self) -> pygame.Rect:

        return self._rect



    def move(self, dcol: int, drow: int, world: World) -> None:

        """Egy cellányi lépés, ha a cél járható."""

        new_col, new_row = clamp_grid(self.col + dcol, self.row + drow)

        if (new_col, new_row) == (self.col, self.row):

            return

        if not world.is_walkable(new_col, new_row):

            return

        self.col, self.row = new_col, new_row

        self._update_rect()



    def draw(self, surface: pygame.Surface) -> None:

        pygame.draw.rect(surface, COLOR_PLAYER, self._rect)





# ---------------------------------------------------------------------------

# Fő játékállapot és hurok

# ---------------------------------------------------------------------------



class Game:

    """Pygame inicializálás, bemenet, frissítés és kirajzolás."""



    def __init__(self) -> None:

        pygame.init()

        self.screen = pygame.display.set_mode((SCREEN_WIDTH, SCREEN_HEIGHT))

        pygame.display.set_caption(WINDOW_TITLE)

        self.clock = pygame.time.Clock()



        self.world = World()

        start_col, start_row = GRID_COLS // 2, GRID_ROWS // 2

        self.player = Player(start_col, start_row)



        self.world.spawn_obstacles(exclude={self.player.position})



        self.grid_overlay = GridOverlay(self.screen)

        self.hotbar_ui = HotbarUI()

        self.cell_highlight = CellHighlightUI()



        self._hover_cell: tuple[int, int] | None = None

        self._hover_in_reach = False



        self._running = True

        self._move_cooldown = 0.0



        self._slot_keys = {

            pygame.K_1: 0,

            pygame.K_2: 1,

            pygame.K_3: 2,

            pygame.K_4: 3,

            pygame.K_5: 4,

        }



    def _update_mouse_hover(self) -> None:

        """Egér alatti cella és elérhetőség (minden képkockán)."""

        mouse_x, mouse_y = pygame.mouse.get_pos()



        if self.hotbar_ui.contains_point(mouse_x, mouse_y):

            self._hover_cell = None

            self._hover_in_reach = False

            return



        cell = pixel_to_grid(mouse_x, mouse_y)

        if cell is None:

            self._hover_cell = None

            self._hover_in_reach = False

            return



        col, row = cell

        self._hover_cell = (col, row)

        self._hover_in_reach = is_within_reach(

            self.player.col, self.player.row, col, row

        )



    def _handle_events(self) -> None:

        for event in pygame.event.get():

            if event.type == pygame.QUIT:

                self._running = False

            elif event.type == pygame.KEYDOWN:

                if event.key == pygame.K_ESCAPE:

                    self._running = False

                elif event.key in self._slot_keys:

                    self.player.inventory.select_slot(self._slot_keys[event.key])

                else:

                    self._try_step_from_key(event.key)

            elif event.type == pygame.MOUSEBUTTONDOWN:

                if event.button == 1:

                    self._handle_left_click(event.pos)



    def _handle_left_click(self, pos: tuple[int, int]) -> None:

        """Bal klikk: interakció csak elérhető (fehér) cellán."""

        mouse_x, mouse_y = pos



        if self.hotbar_ui.contains_point(mouse_x, mouse_y):

            return



        cell = pixel_to_grid(mouse_x, mouse_y)

        if cell is None:

            return



        col, row = cell

        if not is_within_reach(self.player.col, self.player.row, col, row):

            return



        try_click_cell(

            self.world,

            col,

            row,

            self.player.col,

            self.player.row,

            self.player.inventory,

        )



    def _direction_from_keys(self) -> tuple[int, int]:

        """Lenyomott WASD → (dcol, drow); üres, ha nincs irány."""

        keys = pygame.key.get_pressed()

        dcol, drow = 0, 0

        if keys[pygame.K_w] or keys[pygame.K_UP]:

            drow = -1

        elif keys[pygame.K_s] or keys[pygame.K_DOWN]:

            drow = 1

        if keys[pygame.K_a] or keys[pygame.K_LEFT]:

            dcol = -1

        elif keys[pygame.K_d] or keys[pygame.K_RIGHT]:

            dcol = 1

        return dcol, drow



    def _try_step_from_key(self, key: int) -> None:

        """Egylépcsős mozgás billentyű lenyomásakor."""

        direction_map = {

            pygame.K_w: (0, -1),

            pygame.K_UP: (0, -1),

            pygame.K_s: (0, 1),

            pygame.K_DOWN: (0, 1),

            pygame.K_a: (-1, 0),

            pygame.K_LEFT: (-1, 0),

            pygame.K_d: (1, 0),

            pygame.K_RIGHT: (1, 0),

        }

        if key in direction_map:

            dcol, drow = direction_map[key]

            self.player.move(dcol, drow, self.world)

            self._move_cooldown = 1.0 / MOVE_STEPS_PER_SECOND



    def _update(self, dt: float) -> None:

        self._update_mouse_hover()



        self._move_cooldown -= dt

        if self._move_cooldown > 0:

            return



        dcol, drow = self._direction_from_keys()

        if dcol != 0 or drow != 0:

            self.player.move(dcol, drow, self.world)

            self._move_cooldown = 1.0 / MOVE_STEPS_PER_SECOND



    def _draw(self) -> None:

        self.world.draw(self.screen)

        self.grid_overlay.draw()

        self.player.draw(self.screen)



        if self._hover_cell is not None:

            col, row = self._hover_cell

            self.cell_highlight.draw(

                self.screen, col, row, self._hover_in_reach

            )



        self.hotbar_ui.draw(self.screen, self.player.inventory)

        pygame.display.flip()



    def run(self) -> None:

        while self._running:

            dt = self.clock.tick(FPS) / 1000.0

            self._handle_events()

            self._update(dt)

            self._draw()



        pygame.quit()





def main() -> None:

    game = Game()

    game.run()





if __name__ == "__main__":

    try:

        main()

    except KeyboardInterrupt:

        pygame.quit()

        sys.exit(0)


