-- tetrinomi for vita, by svennd
-- version 0.4

-- vita constants
DISPLAY_WIDTH = 960
DISPLAY_HEIGHT = 544

-- application variables
VERSION = "0.4"

-- screen bg
background = Graphics.loadImage("app0:/assets/background.png")
battery_icon = Graphics.loadImage("app0:/assets/power.png")

-- font
main_font = Font.load("app0:/assets/xolonium.ttf")

-- game constants
DIR = { UP = 1, RIGHT = 2, DOWN = 3, LEFT = 4, MIN = 1, MAX = 4 } -- tetronimo direction
STATE = {INIT = 1, PLAY = 2, DEAD = 3} -- game state
SIZE = { X = 25, Y = 25, HEIGHT_FIELD = 19, WIDTH_FIELD = 10, COURT_OFFSET_X = 300, COURT_OFFSET_Y = 5, NEXT_OFFSET_X = 180, NEXT_OFFSET_Y = 40 } -- size in px

-- initialize variables
actions = {} -- table with all user input
game = {start = Timer.new(), last_tick = 0, state = STATE.INIT}
current = {piece = {}, x = 0, y = 0, dir = DIR.UP, highscore = 0 } -- current active piece
next_piece = {piece = {}, dir = DIR.UP } -- upcoming piece
field = {} -- playing field table
score = 0 -- reall score
vscore = 0 -- visual score
line_count = 0 -- line count is used in the step calculation
double_down_speed = 0 -- flag drop piece
new_highscore_flag = false -- new high score
draw_new_version = false -- new version polled
menu_point = 0 -- where is the menu marked

-- load functions

-- load draw functions
dofile("app0://draw.lua")

-- load game functions
dofile("app0://tetris.lua")

-- load system functions
dofile("app0://system.lua")

-- main loop
function main()

	-- initiate game variables
	-- game_start()
	
	-- verify game version
	version_check()
	
	-- gameloop
	while true do
		
		-- process user input
		user_input()
		
		-- update game procs
		update()
		
		-- draw game
		draw_frame()
		
		-- wait for black start
		Screen.waitVblankStart()
	end
	
end

-- run the code
main()