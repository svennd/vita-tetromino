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

-- draw function
local function highscore_draw()
	-- init
	Graphics.initBlend()
	
	-- plot the background (this one is a bit larger)
	Graphics.drawImage(0,0, img_background)
	
	-- text background
	Graphics.fillRect(140, 840, 60, 440, Color.new(255, 255, 255, 70))
		
	-- set font size
	Font.setPixelSizes(fnt_main, 26)
	
	-- input
	Font.print(fnt_main, 170, 90, "HIGHSCORE", black)
	
	-- reduce font size
	Font.setPixelSizes(fnt_main, 22)
	
	-- bling bling
	Graphics.drawImage(110, 30, img_highscore)
	Graphics.drawImage(800, 30, img_highscore)
	Graphics.drawImage(110, 380, img_highscore)
	Graphics.drawImage(800, 380, img_highscore)
	
	-- credit
	Font.print(fnt_main, 190, 140, "Classic :" .. get_high_score(1), black)
	Font.print(fnt_main, 190, 170, "Color   :" .. get_high_score(2), black)

	-- touch tip
	Graphics.drawImage(5, 470, img_touch, Color.new(255,255,255, 50 + math.floor(animate_touch/3)))

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