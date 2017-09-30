-- includes
--dofile("app0:/fps.lua")

-- color
local white 	= Color.new(255, 255, 255)
local black 	= Color.new(0, 0, 0)
local yellow 	= Color.new(255, 255, 0)
local red 		= Color.new(255, 0, 0)
local blue 		= Color.new(0, 0, 255)
local green 	= Color.new(0, 255, 0)

local DISPLAY_WIDTH = 960
local DISPLAY_HEIGHT = 544

-- initialize game constants
DIR = { UP = 1, RIGHT = 2, DOWN = 3, LEFT = 4, MIN = 1, MAX = 4 }
STATE = {INIT = 1, PLAY = 2, DEAD = 3}

-- mimimun delay between 2 keys are considered pressed in ms
MIN_INPUT_DELAY = 50

-- initialize variables
actions = {}
current_time = Timer.new()
last_time = 0
pieces = {} -- will be filled
game = {start = Timer.new(), last_tick = 0}
step = 500 -- should be dynamic

-- current piece
current = {piece = {}, x = 0, y = 0, dir = DIR.UP, state = STATE.INIT }
next_piece = {piece = {}, dir = DIR.UP }

-- block size in pixels
dx = 25
dy = 25

-- court
field = {}
heigh_tetris_field = 20
width_tetris_field = 10

-- blocks
i = { BLOCK = {0x0F00, 0x2222, 0x00F0, 0x4444}, COLOR = yellow }
j = { BLOCK = {0x44C0, 0x8E00, 0x6440, 0x0E20}, COLOR = black }
l = { BLOCK = {0x4460, 0x0E80, 0xC440, 0x2E00}, COLOR = red }
o = { BLOCK = {0xCC00, 0xCC00, 0xCC00, 0xCC00}, COLOR = red }
s = { BLOCK = {0x06C0, 0x8C40, 0x6C00, 0x4620}, COLOR = yellow }
t = { BLOCK = {0x0E40, 0x4C40, 0x4E00, 0x4640}, COLOR = blue }
z = { BLOCK = {0x0C60, 0x4C80, 0xC600, 0x2640}, COLOR = white }


-- temp
-- start_y = 100
-- draw_block_count = 1
-- selected_block = false

oldpad = SCE_CTRL_CROSS

-- court offset
offset_x = 300
offset_y = 20

-- function eachblock (type_block, x, y, dir, fn)
function eachblock (piece)
	local row = 0
	local col = 0
	
	local start_x = current.x
	local start_y = current.y
	
	-- bit
	local bitx = 0x8000
	-- local i = 0
	while bitx > 0 do
		
		-- if piece and bit are set draw
		if bit.band(piece.BLOCK[current.dir], bitx) > 0 then
			draw_block((current.x + col), (current.y + row), piece.COLOR)
		-- else
			-- for debug background
			-- draw_block(start_x + (col*dx), start_y + (row*dy), yellow)
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

-- check if a piece can fit into a position in the grid
function occupied(piece, x_arg, y_arg, dir)
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
		if bit.band(piece.BLOCK[dir], bitx) > 0 then
			-- new position
			x = x_arg + col
			y = y_arg + row
			
			-- in case our x would be out of bounds
			if x < 0 or x > width_tetris_field then
				-- msg = "oob x " .. piece.BLOCK[dir] .. " to " .. bitx .. "\n" 
				-- System.writeFile(log_handler, msg, string.len(msg))
				return true
			end
			
			-- in case our y would be out of bounds
			if y < 0 or y > heigh_tetris_field then
				-- msg = "oob y " .. piece.BLOCK[dir] .. " to " .. bitx .. "\n" 
				-- System.writeFile(log_handler, msg, string.len(msg))
				return true
			end
			
			-- in case there is already a block
			if get_block(x, y) then
				-- flog("already block on ".. x .." ".. y .." ".. piece.BLOCK[dir] .." to ".. bitx .."\n")
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
	
	-- ok everything is fine its not occupied
	return false
end

-- draw the play field
function draw_court()

	local x = 0
	local y = 0
	
	for y = 0, heigh_tetris_field, y + 1 do
		for x = 0, width_tetris_field, x + 1 do
			if get_block(x, y) then
				local block = get_block(x, y)
				draw_block( x, y, block.COLOR)
			else
				draw_block( x, y, green)
			end
		end
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

-- set block
function set_block(x, y, block)
	if field[x] then
		field[x][y] = block
	else
		field[x] = {}
		field[x][y] = block
	end
end

-- clear everything
function clear_field()
	field = {}
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

-- pseudo random that is usefull for tetris
function random_piece() 

	-- no more pieces left
	if table.getn(pieces) == 0 then
		-- all the pieces in 4 states (note: the state is not defined)
		pieces = {i,i,i,i,j,j,j,j,l,l,l,l,o,o,o,o,s,s,s,s,t,t,t,t,z,z,z,z}
		
		-- shuffle them, http://gamebuildingtools.com/using-lua/shuffle-table-lua
		local n = table.getn(pieces)
		while n > 2 do 
			local k = math.random(n) -- get a random number
			pieces[n], pieces[k] = pieces[k], pieces[n]
			n = n - 1
		end
	end
	
	--current.dir = math.random(DIR.MIN, DIR.MAX)
	return table.remove(pieces) -- remove and return piece
end

-- main
function main()
	
	-- selected_block = random_piece()
	-- current.piece = random_piece()
	-- current.dir = math.random(DIR.MIN, DIR.MAX)
	set_next_piece()
	set_current_piece()
	
	-- when game starts reset timer
	Timer.reset(game.start)
	
	log_handler = System.openFile("ux0:/data/tetris_log.txt", FCREATE)
	
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
	
	System.closeFile(log_handler)
end

function update ()
	
	-- check if we are playing
	if current.state ~= STATE.PLAY then
		return true
	end
	
	-- handle of the actions
	-- get the first action
	local current_action = table.remove(actions, 1) 
	
	if current_action == DIR.UP then
		-- start_y = start_y - 10 * FPSController.getDelta()
		-- start_y = start_y - 10
		rotate()
	elseif current_action == DIR.DOWN then
		drop()
	elseif current_action == DIR.LEFT then
		move(DIR.LEFT)
	elseif current_action == DIR.RIGHT then
		move(DIR.RIGHT)
	end
	
	-- tick if deltaT > step
	local time_played = Timer.getTime(game.start)
	dt = time_played - game.last_tick
	if dt > step then
		-- do something
		game.last_tick = time_played
		drop()
	end	
end

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


function drop()
	-- if its not possible to move the piece down
	if not move(DIR.DOWN) then
		drop_pieces() -- split it
		remove_lines()
		set_next_piece()
		set_current_piece()
		
		-- if not possible to find a spot for its current location its overwritten = dead
		if occupied(current.piece, current.x, current.y, current.dir) then
			-- lose()
			flog("dead\n")
			current.state = STATE.DEAD
		end
	end
end

function remove_lines()
	local x = 0
	local y = 0
	local full_line = true
	
	for y = 0, heigh_tetris_field, y + 1 do
		full_line = true
		for x = 0, width_tetris_field, x + 1 do
			-- search for a empty spot
			if not get_block(x, y) then
				full_line = false
				break
			end
		end
		
		-- if a full line remove it
		if full_line then
			remove_line(y)
			y = y - 1 -- recheck the same line
		end
	end
end

-- remove a single line
-- we need to check the entire (from line) array to drop if needed
function remove_line(line)
	local x = 0
	local y = 0
	local type_block = {}
	
	for y = line, 0, y - 1 do
		for x = 0, width_tetris_field, x + 1 do
			if y == 0 then
				type_block = nil
			else
				type_block = get_block(x, y-1)
			end
			set_block(x, y, type_block)
		end
	end
end

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

function flog(msg)
	System.writeFile(log_handler, msg, string.len(msg))
end

function draw_frame()

	-- Starting drawing phase
	Graphics.initBlend()
	
	-- background
	Graphics.fillRect(0, DISPLAY_WIDTH, 0, DISPLAY_HEIGHT, black)
	
	-- temp
	if current.state == STATE.DEAD then
		Graphics.debugPrint(700, 5, "loser!!!!", white)
	end
	-- Graphics.debugPrint(700, 100, "" .. #actions, white)
	-- Graphics.debugPrint(700, 100, "delay " .. #pieces, white)
	-- Graphics.debugPrint(700, 150, "delay " .. table.getn(pieces), white)
	Graphics.debugPrint(700, 200, "step " .. step, white)
	
	-- draw court
	draw_court()
	
	-- draw piece playing with
	eachblock(current.piece)
	
	-- Terminating drawing phase
	Graphics.termBlend()
	Screen.flip()
end

-- draw a single block
function draw_block(x, y, color)	
	-- Graphics.fillRect(x1,x2,y1,y2,color)
	Graphics.fillRect(offset_x+(x*dx), offset_x+((x+1)*dx), offset_y+(y*dy), offset_y+((y+1)*dy), color)
end

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
		step=step+10
		
	elseif Controls.check(pad, SCE_CTRL_CIRCLE) and not Controls.check(oldpad, SCE_CTRL_CIRCLE) then
		step=step-10
		
	elseif Controls.check(pad, SCE_CTRL_START) then
		System.exit()
	end
	
	oldpad = pad
	
	-- reset time
	Timer.reset(current_time)
	
end


-- run the code
main()