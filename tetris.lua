-- game mechanincs

-- game variables
local pieces = {} -- fill all the blocks in this
local step = 500 -- each step the block drops, will become a more important variable once we start using levels/lines

-- pieces
local i = { BLOCK = {0x0F00, 0x2222, 0x00F0, 0x4444}, COLOR = yellow }
local j = { BLOCK = {0x44C0, 0x8E00, 0x6440, 0x0E20}, COLOR = red }
local l = { BLOCK = {0x4460, 0x0E80, 0xC440, 0x2E00}, COLOR = green }
local o = { BLOCK = {0xCC00, 0xCC00, 0xCC00, 0xCC00}, COLOR = orange }
local s = { BLOCK = {0x06C0, 0x8C40, 0x6C00, 0x4620}, COLOR = blue }
local t = { BLOCK = {0x0E40, 0x4C40, 0x4E00, 0x4640}, COLOR = seablue }
local z = { BLOCK = {0x0C60, 0x4C80, 0xC600, 0x2640}, COLOR = purple }


-- main game mechanics update
function update ()
	
	-- check if we are playing
	if game.state ~= STATE.PLAY then
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
		drop()
	end
	
	-- increase speed based on lines
	increase_speed()
end

-- increase speed based on lines
function increase_speed()
	step = 500 - (line_count*5)
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
			new_highscore(score)
			game.state = STATE.DEAD
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
			-- if its not the first line double score !
			if (multi_line > 0) then
				add_score( 100 * ( multi_line + 1 ) )
			else
				add_score( 100 ) -- scored a line :D
				multi_line = multi_line + 1
			end
				add_line(1)
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
	game.last_tick = 0
	
	-- set state to playing
	game.state = STATE.PLAY
	
	-- set current highscore
	current.highscore = get_high_score()
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
	end
	
	-- create it a new highscore file
	local new_score_file = System.openFile("ux0:/data/tetrinomi/tetris_score", FCREATE)
	System.writeFile(new_score_file, score, string.len(score))
	System.closeFile(new_score_file)
end