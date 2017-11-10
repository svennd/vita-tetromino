-- menu file for tetromino

-- load background
local img_background = Graphics.loadImage("app0:/assets/bg_menu.png")
local img_menu = Graphics.loadImage("app0:/assets/menu.png")
local img_touch = Graphics.loadImage("app0:/assets/touch_negative.png")
local img_pointer = Graphics.loadImage("app0:/assets/pointer.png")
local img_version = Graphics.loadImage("app0:/assets/version.png")

-- menu vars
local oldpad = SCE_CTRL_RTRIGGER -- input init
local current_menu = 1 -- menu position
local return_value = false
local animate_touch = 1
local animate_touch_direction = 1

-- draw function
local function menu_draw()
	-- init
	Graphics.initBlend()
	
	-- plot the background
	Graphics.drawImage(0,0, img_background)
	
	-- the lazy method
	Graphics.drawImage(341,85, img_menu)
	
	if current_menu == 1 then
		Graphics.drawImage(357,94, img_pointer, Color.new(255,255,255, 70 + math.floor(animate_touch/3))) -- start
	elseif current_menu == 2 then
		Graphics.drawImage(357,192, img_pointer, Color.new(255,255,255, 70 + math.floor(animate_touch/3))) -- help
	elseif current_menu == 3 then
		Graphics.drawImage(357,290, img_pointer, Color.new(255,255,255, 70 + math.floor(animate_touch/3))) -- credits
	elseif current_menu == 4 then
		Graphics.drawImage(357,388, img_pointer, Color.new(255,255,255, 70 + math.floor(animate_touch/3))) -- exit
	end
	
	-- draw version
	Graphics.drawImage(791, 506, img_version) -- version
	
	-- touch tip
	Graphics.drawImage(5, 470, img_touch, Color.new(255,255,255, 50 + math.floor(animate_touch/3)))
	
	-- end of drawing
	Graphics.termBlend()
	Screen.flip()
end

local function menu_user_input()
	local pad = Controls.read()
	
	-- select
	if (Controls.check(pad, SCE_CTRL_CROSS) and not Controls.check(oldpad, SCE_CTRL_CROSS)) or (Controls.check(pad, SCE_CTRL_CIRCLE) and not Controls.check(oldpad, SCE_CTRL_CIRCLE)) then
		-- pick choise
		if current_menu ~= 0 then
			return_value = current_menu
		end
	-- down
	elseif Controls.check(pad, SCE_CTRL_DOWN) and not Controls.check(oldpad, SCE_CTRL_DOWN) then
		current_menu = current_menu + 1
		if current_menu > MENU.MAX then
			current_menu = MENU.MIN
		end
		
	-- up
	elseif Controls.check(pad, SCE_CTRL_UP) and not Controls.check(oldpad, SCE_CTRL_UP) then
		current_menu = current_menu - 1
		if current_menu < MENU.MIN then
			current_menu = MENU.MAX
		end
		
	-- emergency exit
	elseif Controls.check(pad, SCE_CTRL_SELECT) then
		current_menu = MENU.EXIT
	end
	
	-- read touch control
	local x, y = Controls.readTouch()

	-- first input only
	if x ~= nil then
		
		-- within bounds of buttons (big hitbox around)
		if x > 340 and x < 580 then
			if y > 80 and y < 150 then
				return_value = 1 -- start
			elseif y > 170 and y < 250 then
				return_value = 2 -- help
			elseif y > 275 and y < 345 then
				return_value = 3 -- credits
			elseif y > 375 and y < 450 then
				return_value = 4 -- quit
			end
		end
	end
	
	-- remember
	oldpad = pad
end

local swipe_start = 0
local swipe_x1 = nil

-- check if a swipe is detected (only horizontal)
-- based on the implementation of VitaHEX 
local function swipe_check()
	-- touch input
	local x1, y1 = Controls.readTouch()
	
	-- data
	if x1 ~= nil then
		-- start position
		if swipe_start == 0 and swipe_dt < 5 then
			swipe_start = 1
			swipe_x1 = x1
			swipe_dt = 100
		end
		
		-- swipe started
		if swipe_start == 1 and swipe_dt > 5 then
			if x1 > swipe_x1 + 80 then
				--right swipe
			elseif x1 < swipe_x1 - 80 then
				--left swipe
			end
		end
	end
	
	if swipe_dt > 0 then
		swipe_dt = swipe_dt - 1
	elseif
		-- swipe_dt = 0
		swipe_start = 0
	end
end

-- main menu call
function menu()
	-- gameloop
	while not return_value do
		menu_draw()
		menu_user_input()
		
		-- we get about 180 fps
		if 150*3 < animate_touch then
			animate_touch_direction = -1
		elseif animate_touch < 1 then
			animate_touch_direction = 1
		
		end
		animate_touch = animate_touch + animate_touch_direction
	end
	
	-- free it again
	Graphics.freeImage(img_background)
	Graphics.freeImage(img_touch)
	Graphics.freeImage(img_menu)
	Graphics.freeImage(img_pointer)
	Graphics.freeImage(img_version)
	
	-- unload font
	Font.unload(main_font)
	
	-- return
	state = return_value
end

menu()