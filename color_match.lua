-- classic tetris

-- load images
local img_inteface = Graphics.loadImage("app0:/assets/classic.png")
local img_background = Graphics.loadImage("app0:/assets/bg_menu.png")
local img_battery_icon = Graphics.loadImage("app0:/assets/power.png")
local img_button = Graphics.loadImage("app0:/assets/ingame_button.png")
local img_stats = Graphics.loadImage("app0:/assets/stats.png")

-- font
local main_font = Font.load("app0:/assets/xolonium.ttf")

-- sound
-- this seems to be required outside to load the pieces
Sound.init()

-- load sound
local snd_background = Sound.open("app0:/assets/bg.ogg")
local snd_gameover = Sound.open("app0:/assets/game_over.ogg")
local snd_highscore = Sound.open("app0:/assets/new_highscore.ogg")
local snd_multi_line = Sound.open("app0:/assets/multi_line.ogg")
local snd_single_line = Sound.open("app0:/assets/single_line.ogg")

-- game constants
local DIR = { UP = 1, RIGHT = 2, DOWN = 3, LEFT = 4, MIN = 1, MAX = 4 } -- tetronimo direction
local STATE = {INIT = 1, PLAY = 2, DEAD = 3} -- game state
local MIN_INPUT_DELAY = 50 -- mimimun delay between 2 keys are considered pressed in ms
local SIZE = { X = 25, Y = 25, HEIGHT_FIELD = 19, WIDTH_FIELD = 9, COURT_OFFSET_X = 250, COURT_OFFSET_Y = 5, NEXT_OFFSET_X = 570, NEXT_OFFSET_Y = 40 } -- size in px
local MIN_INPUT_DELAY = 100
local ANIMATION_STEP = 30
local SPEED_LIMIT = 30

-- color definitions
local white 	= Color.new(255, 255, 255)
local black 	= Color.new(0, 0, 0)

local yellow 	= Color.new(255, 255, 0)
local red 		= Color.new(255, 0, 0)
local green 	= Color.new(0, 255, 0)
local blue 		= Color.new(0, 0, 255)

-- local pink 		= Color.new(255, 204, 204)
local orange	= Color.new(255, 128, 0)
-- local seablue	= Color.new(0, 255, 255)
-- local purple	= Color.new(255, 0, 255)

local grey_1	= Color.new(244, 244, 244)
local grey_2	= Color.new(160, 160, 160)
local grey_3	= Color.new(96, 96, 96)

local text_color_score = Color.new(249, 255, 255)

-- initialize variables
local game = {start = Timer.new(), level = 0, last_tick = 0, state = STATE.INIT, step = 500}
local current = {piece = {}, x = 0, y = 0, dir = DIR.UP } -- current active piece
local next_piece = {piece = {}, dir = DIR.UP } -- upcoming piece
local input = {prev = SCE_CTRL_CIRCLE, last_tick = 0, double_down = 0}
local score = {current = 0, visual = 0, high = 0, line = 0, new_high = false}

-- local lremove = {line = {}, position = {}, sound = 0}
local animation = {state = false, last_tick = 0, game_over = 1, game_over_direction = 1, level_up = false, level_up_y = 1}

-- empty var inits
local actions = {} -- table with all user input
local pieces = {} -- fill all the blocks in this
local field = {} -- playing field table

-- pieces
local yellow = { COLOR = yellow }
local red = { COLOR = red }
local blue = { COLOR = blue }
local orange = { COLOR = orange }
local green = { COLOR = green }

-- direction
local STATE = {0x0011, 0x0030, 0x0022, 0x0003}

-- killswitch for this file
local break_loop = false

-- game mechanincs

-- main game mechanics update
function update()
	
	-- check if we are playing
	if game.state ~= STATE.PLAY then
	    
	    -- update the score to reflect the reall score after game over
	    if game.state == STATE.DEAD then
	        score.visual = score.current
	    end
		
		if game.state == STATE.DEAD then
			if 70 < animation.game_over then
				animation.game_over_direction = -1
			elseif animation.game_over < 1 then
				animation.game_over_direction = 1
			
			end
			animation.game_over = animation.game_over + animation.game_over_direction
		end
	    
	    -- stop doing the game mechanics if no play
		return true
	end
	
	local time_played = Timer.getTime(game.start)
	local dt_game = time_played - game.last_tick
	local dt_animation = time_played - animation.last_tick
	
	-- handle of the actions
	handle_input()

	-- tick score
	if score.current > score.visual then
		score.visual = score.visual + 1
	end
	
	-- if double speed is activated drop extra every step/2
	if input.double_down == 1 then
		if dt_game > math.floor(game.step/2) then
			drop()
		end
	end
	
	-- normal speed drop
	if dt_game > game.step then
		-- drop block and update last tick
		game.last_tick = time_played
		
		-- try to drop it
		drop()
		
	end

	if dt_animation > ANIMATION_STEP then
		-- drop block and update last tick
		animation.last_tick = time_played
		-- animate_remove_line()
	end
	
	if animation.level_up then
		if animation.level_up_y > 150 then
			animation.level_up = false
			animation.level_up_y = 0
		else
			animation.level_up_y = animation.level_up_y + 1
		end
	end
end

-- handle user input to actions
function handle_input()

	local current_action = table.remove(actions, 1) -- get the first action
	if current_action == DIR.UP then
		-- rotate a block
		local function rotate ()

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
		rotate()
	elseif current_action == DIR.DOWN then
		drop()
	elseif current_action == DIR.LEFT then
		move(DIR.LEFT)
	elseif current_action == DIR.RIGHT then
		move(DIR.RIGHT)
	end
end
	
-- increase speed based on lines
function increase_speed()

	game.step = 500 - (score.line*5)
	if game.step < SPEED_LIMIT then
		game.step = SPEED_LIMIT
	end
end

-- set upcoming piece and start rotation
function set_next_piece()
	next_piece.piece = random_piece()
	next_piece.dir = math.random(DIR.MIN, DIR.MAX)
end

function set_current_piece()
	current.piece = next_piece.piece
	-- randomize entry point
	-- 4 : 4x4 size for blocks
	current.x = math.random(0, SIZE.WIDTH_FIELD - 4)
	current.y = 0
	current.dir = next_piece.dir
	
	-- for statics if we get here we assume its played
	-- if stats_played_pieces[current.piece.ID] == nil then
		-- stats_played_pieces[current.piece.ID] = 1
	-- else
		-- stats_played_pieces[current.piece.ID] = stats_played_pieces[current.piece.ID] + 1
	-- end
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

-- check if a piece can fit into a position in the grid
function occupied(piece, x_arg, y_arg, dir)
	local row = 0
	local col = 0
	local x = 0
	local y = 0

	-- for each block in the piece
	local bitx = 0x0040
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
		pieces = {yellow, red, blue, orange, green, yellow, red, blue, orange, green, yellow, red, blue, orange, green, yellow, red, blue, orange, green}
		
		-- shuffle them, http://gamebuildingtools.com/using-lua/shuffle-table-lua
		-- might require a better implementation
		math.randomseed(os.clock()*1000) -- os.time() is to easy
		local n = table.getn(pieces)
		while n > 2 do
			local k = math.random(n) -- get a random number
			pieces[n], pieces[k] = pieces[k], pieces[n]
			n = n - 1
		end
	end
	
	-- return block
	local block = {top = table.remove(pieces), bot = table.remove(pieces)}
	
	return block
end

-- attempt to drop the current piece
function drop()
	
	-- during animations don't drop new blocks
	if animation.state then
		return false
	end
	
	-- if its not possible to move the piece down
	if not move(DIR.DOWN) then
		drop_pieces() -- split it
		--remove_lines() -- find full lines
		set_current_piece() -- set next piece as current
		set_next_piece() -- determ a new piece
		add_score(10) -- add 10 points for dropping a piece
		increase_speed() -- increase speed based on lines
		set_level() -- set level 
		-- if not possible to find a spot for its current location its overwritten = dead
		if occupied(current.piece, current.x, current.y, current.dir) then
			-- lose()
			-- store highscore if needed
			local is_new_high_score = new_highscore()
			game.state = STATE.DEAD
			sound_game_over(is_new_high_score)
		end
		
		-- cant move further so disable doube speed
		input.double_down = 0
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
				lremove.sound = true -- play sound
				
				-- if its not the first line double score !
				if (multi_line > 0) then
					
					add_score( 100 * ( multi_line + 1 ) )
					multi_line = multi_line + 1
					
					-- stats (its a double)
					if multi_line == 2 then
						-- remove the single we just counted
						stats_lines.single = stats_lines.single - 1
						stats_lines.double = stats_lines.double + 1
					-- its a triple
					elseif multi_line == 3 then
						-- remove the double we just counted
						stats_lines.double = stats_lines.double - 1
						stats_lines.triple = stats_lines.triple + 1
					-- TETRO !!!!
					elseif multi_line == 4 then
						-- remove the triple we just counted
						stats_lines.triple = stats_lines.triple - 1
						stats_lines.tetro = stats_lines.tetro + 1
					end
				else
					add_score( 100 ) -- scored a line :D
					multi_line = multi_line + 1
					stats_lines.single = stats_lines.single + 1
				end
				
				-- add line score
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

	-- let's make some noise !
	if lremove.sound then
		if count_lremove > 1 then
			Sound.play(snd_multi_line, NO_LOOP)
		else
			Sound.play(snd_single_line, NO_LOOP)
		end
		lremove.sound = false
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
	local bitx = 0x040
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
	score.current = score.current + n
end

-- add line score
function add_line(n)
	score.line = score.line + n
end

-- start the game
function game_start()
	
	-- try to clean bad data ?
	collectgarbage()

	-- reset the score
	score.current = 0
	score.visual = 0
	score.line = 0
	score.new_high = false
	
	-- clear field
	field = {}
	
	-- just in case
	animation.last_tick = 0
	lremove.line = {}
	lremove.position = {}
	lremove.sound = 0
	pieces = {}
	
	-- set up next and current piece
	set_next_piece() -- determ next piece
	set_current_piece() -- set next piece as current piece
	set_next_piece() -- pull the next piece

	-- reset input
	actions = {}
	input.last_tick = 0	-- user input
	input.double_down = 0
	
	-- reset game state
	game.step = 500
	game.level = 0 -- bound to step
	game.last_tick = 0 -- drop ticks
	game.state = STATE.PLAY
	Timer.reset(game.start) -- restart game timer
	
	-- clear stats
	stats_played_pieces = {0, 0, 0, 0, 0, 0, 0} -- nil might be issue
	stats_lines = {single = 0, double = 0, triple = 0, tetro = 0}
	
	-- start the sound
	sound_background()
end

-- get the highscore from file
function get_high_score()

	-- check if it does not exist and create it when needed
	if not System.doesDirExist("ux0:/data/tetrinomi") then
		System.createDirectory("ux0:/data/tetrinomi")
	end
	
    -- check if file exist
	if System.doesFileExist("ux0:/data/tetrinomi/tetris_score") then
	    
	    -- open file
		score_file = System.openFile("ux0:/data/tetrinomi/tetris_score", FREAD)
		
		-- read content
		local highscore = System.readFile(score_file, System.sizeFile(score_file))
		
		-- close file again
		System.closeFile(score_file)
		
		-- cast to number
		highscore = tonumber(highscore)
		
		-- verify if its a sane number
		if highscore == nil then
			return 999
		end
		
		-- put it into score field
		score.high = highscore
		
		return highscore
		
	else
	    return 0
	end
end

-- check if its a new highscore
function new_highscore()
		
    -- current score is higher or equal
	if score.high >= score.current then
		return false
	else
		-- its a higher score
		score.new_high = true
		score.high = score.current
		
		if System.doesFileExist("ux0:/data/tetrinomi/tetris_score") then
			System.deleteFile("ux0:/data/tetrinomi/tetris_score")
		end
	end
	
	-- create it a new highscore file
	new_score_file = System.openFile("ux0:/data/tetrinomi/tetris_score", FCREATE)
	System.writeFile(new_score_file, score.current, string.len(score.current))
	System.closeFile(new_score_file)
	
	return true
end

-- drawing

-- main drawing function
function draw_frame()

	-- Starting drawing phase
	Graphics.initBlend()
	
	-- background image
	Graphics.drawImage(0, 0, img_background)
	Graphics.drawImage(5, 10, img_inteface)
	
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
	
	-- level up :D
	draw_level_up()
	
	-- game over
	if game.state == STATE.DEAD then
		draw_game_over()
	end
	
	-- Terminating drawing phase
	Graphics.termBlend()
	Screen.flip()
end

function draw_game_over()
	Font.setPixelSizes(main_font, 35)

	Font.print(main_font, 270, 180, "GAME OVER", Color.new(255,255,255, 180 + math.floor(animation.game_over)))
	
	-- new high score ?
	if score.new_high then
		Font.setPixelSizes(main_font, 25)
		Font.print(main_font, 570, 220, "! NEW HIGHSCORE !", white)
	end
	
	-- post game stats
	Font.setPixelSizes(main_font, 20)
	Font.print(main_font, 570, 260, "single : x".. stats_lines.single, white)
	Font.print(main_font, 570, 290, "double : x".. stats_lines.double, white)
	Font.print(main_font, 570, 320, "triple : x".. stats_lines.triple, white)
	Font.print(main_font, 570, 350, "tetro : x".. stats_lines.tetro, white)
	Font.print(main_font, 570, 380, "total : ".. score.line .. " lines", white)
	
	-- could be cleaner
	Font.setPixelSizes(main_font, 20)
	
	Graphics.drawImage(786, 204, img_stats)
	Font.print(main_font, 894, 215, "x".. stats_played_pieces[1], white)
	Font.print(main_font, 894, 265, "x".. stats_played_pieces[2], white)
	Font.print(main_font, 894, 315, "x".. stats_played_pieces[3], white) -- square
	Font.print(main_font, 894, 360, "x".. stats_played_pieces[4], white) -- 4long
	Font.print(main_font, 894, 400, "x".. stats_played_pieces[5], white)
	Font.print(main_font, 894, 450, "x".. stats_played_pieces[6], white)
	Font.print(main_font, 894, 500, "x".. stats_played_pieces[7], white)
	
	-- buttons to restart or exit
	Font.setPixelSizes(main_font, 25)
	
	Graphics.drawImage(733, 37, img_button)
	Font.print(main_font, 758, 51, "NEW GAME", white)
	
	Graphics.drawImage(733, 101, img_button)
	Font.print(main_font, 758, 115, "  EXIT  ", white)
end

-- draw current block
function draw_current ()
	local row = 0
	local col = 0
	
	-- 8x8
	local bitx = 0x0040
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
	Font.setPixelSizes(main_font, 32)
	
	-- score
	Font.print(main_font, 25, 25, score.visual, text_color_score)

	-- best
	Font.print(main_font, 565, 185, score.high, text_color_score)
	
	-- level
	Font.setPixelSizes(main_font, 16)
	Font.print(main_font, 15, 85, "LEVEL " .. game.level, text_color_score)
	
end

function set_level()
	-- speed
	local level = 0
	if game.step < 450 and game.step >= 400 then
		level = 1
	elseif game.step < 400 and game.step >= 350 then
		level = 2
	elseif game.step < 350 and game.step >= 300 then
		level = 3
	elseif game.step < 300 and game.step >= 250 then
		level = 4
	elseif game.step < 250 and game.step >= 200 then
		level = 5
	elseif game.step < 200 and game.step >= 150 then
		level = 6
	elseif game.step < 150 and game.step >= 100 then
		level = 7
	elseif game.step < 100 and game.step >= 50 then
		level = 8
	elseif game.step < 50 then
		level = 9
	end
	-- new level
	if game.level ~= level then
		animation.level_up = true
		game.level = level
	end
end

-- level up text
function draw_level_up()

	if animation.level_up then
		Font.setPixelSizes(main_font, 25)
		Font.print(main_font, 26+math.floor(animation.level_up_y/3), 120, "LEVEL UP !", Color.new(255,255,255))
	end
end

-- draw next block
function draw_next()
	local x = 0
	local y = 0
	local margin = 15 -- margin around next box
	
	-- 8x8
	local bitx = 0x0040
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
end

-- draw battery
function draw_battery()
    local margin = 60
	local y_offset = 5
    local life = System.getBatteryPercentage()
	
	-- icon
	-- ok
	if life > 70 then
		Graphics.drawPartialImage(DISPLAY_WIDTH - margin, y_offset, img_battery_icon, 0, 0, 50, 25)
	elseif life > 50 then
		Graphics.drawPartialImage(DISPLAY_WIDTH - margin, y_offset, img_battery_icon, 0, 26, 50, 25)
	elseif life > 30 then
		Graphics.drawPartialImage(DISPLAY_WIDTH - margin, y_offset, img_battery_icon, 0, 53, 50, 25)
	elseif life > 10 then
		Graphics.drawPartialImage(DISPLAY_WIDTH - margin, y_offset, img_battery_icon, 0, 78, 50, 25)
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


-- user_input

-- work through user input
function user_input()
	
	-- get time played
	local time_played = Timer.getTime(game.start)
	
	-- last valid input
	local last_input = time_played - input.last_tick

	-- input data
	local pad = Controls.read()
	
	-- add the action to first
	if Controls.check(pad, SCE_CTRL_UP) and not Controls.check(input.prev, SCE_CTRL_UP) then
		table.insert(actions, DIR.UP)
		
	-- sticky key support
	elseif Controls.check(pad, SCE_CTRL_DOWN) and last_input > MIN_INPUT_DELAY then
		table.insert(actions, DIR.DOWN)
		input.last_tick = time_played
		
	-- sticky key support
	elseif Controls.check(pad, SCE_CTRL_LEFT) and last_input > MIN_INPUT_DELAY then
		table.insert(actions, DIR.LEFT)
		input.last_tick = time_played
		
	elseif Controls.check(pad, SCE_CTRL_LTRIGGER) and not Controls.check(input.prev, SCE_CTRL_LTRIGGER ) then
		table.insert(actions, DIR.LEFT)
		
	-- sticky key support
	elseif Controls.check(pad, SCE_CTRL_RIGHT) and last_input > MIN_INPUT_DELAY then
		table.insert(actions, DIR.RIGHT)
		input.last_tick = time_played
		
	elseif Controls.check(pad, SCE_CTRL_RTRIGGER) and not Controls.check(input.prev, SCE_CTRL_RTRIGGER) then
		table.insert(actions, DIR.RIGHT)
		
	elseif Controls.check(pad, SCE_CTRL_CROSS) and not Controls.check(input.prev, SCE_CTRL_CROSS) then
		table.insert(actions, DIR.UP)

	elseif Controls.check(pad, SCE_CTRL_CIRCLE) and not Controls.check(input.prev, SCE_CTRL_CIRCLE) then
		input.double_down = 1 -- speed down
		
	elseif Controls.check(pad, SCE_CTRL_START) and not Controls.check(input.prev, SCE_CTRL_START) then
		if game.state == STATE.INIT then
			-- give option to start
		elseif game.state == STATE.PLAY then
			-- pauze ?
		elseif game.state == STATE.DEAD then
			game_start()
		end
	elseif Controls.check(pad, SCE_CTRL_SELECT) then
		ct_clean_exit()
	end
	
	-- if game dead, offer restart and exit in interface
	if game.state == STATE.DEAD then
		-- read touch control
		local x, y = Controls.readTouch()

		-- first input only
		if x ~= nil then
			
			-- within bounds of buttons (big hitbox around)
			if x > 720 and x < 940 then
				if y > 25 and y < 95 then
					game_start()
				elseif y > 95 and y < 160 then
					ct_clean_exit() 
				end
			end
		end
	end
	
	-- pepperidge farm remembers
	input.prev = pad
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

-- close all resources
-- while not strictly necessary, its clean
function ct_clean_exit()

	-- free images
	Graphics.freeImage(img_inteface)
	Graphics.freeImage(img_background)
	Graphics.freeImage(img_battery_icon)
	Graphics.freeImage(img_stats)
	Graphics.freeImage(img_button)

	-- close music files
	Sound.close(snd_background)
	Sound.close(snd_gameover)
	Sound.close(snd_highscore)
	Sound.close(snd_single_line)
	Sound.close(snd_multi_line)
	
	-- unload font
	Font.unload(main_font)
	
	-- kill this loop
	break_loop = true
end

-- main

-- main function
function main()

	-- start sound
	Sound.play(snd_background, LOOP)
	
	-- set current highscore (file call, don't need to renew every game)
	get_high_score()
	
	-- initiate game variables
	game_start()

	-- gameloop
	while true do
		
		-- process user input
		user_input()
		
		-- update game procs
		update()
		
		-- in case exit was called
		if break_loop then
			break
		end
		
		-- draw game
		draw_frame()
		
		-- wait for black start
		Screen.waitVblankStart()
	end
	
end

-- run the code
main()

-- return to menu
state = MENU.MENU 