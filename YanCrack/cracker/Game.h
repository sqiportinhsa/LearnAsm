#pragma once
#include <SFML/Graphics.hpp>

const int MAZE_SIZE = 10;				         // Размер лабиринта в клетках
const int ARRAY_SIZE = MAZE_SIZE * MAZE_SIZE;    // Размер массива клеток
const int SCREEN_SIZE = 600;				     // Размер экрана в пикселях
const int CELL_SIZE  = 50;				         // Размер клетки в пикселях

enum class Direction { Nope = 0, Left = 1, Right = 2, Up = 3, Down = 4 };

struct Frame {
    int delay = 0;
    sf::Texture frame;
};

struct GIF {
    int size = 0;
    Frame *arr = 0;
};

enum class TileType {
    CAT   = -1,
    SPACE = 0,
    WALL  = 1
};

struct Textures {
    sf::Texture wall;
    sf::Texture space;
};

struct Gifs {
    GIF *cat_left;
    GIF *cat_right;
    GIF *cat_up;
    GIF *cat_down1;
    GIF *cat_down2;
    GIF *cat_wait;
    GIF *cat_sleep;
};


struct Game {
    sf::RenderWindow window;
    sf::Sprite  maze[ARRAY_SIZE];
    sf::Sprite  cat;
    size_t      cat_index;
    bool        solved;
    sf::Font    font; 
    Textures    text;
    Gifs        gifs;
};

bool run_game();

const TileType Maze[] = {TileType::SPACE, TileType::SPACE, TileType::SPACE, TileType::SPACE, TileType::SPACE, TileType::SPACE, TileType::SPACE, TileType::SPACE, TileType::SPACE, TileType::SPACE,
                         TileType::SPACE, TileType::SPACE, TileType::SPACE, TileType::SPACE, TileType::SPACE, TileType::SPACE, TileType::SPACE, TileType::SPACE, TileType::SPACE, TileType::SPACE,
                         TileType::SPACE, TileType::SPACE, TileType::SPACE, TileType::SPACE, TileType::SPACE, TileType::SPACE, TileType::SPACE, TileType::SPACE, TileType::SPACE, TileType::SPACE,
                         TileType::SPACE, TileType::SPACE, TileType::SPACE, TileType::SPACE, TileType::SPACE, TileType::SPACE, TileType::SPACE, TileType::SPACE, TileType::SPACE, TileType::SPACE,
                         TileType::SPACE, TileType::SPACE, TileType::SPACE, TileType::SPACE, TileType::SPACE, TileType::SPACE, TileType::SPACE, TileType::SPACE, TileType::SPACE, TileType::SPACE,
                         TileType::SPACE, TileType::SPACE, TileType::SPACE, TileType::SPACE, TileType::SPACE, TileType::SPACE, TileType::SPACE, TileType::SPACE, TileType::SPACE, TileType::SPACE,
                         TileType::SPACE, TileType::SPACE, TileType::SPACE, TileType::SPACE, TileType::SPACE, TileType::SPACE, TileType::SPACE, TileType::SPACE, TileType::SPACE, TileType::SPACE,
                         TileType::SPACE, TileType::SPACE, TileType::SPACE, TileType::SPACE, TileType::SPACE, TileType::SPACE, TileType::SPACE, TileType::SPACE, TileType::SPACE, TileType::SPACE,
                         TileType::SPACE, TileType::SPACE, TileType::SPACE, TileType::SPACE, TileType::SPACE, TileType::SPACE, TileType::SPACE, TileType::SPACE, TileType::SPACE, TileType::SPACE,
                         TileType::SPACE, TileType::SPACE, TileType::SPACE, TileType::SPACE, TileType::SPACE, TileType::SPACE, TileType::SPACE, TileType::SPACE, TileType::SPACE, TileType::SPACE};
