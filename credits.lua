-- credits screen for tetris

-- load background
local img_background = Graphics.loadImage("app0:/assets/bg_menu.png") -- lazy :D
local img_touch = Graphics.loadImage("app0:/assets/touch_negative.png")
local img_version = Graphics.loadImage("app0:/assets/version.png")

-- font
local main_font = Font.load("app0:/assets/xolonium.ttf")

-- credits vars
local return_value = false
local animate_touch = 1
local animate_touch_direction = 1

-- colors
local white 	= Color.new(255, 255, 255)
local black 	= Color.new(0, 0, 0)

-- credits

-- draw function
local function credits_draw()
	-- init
	Graphics.initBlend()
	
	-- plot the background (this one is a bit larger)
	Graphics.drawImage(0,0, img_background)
	
	-- text background
	Graphics.fillRect(140, 840, 60, 440, Color.new(255, 255, 255, 70))
		
	-- set font size
	Font.setPixelSizes(main_font, 26)
	
	-- input
	Font.print(main_font, 170, 90, "CREDITS", black)
	
	-- reduce font size
	Font.setPixelSizes(main_font, 22)
	
	-- credit
	Font.print(main_font, 190, 140, "Lua Player Plus Vita by Rinnegatamante\n(rinnegatamante.it)\n\nVITA buttons by nodeadfolk\n\nXolomium font from fontlibrary.com\n\nsounds by freesound.org\n\n\n\n\nBy Svennd (svennd.be)", black)

	-- touch tip
	Graphics.drawImage(5, 470, img_touch, Color.new(255,255,255, 50 + math.floor(animate_touch/3)))

	-- draw version
	Graphics.drawImage(791, 506, img_version) -- version
	
	Graphics.termBlend()
	Screen.flip()
end

local function credits_user_input()
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

-- main menu call
function credits()
	-- gameloop
	while not return_value do
		credits_draw()
		credits_user_input()
		-- we get about 180 fps (not essential)
		if 150*3 < animate_touch then
			animate_touch_direction = -1
		elseif animate_touch < 1 then
			animate_touch_direction = 1
		
		end
		animate_touch = animate_touch + animate_touch_direction
	end
	
	-- free it again
	Graphics.freeImage(img_version)
	Graphics.freeImage(img_touch)
	Graphics.freeImage(img_background)
	
	-- return
	state = return_value
end

credits()