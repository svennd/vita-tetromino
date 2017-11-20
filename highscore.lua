-- highscore screen for tetris

-- load background
local img_background 	= Graphics.loadImage("app0:/assets/img/bg.png")
local img_touch 		= Graphics.loadImage("app0:/assets/img/touch_negative.png")
local img_version 		= Graphics.loadImage("app0:/assets/img/version.png")
local img_highscore		= Graphics.loadImage("app0:/assets/img/highscore.png")

-- font
local fnt_main 	= Font.load("app0:/assets/xolonium.ttf")

-- credits vars
local return_value = false
local animate_touch = 1
local animate_touch_direction = 1

-- colors
local white 	= Color.new(255, 255, 255)
local black 	= Color.new(0, 0, 0)

-- credits
local function get_highscore(mode)

	-- check if it does not exist and create it when needed
	if not System.doesDirExist("ux0:/data/tetrinomi") then
		System.createDirectory("ux0:/data/tetrinomi")
	end
	
	-- 'convert' the legacy format to the new format of highscore format
	if System.doesFileExist("ux0:/data/tetrinomi/tetris_score") then
		System.rename("ux0:/data/tetrinomi/tetris_score", "ux0:/data/tetrinomi/tetris_classic_score")
	end
	
	if mode == 1 then
		if System.doesFileExist("ux0:/data/tetrinomi/tetris_classic_score") then    
			-- open file
			score_file = System.openFile("ux0:/data/tetrinomi/tetris_classic_score", FREAD)
			
			-- read content
			local highscore = System.readFile(score_file, System.sizeFile(score_file))
			
			-- close file again
			System.closeFile(score_file)

			-- put it into score field
			return tonumber(highscore)
		end
	elseif mode == 2 then
		if System.doesFileExist("ux0:/data/tetrinomi/tetris_color_score") then    
			-- open file
			score_file = System.openFile("ux0:/data/tetrinomi/tetris_color_score", FREAD)
			
			-- read content
			local highscore = System.readFile(score_file, System.sizeFile(score_file))
			
			-- close file again
			System.closeFile(score_file)

			-- put it into score field
			return tonumber(highscore)
		end
	end
	return 0
end

-- draw function
local function highscore_draw()
	-- init
	Graphics.initBlend()
	
	-- plot the background (this one is a bit larger)
	Graphics.drawImage(0,0, img_background)
	
	-- text background
	Graphics.fillRect(140, 840, 80, 440, Color.new(255, 255, 255, 70))
		
	-- set font size
	Font.setPixelSizes(fnt_main, 26)
	
	-- input
	Font.print(fnt_main, 170, 90, "HIGHSCORE", black)
	
	-- reduce font size
	Font.setPixelSizes(fnt_main, 22)
	
	-- bling bling
	Graphics.drawImage(130, 10, img_highscore)
	Graphics.drawImage(230, 10, img_highscore)
	Graphics.drawImage(330, 10, img_highscore)
	Graphics.drawImage(430, 10, img_highscore)
	
	-- credit
	Font.print(fnt_main, 190, 140, "Classic :" .. get_highscore(1), black)
	Font.print(fnt_main, 190, 170, "Color   :" .. get_highscore(2), black)

	-- touch tip
	Graphics.drawImage(5, 470, img_touch, Color.new(255,255,255, 50 + math.floor(animate_touch/3)))

	-- draw version
	Graphics.drawImage(791, 506, img_version) -- version
	
	Graphics.termBlend()
	Screen.flip()
end

local function highscore_user_input()
	local pad = Controls.read()
	
	-- select
	if Controls.check(pad, SCE_CTRL_CROSS) or Controls.check(pad, SCE_CTRL_CIRCLE) then
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

	-- free it again
	Graphics.freeImage(img_background)
	Graphics.freeImage(img_touch)
	Graphics.freeImage(img_version)
	Graphics.freeImage(img_highscore)
	
	-- unload font
	Font.unload(fnt_main)
	
end

-- main menu call
function highscore()
	-- gameloop
	while not return_value do
		highscore_draw()
		highscore_user_input()
		-- we get about 180 fps (not essential)
		if 150*3 < animate_touch then
			animate_touch_direction = -1
		elseif animate_touch < 1 then
			animate_touch_direction = 1
		
		end
		animate_touch = animate_touch + animate_touch_direction
	end
	
	-- cleanup loaded resources
	cleanup()
	
	-- return
	state = return_value
end

highscore()