-- tetrinomi for vita, by svennd
-- version 0.1

-- vita constants
DISPLAY_WIDTH = 960
DISPLAY_HEIGHT = 544

-- screen bg
background = Graphics.loadImage("app0:/assets/background.png")

-- game constants
DIR = { UP = 1, RIGHT = 2, DOWN = 3, LEFT = 4, MIN = 1, MAX = 4 } -- tetronimo direction
STATE = {INIT = 1, PLAY = 2, DEAD = 3} -- game state
MIN_INPUT_DELAY = 50 -- mimimun delay between 2 keys are considered pressed in ms
SIZE = { X = 25, Y = 25, HEIGHT_FIELD = 20, WIDTH_FIELD = 10, COURT_OFFSET_X = 300, COURT_OFFSET_Y = 0 } -- size in px

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
current_time = Timer.new() -- timer for limiting user input
pieces = {} -- fill all the blocks in this
game = {start = Timer.new(), last_tick = 0}
step = 500 -- each step the block drops, will become a more important variable once we start using levels/lines
current = {piece = {}, x = 0, y = 0, dir = DIR.UP, state = STATE.INIT } -- current active piece
next_piece = {piece = {}, dir = DIR.UP } -- upcoming piece
field = {} -- playing field table
oldpad = SCE_CTRL_CROSS -- user input init
score = 0
line_count = 0

-- pieces
i = { BLOCK = {0x0F00, 0x2222, 0x00F0, 0x4444}, COLOR = yellow }
j = { BLOCK = {0x44C0, 0x8E00, 0x6440, 0x0E20}, COLOR = red }
l = { BLOCK = {0x4460, 0x0E80, 0xC440, 0x2E00}, COLOR = green }
o = { BLOCK = {0xCC00, 0xCC00, 0xCC00, 0xCC00}, COLOR = orange }
s = { BLOCK = {0x06C0, 0x8C40, 0x6C00, 0x4620}, COLOR = yellow }
t = { BLOCK = {0x0E40, 0x4C40, 0x4E00, 0x4640}, COLOR = seablue }
z = { BLOCK = {0x0C60, 0x4C80, 0xC600, 0x2640}, COLOR = purple }


-- game mechanincs

-- main game mechanics update
function update ()
	
	-- check if we are playing
	if current.state ~= STATE.PLAY then
		return true
	end
	
	local time_played = Timer.getTime(game.start)
	local dt = 0
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
	
	-- tick if deltaT > step
	dt = time_played - game.last_tick
	if dt > step then
		-- drop block and update last tick
		game.last_tick = time_played
		drop()
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
	current.x = 0
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
			current.state = STATE.DEAD
		end
	end
end

-- go through the field to find full lines
function remove_lines()
	local x = 0
	local y = 0
	local full_line = true
	
	for y = 0, SIZE.HEIGHT_FIELD, y + 1 do
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
			remove_line(y)
			add_score(100) -- scored a line :D
			y = y - 1 -- recheck the same line
		end
	end
end

-- remove a single line and drop the above
function remove_line(line)

	local x = 0
	local y = 0
	local type_block = {}
	
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

function add_score(n)
	score = score + n
end

function add_line(n)
	line_count = line_count + n
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
	if current.state == STATE.DEAD then
		Graphics.debugPrint(700, 5, "loser!!!!", white)
	end
	
	--Graphics.debugPrint(700, 200, "step " .. step, white)
	
	-- draw court
	draw_court()
	
	-- draw piece playing with
	draw_current()
	
	-- draw upcomming piece 
	draw_next()
	
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

function draw_score()
end

--next_piece = {piece = {}, dir = DIR.UP } -- upcoming piece

function draw_next()
	local x = 0
	local y = 0
	
	-- 8x8
	local bitx = 0x8000
	while bitx > 0 do
		
		-- if current.piece bit is set are draw block
		if bit.band(next_piece.piece.BLOCK[current.dir], bitx) > 0 then
			-- draw_block uses SIZE.COURT_OFFSET by default
			Graphics.fillRect(
					(x*SIZE.X) + x, 
					((x+1)*SIZE.X) + x, 
					(y*SIZE.Y) + y, 
					((y+1)*SIZE.Y) + y, 
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

-- user_input

-- work through user input
function user_input()
	
	-- limit input
	if Timer.getTime(current_time) < MIN_INPUT_DELAY then
		return true
	end
	
	-- input data
	local pad = Controls.read()
	
	-- add the action to first
	if Controls.check(pad, SCE_CTRL_UP) and not Controls.check(oldpad, SCE_CTRL_UP) then
		table.insert(actions, DIR.UP)
		
	elseif Controls.check(pad, SCE_CTRL_DOWN) and not Controls.check(oldpad, SCE_CTRL_DOWN) then
		table.insert(actions, DIR.DOWN)
		
	elseif Controls.check(pad, SCE_CTRL_LEFT) and not Controls.check(oldpad, SCE_CTRL_LEFT) then
		table.insert(actions, DIR.LEFT)
		
	elseif Controls.check(pad, SCE_CTRL_RIGHT) and not Controls.check(oldpad, SCE_CTRL_RIGHT) then
		table.insert(actions, DIR.RIGHT)
		
	elseif Controls.check(pad, SCE_CTRL_CROSS) and not Controls.check(oldpad, SCE_CTRL_CROSS) then
		table.insert(actions, DIR.UP)

	elseif Controls.check(pad, SCE_CTRL_START) then
		System.exit()
	end
	
	-- pepperidge farm remembers
	oldpad = pad
	
	-- reset time
	Timer.reset(current_time)
end


-- main

-- main function
function main()
	
	-- set up next and current piece
	set_next_piece() -- determ next piece
	set_current_piece() -- set next piece as current piece
	set_next_piece() -- pull the next piece
	
	-- reset start timer
	Timer.reset(game.start)
	
	-- set game as started
	current.state = STATE.PLAY
	
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