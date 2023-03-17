#include "Game.h"
#include <unistd.h>

#define STB_IMAGE_IMPLEMENTATION
#define STBI_ONLY_GIF

#include "stb/stb_image.h"

static Game *init(sf::RenderWindow *window);
static bool check_exit(Game *game);
static void move_cat(Game *game, Direction direction);
static GIF* get_gif_frames(const char *catgif, int vert_size, int hor_size);
static void draw_catgif(Game *game, GIF *catgif);
static void draw_maze(Game *game);
static void celebrate_win(Game *game);

bool run_game() {
	sf::RenderWindow window(sf::VideoMode(SCREEN_SIZE, SCREEN_SIZE), "", sf::Style::None);
	Game *game = init(&window);
	sf::Event event;
	Direction direction = Direction::Nope;
	
	while (!game->solved) {
		while (game->window->pollEvent(event)) {
            // stop if window closed
            if (event.type == sf::Event::Closed) {
                game->window->close();
				return false;
            }

			direction = Direction::Nope;

			if (event.type == sf::Event::KeyPressed) {
				switch (event.key.code) {
					case sf::Keyboard::Left:
						direction = Direction::Left;
						break;
					case sf::Keyboard::Right:
						direction = Direction::Right;
						break;
					case sf::Keyboard::Up:
						direction = Direction::Up;
						break;
					case sf::Keyboard::Down:
						direction = Direction::Down;
						break;
					case sf::Keyboard::Escape:
						game->window->close();
						return false;
					default:
						break;
				}
			}

			if (direction != Direction::Nope) move_cat(game, direction);
			if (game->solved) break;

			draw_catgif(game, game->gifs.cat_wait);
        }
	}

	celebrate_win(game);
	game->window->close();
	return true;
}

static Game *init(sf::RenderWindow *window) {
	Game *game = (Game*) calloc(1, sizeof(Game));

	// Init main window and set it's position to higher left point
	game->window = window;
    game->window->setPosition(sf::Vector2i(0, 0));

	// Подгружаем шрифт
	// game->font.loadFromFile("calibri.ttf");

	// load textures
    game->text.wall.loadFromFile("cracker/images/wall1.webp.png");
	game->text.space.loadFromFile("cracker/images/space.png");

	// load gifs
	game->gifs.cat_left  = get_gif_frames("cracker/images/left.gif", MAZE_SIZE, MAZE_SIZE);
	game->gifs.cat_down  = get_gif_frames("cracker/images/down.gif", MAZE_SIZE, MAZE_SIZE);
	game->gifs.cat_right = get_gif_frames("cracker/images/right.gif", MAZE_SIZE, MAZE_SIZE);
	game->gifs.cat_up    = get_gif_frames("cracker/images/up.gif", MAZE_SIZE, MAZE_SIZE);
	game->gifs.cat_sleep = get_gif_frames("cracker/images/down.gif", MAZE_SIZE, MAZE_SIZE);
	game->gifs.cat_wait  = get_gif_frames("cracker/images/wait.gif", MAZE_SIZE, MAZE_SIZE);

	// Заполняем лабиринт
	for (int i = 0; i < ARRAY_SIZE - 1; i++) {
		game->maze[i] = sf::Sprite();
		if (Maze[i] == TileType::SPACE) game->maze[i].setTexture(game->text.wall);
		if (Maze[i] == TileType::WALL)  game->maze[i].setTexture(game->text.space);

		game->maze[i].setPosition((i % MAZE_SIZE) * CELL_SIZE, (i / MAZE_SIZE) * SCREEN_SIZE);
	}

	// Ставим котика в левую верхнюю позицию
	game->cat_index = MAZE_SIZE + 1;
	game->solved = false;

	return game;
}

static bool check_exit(Game *game) {
	// проверка вышел ли котик из лабиринта
	if (game->cat_index == ARRAY_SIZE - MAZE_SIZE - 1) return true;
	return false;
}

static void move_cat(Game *game, Direction direction) {
	// Вычисляем строку и колонку котика
	int col = game->cat_index % MAZE_SIZE;
	int row = game->cat_index / MAZE_SIZE;

    // Вычисление индекса новой позиции котика и подбор гифки
	int move_index = -1;
	GIF *catgif = {};

	switch (direction) {
		case Direction::Left:
			catgif = game->gifs.cat_left;
			move_index = game->cat_index - 1;
			break;
		case Direction::Right:
			catgif = game->gifs.cat_right;
			move_index = game->cat_index + 1;
			break;
		case Direction::Up:
			catgif = game->gifs.cat_up;
			move_index = game->cat_index + MAZE_SIZE;
			break;
		case Direction::Down:
			catgif = game->gifs.cat_down;
			move_index = game->cat_index - MAZE_SIZE;
			break;
	}

    // Проверка на отсутствие стены на будущей позиции котика
    if (Maze[move_index] == TileType::WALL) {
        move_index = -1;
    }

	// Перемещение котика на новую позицию если это возможно
	if (move_index >= 0) {
		game->maze[game->cat_index].setTexture(game->text.space);
		game->cat_index = move_index;
		draw_catgif(game, catgif);
	}

	// Проверка вышел ли котик из лабиринта
	game->solved = check_exit(game);
}

static void draw_catgif(Game *game, GIF *catgif) {
	// Покадровая отрисовка гифки с котом
	for (int i = 0; i < catgif->size; ++i) {
		game->window->clear();
		game->maze[game->cat_index].setTexture(catgif->arr[i].frame);
		draw_maze(game);
		game->window->draw(game->maze[game->cat_index]);
		usleep(catgif->arr[i].delay);
		game->window->display();
	}
}

static void draw_maze(Game *game) {
	// Поклеточная отрисовка лабиринта
	sf::RenderWindow win1(sf::VideoMode(SCREEN_SIZE, SCREEN_SIZE), "", sf::Style::None);
	for (size_t i = 0; i < ARRAY_SIZE; ++i) {
		for (int i = 0; i < ARRAY_SIZE - 1; i++) {
			if (i != game->cat_index) win1.draw(game->maze[i]);
		}
	}

}

static void celebrate_win(Game *game) {
	draw_catgif(game, game->gifs.cat_sleep);
}

static GIF* get_gif_frames(const char *catgif, int vert_size, int hor_size) {
	int* delay_list = 0;
	int  frame_count = 0;
	int  channel = 0;
	int  arr_step = vert_size * hor_size * 4;

	FILE* gif_orig = stbi__fopen(catgif, "rb");
	stbi__context context = {};
	stbi__start_file(&context, gif_orig);

	void* gif_arr = stbi__load_gif_main(&context, &delay_list, &hor_size, &vert_size, 
	                                          &frame_count, &channel, STBI_rgb_alpha);

	GIF *gif_frames  = (GIF*) calloc(1, sizeof(GIF));
	gif_frames->size = frame_count;
	gif_frames->arr  = (Frame*) calloc(frame_count, sizeof(Frame));

	for (int i = 0; i < frame_count; i++) {
		sf::Image image = sf::Image();
		image.create(hor_size, vert_size, (const sf::Uint8*) gif_arr + arr_step * i);

		sf::Texture img_texture = sf::Texture();
		img_texture.loadFromImage(image);

		gif_frames->arr[i].frame = img_texture;
		gif_frames->arr[i].delay = delay_list[i];
	}

	fclose(gif_orig);
	free(gif_arr);
	return gif_frames;
}
