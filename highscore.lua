-- highscore screen for tetromino

-- font
-- local fnt_main 	= Font.load("app0:/assets/xolonium.ttf")
local fnt_retro 	= Font.load("app0:/assets/fonts/Retroscape.ttf")

-- load images
local img_highscore_header 	= Graphics.loadImage("app0:/assets/img/highscore_header.png")
local img_version 			= Graphics.loadImage("app0:/assets/img/version.png")

-- highscore vars
local return_value = false

-- colors
local white 	= Color.new(255, 255, 255)
local black 	= Color.new(0, 0, 0)
local yellow 	= Color.new(255, 255, 0)
local orange 	= Color.new(255, 102, 0)
local red 		= Color.new(255, 0, 0)
local purple	= Color.new(136, 0, 170)
local pink	 	= Color.new(255, 0, 102)

-- animation
math.randomseed(os.clock()*1000)
local stars = {
				{ x = math.random(5,950), y = math.random(10,544), yellow = math.random(0,255), level = math.random(0,255) },
				{ x = math.random(5,950), y = math.random(10,544), yellow = math.random(0,255), level = math.random(0,255) },
				{ x = math.random(5,950), y = math.random(10,544), yellow = math.random(0,255), level = math.random(0,255) },
				{ x = math.random(5,950), y = math.random(10,544), yellow = math.random(0,255), level = math.random(0,255) },
				{ x = math.random(5,950), y = math.random(10,544), yellow = math.random(0,255), level = math.random(0,255) },
				{ x = math.random(5,950), y = math.random(10,544), yellow = math.random(0,255), level = math.random(0,255) },
				{ x = math.random(5,950), y = math.random(10,544), yellow = math.random(0,255), level = math.random(0,255) },
				{ x = math.random(5,950), y = math.random(10,544), yellow = math.random(0,255), level = math.random(0,255) },
				{ x = math.random(5,950), y = math.random(10,544), yellow = math.random(0,255), level = math.random(0,255) },
				{ x = math.random(5,950), y = math.random(10,544), yellow = math.random(0,255), level = math.random(0,255) },
				{ x = math.random(5,950), y = math.random(10,544), yellow = math.random(0,255), level = math.random(0,255) },
				{ x = math.random(5,950), y = math.random(10,544), yellow = math.random(0,255), level = math.random(0,255) },
				{ x = math.random(5,950), y = math.random(10,544), yellow = math.random(0,255), level = math.random(0,255) },
				{ x = math.random(5,950), y = math.random(10,544), yellow = math.random(0,255), level = math.random(0,255) },
				{ x = math.random(5,950), y = math.random(10,544), yellow = math.random(0,255), level = math.random(0,255) },
				{ x = math.random(5,950), y = math.random(10,544), yellow = math.random(0,255), level = math.random(0,255) },
				{ x = math.random(5,950), y = math.random(10,544), yellow = math.random(0,255), level = math.random(0,255) },
				{ x = math.random(5,950), y = math.random(10,544), yellow = math.random(0,255), level = math.random(0,255) },
				{ x = math.random(5,950), y = math.random(10,544), yellow = math.random(0,255), level = math.random(0,255) },
				{ x = math.random(5,950), y = math.random(10,544), yellow = math.random(0,255), level = math.random(0,255) },
				{ x = math.random(5,950), y = math.random(10,544), yellow = math.random(0,255), level = math.random(0,255) },
				{ x = math.random(5,950), y = math.random(10,544), yellow = math.random(0,255), level = math.random(0,255) },
				{ x = math.random(5,950), y = math.random(10,544), yellow = math.random(0,255), level = math.random(0,255) }
			}
			
-- draw function
local function draw_stars()
	local i = 1
	
	while stars[i] do
		Graphics.fillRect(stars[i].x, stars[i].x + 3, stars[i].y, stars[i].y + 3, Color.new(255, 255, stars[i].yellow, stars[i].level))
		
		local new_level = stars[i].level + 3
		if new_level > 255 then
			stars[i].level = 0
		else
			stars[i].level = new_level
		end
		
		if math.random(0,1) == 1 then
			local new_color = stars[i].yellow + 1
			if new_color > 255 then
				stars[i].yellow = stars[i].yellow - 2;
			else
				stars[i].yellow = new_color
			end			
		else
			local new_color = stars[i].yellow - 1
			if new_color < 0 then
				stars[i].yellow = stars[i].yellow + 2;
			else
				stars[i].yellow = new_color
			end			
		end
		
		i = i + 1
	end
end

local function highscore_draw()
	-- init
	Graphics.initBlend()
	
	-- black background
	Graphics.fillRect(0, DISPLAY_WIDTH, 0, DISPLAY_HEIGHT, black)

	-- draw stars
	draw_stars(1)
	
	-- draw header
	Graphics.drawImage(100, 54, img_highscore_header)
	
	-- draw table
	-- draw header
	Font.setPixelSizes(fnt_retro, 18)
	Font.print(fnt_retro, 135, 280, "RANK", white)
	Font.print(fnt_retro, 335, 280, "SCORE", white)
	Font.print(fnt_retro, 600, 280, "PLAYER", white)
	
	-- get data
	local high_score = get_high_score("classic")
	
	Font.setPixelSizes(fnt_retro, 16)
	Font.print(fnt_retro, 150, 330, "1ST", yellow)
	Font.print(fnt_retro, 150, 370, "2ND", orange)
	Font.print(fnt_retro, 150, 410, "3RD", red)
	Font.print(fnt_retro, 150, 450, "4TH", purple)
	Font.print(fnt_retro, 150, 490, "5TH", pink)
	
	-- print set data :)
	local color = {yellow, orange, red, purple, pink}
	local i = 1
	while 5 >= i do
		-- value
		Font.print(fnt_retro, 370, 330+(40*(i-1)), high_score[1][i], color[i])
		
		-- username
		Font.print(fnt_retro, 600, 330+(40*(i-1)), string.upper(high_score[2][i]), color[i])
		
		i = i + 1
	end
	
	-- draw version
	Graphics.drawImage(791, 506, img_version) -- version
	
	Graphics.termBlend()
	Screen.flip()
end

local function highscore_user_input()
	local pad = Controls.read()
	
	-- any key ?
	if Controls.check(pad, SCE_CTRL_CROSS) or Controls.check(pad, SCE_CTRL_CIRCLE) then
		return_value = MENU.MENU
	end
	
	-- exit key
	if Controls.check(pad, SCE_CTRL_SELECT) then
		return_value = MENU.MENU
	end
	
	-- read touch control
	local x, y = Controls.readTouch()

	-- first input only
	if x ~= nil then
		-- any touch go back to menu
		return_value = MENU.MENU
	end
end

-- clean up loaded resources
local function cleanup ()
	-- unload font
	Font.unload(fnt_retro)
	
	-- unload gfx
	Graphics.freeImage(img_highscore_header)
	Graphics.freeImage(img_version)
	
end

-- main menu call
function highscore()
	-- gameloop
	while not return_value do
		highscore_draw()
		highscore_user_input()
	end
	
	-- cleanup loaded resources
	cleanup()
	
	-- return
	state = return_value
end

highscore()