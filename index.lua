-- tetrinomi for vita, by svennd
-- version 0.5

-- vita constants
DISPLAY_WIDTH = 960
DISPLAY_HEIGHT = 544

-- application variables
VERSION = "0.5"

-- screen bg
background = Graphics.loadImage("app0:/assets/background.png")
battery_icon = Graphics.loadImage("app0:/assets/power.png")
control = Graphics.loadImage("app0:/assets/control.png")

-- font
main_font = Font.load("app0:/assets/xolonium.ttf")

-- sound
-- this seems to be required outside to load the pieces
Sound.init()

-- load sound
snd_background = Sound.openMp3("app0:/assets/bg.mp3")
snd_gameover = Sound.openWav("app0:/assets/game_over.wav")
snd_highscore = Sound.openWav("app0:/assets/new_highscore.wav")

-- game constants
BUTTON = { CROSS = 1, CIRCLE = 2, TRIANGLE = 3, SQUARE = 4, LTRIGGER = 5, RTRIGGER = 6, LEFT = 7, RIGHT = 8, UP = 9, DOWN = 10, ANALOG = 11, START = 12, SELECT = 13 }
DIR = { UP = 1, RIGHT = 2, DOWN = 3, LEFT = 4, MIN = 1, MAX = 4 } -- tetronimo direction
STATE = {INIT = 1, PLAY = 2, DEAD = 3} -- game state
MIN_INPUT_DELAY = 50 -- mimimun delay between 2 keys are considered pressed in ms
SIZE = { X = 25, Y = 25, HEIGHT_FIELD = 19, WIDTH_FIELD = 10, COURT_OFFSET_X = 250, COURT_OFFSET_Y = 5, NEXT_OFFSET_X = 570, NEXT_OFFSET_Y = 40 } -- size in px
MIN_INPUT_DELAY = 100
ANIMATION_STEP = 30

-- color definitions
local white 	= Color.new(255, 255, 255)
local black 	= Color.new(0, 0, 0)

local yellow 	= Color.new(255, 255, 0)
local red 		= Color.new(255, 0, 0)
local green 	= Color.new(0, 255, 0)
local blue 		= Color.new(0, 0, 255)

local pink 		= Color.new(255, 204, 204)
local orange	= Color.new(255, 128, 0)
local seablue	= Color.new(0, 255, 255)
local purple	= Color.new(255, 0, 255)

local grey_1	= Color.new(244, 244, 244)
local grey_2	= Color.new(160, 160, 160)
local grey_3	= Color.new(96, 96, 96)

-- initialize variables
actions = {} -- table with all user input
pieces = {} -- fill all the blocks in this
game = {start = Timer.new(), last_tick = 0, state = STATE.INIT}
step = 500 -- each step the block drops, will become a more important variable once we start using levels/lines
current = {piece = {}, x = 0, y = 0, dir = DIR.UP, highscore = 0 } -- current active piece
next_piece = {piece = {}, dir = DIR.UP } -- upcoming piece
field = {} -- playing field table
oldpad = SCE_CTRL_CROSS -- user input init
last_user_tick = 0
score = 0
vscore = 0 -- visual score
line_count = 0
double_down_speed = 0
new_highscore_flag = false
draw_new_version = false
lremove = {line = {}, position = {}}
animation = {state = false, last_tick = 0}

-- pieces
i = { BLOCK = {0x0F00, 0x2222, 0x00F0, 0x4444}, COLOR = yellow }
j = { BLOCK = {0x44C0, 0x8E00, 0x6440, 0x0E20}, COLOR = red }
l = { BLOCK = {0x4460, 0x0E80, 0xC440, 0x2E00}, COLOR = green }
o = { BLOCK = {0xCC00, 0xCC00, 0xCC00, 0xCC00}, COLOR = orange }
s = { BLOCK = {0x06C0, 0x8C40, 0x6C00, 0x4620}, COLOR = blue }
t = { BLOCK = {0x0E40, 0x4C40, 0x4E00, 0x4640}, COLOR = seablue }
z = { BLOCK = {0x0C60, 0x4C80, 0xC600, 0x2640}, COLOR = purple }
k = { BLOCK = {}, COLOR = white }

-- game mechanincs

-- main game mechanics update
function update ()
	
	-- check if we are playing
	if game.state ~= STATE.PLAY then
	    
	    -- update the score to reflect the reall score after game over
	    if game.state == STATE.DEAD then
	        vscore = score
	    end
	    
	    -- stop doing the game mechanics if no play
		return true
	end
	
	local time_played = Timer.getTime(game.start)
	local dt = 0
	local dt_animation = 0
	local current_action = table.remove(actions, 1) -- get the first action
	
	-- handle of the actions
	if current_action == DIR.UP then
		rotate()
	elseif current_action == DIR.DOWN then
		drop()
	elseif current_action == DIR.LEFT then
		move(DIR.LEFT)
	elseif current_action == DIR.RIGHT then
		move(DIR.RIGHT)
	end
	
	-- tick score
	if score > vscore then
		vscore = vscore + 1
	end
	
	-- tick if deltaT > step
	dt = time_played - game.last_tick
		
	-- if double speed is activated drop extra every step/2
	if double_down_speed == 1 then
		if dt > math.floor(step/2) then
			drop()
		end
	end
	
	-- normal speed drop
	if dt > step then
		-- drop block and update last tick
		game.last_tick = time_played
		
		-- if animation is running don't drop
		if not animation.state then
			drop()
		end
	end

	dt_animation = time_played - animation.last_tick
	if dt_animation > ANIMATION_STEP then
		-- drop block and update last tick
		animation.last_tick = time_played
		animate_remove_line()
	end
	
	-- increase speed based on lines
	increase_speed()
end

-- increase speed based on lines
function increase_speed()
	step = 500 - (line_count*5)
	if step < 30 then
		step = 30
	end
end

-- set upcoming piece and start rotation
function set_next_piece()
	next_piece.piece = random_piece()
	next_piece.dir = math.random(DIR.MIN, DIR.MAX)
end

-- current = {piece = {}, x = 0, y = 0, dir = DIR.UP }
function set_current_piece()
	current.piece = next_piece.piece
	-- randomize entry point
	-- 4 : 4x4 size for blocks
	current.x = math.random(0, SIZE.WIDTH_FIELD - 4)
	current.y = 0
	current.dir = next_piece.dir
end

-- set block
function set_block(x, y, block)
	if field[x] then
		field[x][y] = block
	else
		field[x] = {}
		field[x][y] = block
	end
end

-- get block
function get_block(x, y)
	if field[x] then
		return field[x][y]
	else
		return false
	end
end

-- clear everything
function clear_field()
	field = {}
end

-- check if a piece can fit into a position in the grid
function occupied(piece, x_arg, y_arg, dir)
	local row = 0
	local col = 0
	local x = 0
	local y = 0

	-- for each block in the piece
	local bitx = 0x8000
	while bitx > 0 do
		-- in every position where there is a block in our 8x8
		if bit.band(piece.BLOCK[dir], bitx) > 0 then
			-- determ new position
			x = x_arg + col
			y = y_arg + row
			
			-- in case our x would be out of bounds
			if x < 0 or x > SIZE.WIDTH_FIELD then
				return true
			end
			
			-- in case our y would be out of bounds
			if y < 0 or y > SIZE.HEIGHT_FIELD then
				return true
			end
			
			-- in case there is already a block
			if get_block(x, y) then
				return true
			end
		end
		
		col = col + 1
		if col == 4 then
			col = 0
			row = row + 1
		end
		
		-- shift it
		bitx = bit.rshift(bitx, 1)
	end
	
	-- its not occupied
	return false
end

-- rotate a block
function rotate ()

	local new_dir
	-- take the next rotation, or first at the end
	if current.dir == DIR.MAX then
		new_dir = DIR.MIN
	else
		new_dir = current.dir + 1
	end
	
	-- verify that this rotation is possible
	if not occupied(current.piece, current.x, current.y, new_dir) then
		current.dir = new_dir
	end
end

-- move current piece in certain direction
function move(dir)
	local x = current.x
	local y = current.y
	
	if dir == DIR.RIGHT then
		x = x + 1
	elseif dir == DIR.LEFT then
		x = x - 1
	elseif dir == DIR.DOWN then
		y = y + 1
	end
	
	-- check if move is possible
	if not occupied(current.piece, x, y, current.dir) then
		current.x = x
		current.y = y
	else
		-- if not return failed move
		return false
	end
	
	-- move executed
	return true
end

-- pseudo random that is usefull for tetris
function random_piece()

	-- no more pieces left
	if table.getn(pieces) == 0 then
		-- all the pieces in 4 states (note: the state is not defined)
		pieces = {i,i,i,i,j,j,j,j,l,l,l,l,o,o,o,o,s,s,s,s,t,t,t,t,z,z,z,z}
		
		-- shuffle them, http://gamebuildingtools.com/using-lua/shuffle-table-lua
		-- might require a better implementation
		local n = table.getn(pieces)
		while n > 2 do
			local k = math.random(n) -- get a random number
			pieces[n], pieces[k] = pieces[k], pieces[n]
			n = n - 1
		end
	end
	
	return table.remove(pieces) -- remove and return piece
end

-- attempt to drop the current piece
function drop()
	-- if its not possible to move the piece down
	if not move(DIR.DOWN) then
		drop_pieces() -- split it
		remove_lines() -- find full lines
		set_current_piece() -- set next piece as current
		set_next_piece() -- determ a new piece
		add_score(10) -- add 10 points for dropping a piece
		
		-- if not possible to find a spot for its current location its overwritten = dead
		if occupied(current.piece, current.x, current.y, current.dir) then
			-- lose()
			-- store highscore if needed
			local is_new_high_score = new_highscore(score)
			game.state = STATE.DEAD
			sound_game_over(is_new_high_score)
		end
		
		-- cant move further so disable doube speed
		double_down_speed = 0
	end
end

-- go through the field to find full lines
function remove_lines()
	local x = 0
	local y = 0
	local multi_line = 0
	local full_line = true
	local already_have_line = false
	
	for y = 0, SIZE.HEIGHT_FIELD, y + 1 do
	
		-- verify if we did not already have this line
		for k, v in ipairs(lremove.line) do
			if v == y then
				already_have_line = true
				break
			end
		end
		
		-- be sure we did not already count this line
		-- happens during animation
		if not already_have_line then
		
			-- check if this line is full
			full_line = true
			for x = 0, SIZE.WIDTH_FIELD, x + 1 do
				-- search for a empty spot
				if not get_block(x, y) then
					full_line = false
					break
				end
			end
			
			-- if a full line remove it
			if full_line then

				table.insert(lremove.line, y)
				table.insert(lremove.position, 0)
				
				-- if its not the first line double score !
				if (multi_line > 0) then
					add_score( 100 * ( multi_line + 1 ) )
				else
					add_score( 100 ) -- scored a line :D
					multi_line = multi_line + 1
				end
					add_line(1)
			end
		end
		
		-- reset known line
		already_have_line = false
	end
end

-- animate remove line
function animate_remove_line()

	local count_lremove = #lremove.line
	
	-- check if we need an animation
	if count_lremove > 0 then	
		animation.state = true
	else
		animation.state = false	
	end

	-- start animation
	local x = 0
	local i = 0
	
	-- left to right,
	for x = 0, SIZE.WIDTH_FIELD, x + 1 do
	
		while i < count_lremove do
		
			-- get last
			line = lremove.line[i+1]
			position = lremove.position[i+1]
			
			if position > (SIZE.WIDTH_FIELD + 1) then
			
				-- delete from list
				lremove.line[i+1] = nil
				lremove.position[i+1] = nil
				
				-- remove line
				remove_line(line)
			else 
				-- set block
				set_block(position, line, k) -- k = special white
				
				-- update state
				lremove.position[i+1] = position + 1
			end
			i = i + 1
		end
	end	
end

-- remove a single line and drop the above
function remove_line(line)

	local x = 0
	local y = 0
	local type_block = {}
	
	-- start from line, and work the way up
	for y = line, 0, y - 1 do
		for x = 0, SIZE.WIDTH_FIELD, x + 1 do
			if y == 0 then
				type_block = nil
			else
				type_block = get_block(x, y-1)
			end
			set_block(x, y, type_block)
		end
	end
end

-- drop the piece into blocks in field table
function drop_pieces()
	local row = 0
	local col = 0
	local x = 0
	local y = 0

	-- for each block in the piece
	-- bit
	local bitx = 0x8000
	-- local i = 0
	while bitx > 0 do
		-- in every position where there is a block in our 8x8
		if bit.band(current.piece.BLOCK[current.dir], bitx) > 0 then
			
			-- current end position
			x = current.x + col
			y = current.y + row
			
			set_block(x, y, current.piece)
		end
		
		col = col + 1
		if col == 4 then
			col = 0
			row = row + 1
		end
		
		-- shift it
		bitx = bit.rshift(bitx, 1)
	end
end

-- add score line
function add_score(n)
	score = score + n
end

-- add line score
function add_line(n)
	line_count = line_count + n
end

-- start the game
function game_start()
	-- reset the score
	score = 0
	vscore = 0
	line_count = 0
	new_highscore_flag = false
	
	-- clear field
	clear_field()
	
	-- set up next and current piece
	set_next_piece() -- determ next piece
	set_current_piece() -- set next piece as current piece
	set_next_piece() -- pull the next piece

	-- reset start timer
	Timer.reset(game.start)
	
	-- reset ticks
	game.last_tick = 0 -- drop ticks
	last_user_tick = 0 -- user input
	
	-- set state to playing
	game.state = STATE.PLAY
	
	-- set current highscore
	current.highscore = get_high_score()
	
	-- start the sound
	sound_background()
end

-- get the highscore from file
function get_high_score()
    
	System.createDirectory("ux0:/data/tetrinomi")
	
    -- check if file exist
	if System.doesFileExist("ux0:/data/tetrinomi/tetris_score") then
	    
	    -- open file
		local score_file = System.openFile("ux0:/data/tetrinomi/tetris_score", FREAD)
		
		-- read content
		local highscore = System.readFile(score_file, System.sizeFile(score_file))
		
		-- close file again
		System.closeFile(score_file)
		
		-- cast to number
		highscore = tonumber(highscore)
		
		-- verify if its a sane number
		if highscore == nil then
			return 0
		end
		
		return highscore
		
	else
	    return 0
	end
end

-- check if its a new highscore
function new_highscore(score)
	
	local highscore = get_high_score()
	
    -- current score is higher or equal
	if highscore >= score then
		return false
	else
		-- its a higher score
		new_highscore_flag = true
		current.highscore = score
		
		if System.doesFileExist("ux0:/data/tetrinomi/tetris_score") then
			System.deleteFile("ux0:/data/tetrinomi/tetris_score")
		end
		return true
	end
	
	-- create it a new highscore file
	local new_score_file = System.openFile("ux0:/data/tetrinomi/tetris_score", FCREATE)
	System.writeFile(new_score_file, score, string.len(score))
	System.closeFile(new_score_file)
end

-- drawing

-- main drawing function
function draw_frame()

	-- Starting drawing phase
	Graphics.initBlend()
	
	-- background
	Graphics.fillRect(0, DISPLAY_WIDTH, 0, DISPLAY_HEIGHT, black)
	
	-- background image
	Graphics.drawImage(0,0, background)
	
	-- temp
	if game.state == STATE.DEAD then
		Font.setPixelSizes(main_font, 25)
	
		Font.print(main_font, 570, 180, "GAME OVER", white)
		if new_highscore_flag then
			Font.print(main_font, 570, 220, "! NEW HIGHSCORE !", white)
		end
	end
	
	-- draw court
	draw_court()
	
	-- draw piece playing with
	draw_current()
	
	-- draw upcomming piece
	draw_next()
	
	-- score
	draw_score()
	
	-- draw battery info
	draw_battery()
	
	-- show help
	draw_show_help()
	
	-- in case a new version is there
	if draw_new_version then
		new_version()
	end
	
	-- Terminating drawing phase
	Graphics.termBlend()
	Screen.flip()
end

-- draw current block
function draw_current ()
	local row = 0
	local col = 0
	
	-- 8x8
	local bitx = 0x8000
	while bitx > 0 do
		
		-- if current.piece bit is set are draw block
		if bit.band(current.piece.BLOCK[current.dir], bitx) > 0 then
			draw_block((current.x + col), (current.y + row), current.piece.COLOR)
		end
		
		col = col + 1
		if col == 4 then
			col = 0
			row = row + 1
		end
		
		-- shift it
		bitx = bit.rshift(bitx, 1)
	end
end

-- draw the play field
function draw_court()

	-- draw background frame
	Graphics.fillRect(
		SIZE.COURT_OFFSET_X,
		SIZE.COURT_OFFSET_X + ( (SIZE.WIDTH_FIELD + 1) * SIZE.X) + SIZE.WIDTH_FIELD,
		SIZE.COURT_OFFSET_Y,
		SIZE.COURT_OFFSET_Y + ( (SIZE.HEIGHT_FIELD + 1) * SIZE.Y) + SIZE.HEIGHT_FIELD,
		black)
	
	-- draw blocks
	local x = 0
	local y = 0
	
	for y = 0, SIZE.HEIGHT_FIELD, y + 1 do
		for x = 0, SIZE.WIDTH_FIELD, x + 1 do
			if get_block(x, y) then
				local block = get_block(x, y)
				draw_block( x, y, block.COLOR)
			else
				draw_block( x, y, grey_3)
			end
		end
	end
	
end

-- draw a single block
function draw_block(x, y, color)

	Graphics.fillRect(
		SIZE.COURT_OFFSET_X+(x*SIZE.X) + x,
		SIZE.COURT_OFFSET_X+((x+1)*SIZE.X) + x,
		SIZE.COURT_OFFSET_Y+(y*SIZE.Y) + y,
		SIZE.COURT_OFFSET_Y+((y+1)*SIZE.Y) + y,
		color)
end

-- draw score
function draw_score()
	local margin = 15
	
	-- increase draw size
	Font.setPixelSizes(main_font, 30)
	
	-- high_score
	Font.print(main_font, 15, 20, "HIGHSCORE", white)
	Font.print(main_font, 15, 80, current.highscore, white)
	draw_box(5, 220, 10, 120, 3, white)
	
	-- score
	Font.print(main_font, 97, 140, "SCORE", white)
	Font.print(main_font, 15, 200, vscore, white)
	draw_box(5, 220, 130, 240, 3, grey_3)

	-- lines
	Font.print(main_font, 105, 260, "LINES" , white)
	Font.print(main_font, 15, 320, line_count , white)
	draw_box(5, 220, 250, 360, 3, grey_3)
	
	-- speed
	local level = 0
	if step < 450 and step > 400 then
		level = 1
	elseif step < 400 and step > 350 then
		level = 2
	elseif step < 350 and step > 300 then
		level = 3
	elseif step < 300 and step > 250 then
		level = 4
	elseif step < 250 and step > 200 then
		level = 5
	elseif step < 200 and step > 150 then
		level = 6
	elseif step < 150 and step > 100 then
		level = 7
	elseif step < 100 and step > 50 then
		level = 8
	elseif step < 50 then
		level = 9
	end
	
	Font.print(main_font, 105, 380, "LEVEL" , white)
	Font.print(main_font, 15, 440, level , white)
	draw_box(5, 220, 370, 480, 3, grey_3)
	
end

-- draw next block
function draw_next()
	local x = 0
	local y = 0
	local margin = 15 -- margin around next box
	
	-- 8x8
	local bitx = 0x8000
	while bitx > 0 do
		
		-- if current.piece bit is set are draw block
		if bit.band(next_piece.piece.BLOCK[next_piece.dir], bitx) > 0 then
			-- draw_block uses SIZE.COURT_OFFSET by default
			Graphics.fillRect(
					SIZE.NEXT_OFFSET_X + (x*SIZE.X) + x,
					SIZE.NEXT_OFFSET_X + ((x+1)*SIZE.X) + x,
					SIZE.NEXT_OFFSET_Y + (y*SIZE.Y) + y,
					SIZE.NEXT_OFFSET_Y + ((y+1)*SIZE.Y) + y,
					next_piece.piece.COLOR)
		end
		
		x = x + 1
		if x == 4 then
			x = 0
			y = y + 1
		end
		
		-- shift it
		bitx = bit.rshift(bitx, 1)
	end
	
	-- draw frame around
	draw_box(
			SIZE.NEXT_OFFSET_X - margin,
			SIZE.NEXT_OFFSET_X+(4*SIZE.X) + margin,
			SIZE.NEXT_OFFSET_Y - margin,
			SIZE.NEXT_OFFSET_Y+(4*SIZE.Y) + margin,
			3,
			red)
			
	-- text
	Font.setPixelSizes(main_font, 25)
	Font.print(main_font, SIZE.NEXT_OFFSET_X-margin, SIZE.NEXT_OFFSET_Y-(margin*3), "upcoming" , white)
end

-- draw battery
function draw_battery()
    local margin = 60
	local y_offset = 5
    local life = System.getBatteryPercentage()
	
	-- icon
	-- ok
	if life > 70 then
		Graphics.drawPartialImage(DISPLAY_WIDTH - margin, y_offset, battery_icon, 0, 0, 50, 25)
	elseif life > 50 then
		Graphics.drawPartialImage(DISPLAY_WIDTH - margin, y_offset, battery_icon, 0, 26, 50, 25)
	elseif life > 30 then
		Graphics.drawPartialImage(DISPLAY_WIDTH - margin, y_offset, battery_icon, 0, 53, 50, 25)
	elseif life > 10 then
		Graphics.drawPartialImage(DISPLAY_WIDTH - margin, y_offset, battery_icon, 0, 78, 50, 25)
	end

	-- decrease font size
	Font.setPixelSizes(main_font, 16)
	Font.print(main_font, DISPLAY_WIDTH - margin - 45, y_offset, life .. "%", white)
end

-- draw a box
-- untill fillEmptyRect is fixed
function draw_box(x1, x2, y1, y2, width, color)

	-- top line
	Graphics.fillRect(x1, x2+width, y1, y1+width, color)
	
	-- bot line
	Graphics.fillRect(x1, x2+width, y2, y2+width, color)
	
	-- left line
	Graphics.fillRect(x1, x1+width, y1, y2, color)
	
	-- right line
	Graphics.fillRect(x2, x2+width, y1, y2, color)
	
end

-- new version available
function new_version()
	Font.setPixelSizes(main_font, 20)
	Font.print(main_font, 800, 300, "New version available", red)
end

-- help
function draw_show_help()

	Font.setPixelSizes(main_font, 16)
	draw_control(760, 400, BUTTON.START)
	Font.print(main_font, 850, 410, "PLAY", white)
	
	draw_control(760, 440, BUTTON.SELECT)
	Font.print(main_font, 850, 450, "EXIT", white)
	-- Font.print(main_font, 800, 390, "< left right >", white)
	-- Font.print(main_font, 800, 410, "UP/X rotate", white)
	-- Font.print(main_font, 800, 430, "O drop", white)
end

-- generic function to draw control
function draw_control(x, y, button_request)

	if button_request == BUTTON.TRIANGLE then
		Graphics.drawPartialImage(x, y, control, 5, 2, 50, 50)
		
	elseif button_request == BUTTON.CIRCLE then
		Graphics.drawPartialImage(x, y, control, 60, 2, 50, 50)
		
	elseif button_request == BUTTON.CROSS then
		Graphics.drawPartialImage(x, y, control, 115, 2, 50, 50)
		
	elseif button_request == BUTTON.SQUARE then
		Graphics.drawPartialImage(x, y, control, 170, 2, 50, 50)
		
	elseif button_request == BUTTON.LTRIGGER then
		Graphics.drawPartialImage(x, y, control, 0, 56, 80, 34)
		
	elseif button_request == BUTTON.RTRIGGER then
		Graphics.drawPartialImage(x, y, control, 232, 8, 80, 34)
		
	elseif button_request == BUTTON.LEFT then
		Graphics.drawPartialImage(x, y, control, 197, 54, 60, 45)
		
	elseif button_request == BUTTON.RIGHT then
		Graphics.drawPartialImage(x, y, control, 260, 54, 60, 45)
		
	elseif button_request == BUTTON.UP then
		Graphics.drawPartialImage(x, y, control, 97, 59, 40, 54)
		
	elseif button_request == BUTTON.DOWN then
		Graphics.drawPartialImage(x, y, control, 150, 62, 40, 54)
		
	elseif button_request == BUTTON.ANALOG then
		Graphics.drawPartialImage(x, y, control, 34, 100, 58, 58)
	
	elseif button_request == BUTTON.START then
		Graphics.drawPartialImage(x, y, control, 222, 102, 79, 40)
		
	elseif button_request == BUTTON.SELECT then
		Graphics.drawPartialImage(x, y, control, 105, 119, 79, 40)
	end

end


-- user_input

-- work through user input
function user_input()
	
	-- get time played
	local time_played = Timer.getTime(game.start)
	
	-- last valid input
	local last_input = time_played - last_user_tick

	-- input data
	local pad = Controls.read()
	
	-- add the action to first
	if Controls.check(pad, SCE_CTRL_UP) and not Controls.check(oldpad, SCE_CTRL_UP) then
		table.insert(actions, DIR.UP)
		
	-- sticky key support
	elseif Controls.check(pad, SCE_CTRL_DOWN) and last_input > MIN_INPUT_DELAY then
		table.insert(actions, DIR.DOWN)
		last_user_tick = time_played
		
	-- sticky key support
	elseif Controls.check(pad, SCE_CTRL_LEFT) and last_input > MIN_INPUT_DELAY then
		table.insert(actions, DIR.LEFT)
		last_user_tick = time_played
		
	elseif Controls.check(pad, SCE_CTRL_LTRIGGER) and not Controls.check(oldpad, SCE_CTRL_LTRIGGER ) then
		table.insert(actions, DIR.LEFT)
		
	-- sticky key support
	elseif Controls.check(pad, SCE_CTRL_RIGHT) and last_input > MIN_INPUT_DELAY then
		table.insert(actions, DIR.RIGHT)
		last_user_tick = time_played
		
	elseif Controls.check(pad, SCE_CTRL_RTRIGGER) and not Controls.check(oldpad, SCE_CTRL_RTRIGGER) then
		table.insert(actions, DIR.RIGHT)
		
	elseif Controls.check(pad, SCE_CTRL_CROSS) and not Controls.check(oldpad, SCE_CTRL_CROSS) then
		table.insert(actions, DIR.UP)

	elseif Controls.check(pad, SCE_CTRL_CIRCLE) and not Controls.check(oldpad, SCE_CTRL_CIRCLE) then
		double_down_speed = 1 -- speed down
		
	elseif Controls.check(pad, SCE_CTRL_START) and not Controls.check(oldpad, SCE_CTRL_START) then
		if game.state == STATE.INIT then
			-- give option to start
		elseif game.state == STATE.PLAY then
			-- pauze ?
		elseif game.state == STATE.DEAD then
			game_start()
		end
	elseif Controls.check(pad, SCE_CTRL_SELECT) then
		clean_exit()
	end
	
	-- pepperidge farm remembers
	oldpad = pad
end


-- sound
function sound_background()
	if not Sound.isPlaying(snd_background) then
		Sound.resume(snd_background)
	end
end

-- game over sound :D
function sound_game_over(new_high_score)
	-- stop background
	if Sound.isPlaying(snd_background) then
		Sound.pause(snd_background)
	end
	
	-- happy or sad noise ?
	if new_high_score then
		Sound.play(snd_highscore, NO_LOOP)
	else
		Sound.play(snd_gameover, NO_LOOP)
	end
end


-- main

-- main function
function main()

	-- start sound
	Sound.play(snd_background, LOOP)
	
	-- initiate game variables
	game_start()
	
	-- verify game version
	-- not functional
	--version_check()
	
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

-- close all resources
-- while not strictly necessary, its clean
function clean_exit()

	-- free images
	Graphics.freeImage(control)
	Graphics.freeImage(battery_icon)
	Graphics.freeImage(background)
	
	-- close music files
	Sound.close(snd_background)
	Sound.close(snd_gameover)
	Sound.close(snd_highscore)
	
	-- unload font
	Font.unload(main_font)
	
	-- stop sound module
	-- bugged ?
	-- Sound.term()
	
	-- kill app
	System.exit()
	
end


-- version check
function version_check()
	-- initialize network
	Network.init()

	-- Checking if connection is available
	if Network.isWifiEnabled() then

		-- sync send a request for the content
		local skt = Socket.connect("raw.githubusercontent.com", 443)
		-- send request
		Socket.send(skt, "GET /svennd/vita-tetromino/master/VERSION.md HTTP/1.1\r\nHost: raw.githubusercontent.com\r\n\r\n")

		-- Since sockets are non blocking, we wait till at least a byte is received
		local raw_data = ""
		while raw_data == "" do
			raw_data = raw_data .. Socket.receive(skt, 8192)
		end

		-- Keep downloading till the whole response is received
		dwnld_data = raw_data
		retry = 0
		while dwnld_data ~= "" or retry < 1000 do
			dwnld_data = Socket.receive(skt, 8192)
			raw_data = raw_data .. dwnld_data
			if dwnld_data == "" then
				retry = retry + 1
			else
				retry = 0
			end
		end
	
		-- Extracting Content-Length value
		offs1, offs2 = string.find(raw_data, "Length: ")
		offs3 = string.find(raw_data, "\r", offs2)
		content_length = tonumber(string.sub(raw_data, offs2, offs3))

		-- getting the version
		stub, content_offset = string.find(raw_data, "\r\n\r\n")
		local uplink_version = string.sub(raw_data, content_offset+1)
		
		if uplink_version == VERSION then
			draw_new_version = true
		end
		
		-- Closing socket
		Socket.close(skt)
		
	end

	-- Terminating network
	Network.term()
end

-- run the code
main()