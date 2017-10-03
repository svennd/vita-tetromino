-- drawing functions

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
	    
		draw_text("GAME OVER", 610, 50, white, 25)
		if new_highscore_flag then
	    	draw_text("! NEW HIGHSCORE !", 610, 90, white, 25)
		end
		
    elseif game.state == STATE.INIT then
        draw_interface()
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
        draw_text("New version available", 800, 300, red, 30)
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
	
	-- tick score
	if score > vscore then
		vscore = vscore + 1
	end
	
	-- score
	draw_text("SCORE : ", 110, 270, white, 30)
	draw_text(vscore, 110, 330, white, 30)
	draw_box(100, 270, 260, 370, 3, grey_3)

	-- lines
	draw_text("LINES : ", 110, 390, white, 30)
	draw_text(line_count, 110, 450, white, 30)
	draw_box(100, 270, 380, 490, 3, grey_3)
	
	-- high_score
	draw_high_score()
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
	draw_text("upcoming", SIZE.NEXT_OFFSET_X-margin, SIZE.NEXT_OFFSET_Y-(margin*3), white, 25)
	
end

-- draw battery
function draw_battery()
    local margin = 50
	local y_offset = 5
    local life = System.getBatteryPercentage()
	
	-- icon
	Graphics.drawImage(DISPLAY_WIDTH - margin, y_offset, battery_icon)
	
	-- print %
	draw_text(life .. "%", (DISPLAY_WIDTH - margin), y_offset, black, 16)
end

-- draw highscore
function draw_high_score()
    
    -- score
    draw_text("highscore : ", 610, 270, white, 30)
    draw_text(current.highscore, 610, 330, white, 30)
    
    -- box
	draw_box(600, 790, 260, 370, 3, white)
	
end

-- help
function draw_show_help()
	Font.setPixelSizes(main_font, 16)
	Font.print(main_font, 800, 350, "START to play", white)
	Font.print(main_font, 800, 370, "SELECT to exit", white)
	Font.print(main_font, 800, 390, "< left right >", white)
	Font.print(main_font, 800, 410, "UP/X rotate", white)
	Font.print(main_font, 800, 430, "O drop", white)
end

-- interface menu
function draw_interface()
    
    local button = { width = 150, height = 50 }
    local margin = { x = 15, y = 5 }
    
    -- menu
    -- start tetronimo
    draw_text("START CLASSIC TETRIS", (DISPLAY_WIDTH/2)-(button.width/2)+margin.x, 300+button.height-margin.y, white, 28)
    Graphics.fillRect(
                (DISPLAY_WIDTH/2)-(button.width/2),
                (DISPLAY_WIDTH/2)+(button.width/2),
                (300-(button.height/2)),
                (300+(button.height/2)),
                ((menu_point == 1) ? grey_3 : grey_1)
            )
            
    -- credits
    draw_text("CREDITS", (DISPLAY_WIDTH/2)-(button.width/2)+margin.x, 350+button.height-margin.y, white, 28)
    Graphics.fillRect(
                (DISPLAY_WIDTH/2)-(button.width/2),
                (DISPLAY_WIDTH/2)+(button.width/2),
                (350-(button.height/2)),
                (350+(button.height/2)),
                ((menu_point == 2) ? grey_3 : grey_1)
            )
            
    -- check for update
    draw_text("CHECK FOR UPDATES", (DISPLAY_WIDTH/2)-(button.width/2)+margin.x, 350+button.height-margin.y, white, 28)
    Graphics.fillRect(
                (DISPLAY_WIDTH/2)-(button.width/2),
                (DISPLAY_WIDTH/2)+(button.width/2),
                (400-(button.height/2)),
                (400+(button.height/2)),
                ((menu_point == 3) ? grey_3 : grey_1)
            )
            
    -- exit
    draw_text("I HATE TETRIS", (DISPLAY_WIDTH/2)-(button.width/2)+margin.x, 350+button.height-margin.y, white, 28)
    Graphics.fillRect(
                (DISPLAY_WIDTH/2)-(button.width/2),
                (DISPLAY_WIDTH/2)+(button.width/2),
                (450-(button.height/2)),
                (450+(button.height/2)),
                ((menu_point == 4) ? grey_3 : grey_1)
            )
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

-- wrapper around font.*
function draw_text(msg, x, y, color, size)
    -- set size
	Font.setPixelSizes(main_font, size)
	
	-- set location, color and msg
	Font.print(main_font, x, y, msg, color)
end
