-- menu file for tetromino

-- load background
local img_background 	= Graphics.loadImage("app0:/assets/img/bg.png")
local img_version 		= Graphics.loadImage("app0:/assets/img/version.png")
local img_menu 			= Graphics.loadImage("app0:/assets/img/menu.png")
local img_touch			= Graphics.loadImage("app0:/assets/img/touch_negative.png")
local img_pointer 		= Graphics.loadImage("app0:/assets/img/pointer.png")

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
	Graphics.drawImage(341, 40, img_menu)
	
	if current_menu == MENU.START_CLASSIC then
		Graphics.drawImage(357, 50, img_pointer) -- start
	elseif current_menu == MENU.HIGHSCORE then
		Graphics.drawImage(357, 144, img_pointer) -- score
	elseif current_menu == MENU.HELP then
		Graphics.drawImage(357, 235, img_pointer) -- help
	elseif current_menu == MENU.CREDIT then
		Graphics.drawImage(357, 327, img_pointer) -- credits
	elseif current_menu == MENU.QUIT then
		Graphics.drawImage(357, 421, img_pointer) -- exit
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
	end
	
	-- read touch control
	local x, y = Controls.readTouch()

	-- first input only
	if x ~= nil then
		
		-- within bounds of buttons (big hitbox around)
		if x > 340 and x < 580 then
			if y > 20 and y < 110 then
				return_value = MENU.START_CLASSIC -- start
			elseif y > 130 and y < 200 then
				return_value = MENU.HIGHSCORE -- highscore
			elseif y > 220 and y < 290 then
				return_value = MENU.HELP -- help
			elseif y > 310 and y < 390 then
				return_value = MENU.CREDIT -- credits
			elseif y > 410 and y < 480 then
				return_value = MENU.QUIT -- quit
			end
		end
		
	end
	
	-- remember
	oldpad = pad
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
	
	-- return
	state = return_value
end

menu()