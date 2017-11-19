-- menu file for tetromino

-- load images
local img_background 	= Graphics.loadImage("app0:/assets/img/bg.png")
local img_touch 		= Graphics.loadImage("app0:/assets/img/touch_negative.png")
local img_version 		= Graphics.loadImage("app0:/assets/img/version.png")
local img_awesome 		= Graphics.loadImage("app0:/assets/img/awesome_header.png")
local img_highscore		= Graphics.loadImage("app0:/assets/img/highscore.png")
local img_box 			= Graphics.loadImage("app0:/assets/img/box.png")
local img_box_select 	= Graphics.loadImage("app0:/assets/img/box_select.png")

-- load font
local fnt_main 	= Font.load("app0:/assets/font/xolonium.ttf")

-- menu vars
local oldpad = SCE_CTRL_RTRIGGER -- input init
local current_menu = 1 -- menu position
local max_menu = 2
local min_menu = 1
local return_value = false
local animate_touch = 1
local animate_touch_direction = 1

-- draw function
function menu_draw()
	-- init
	Graphics.initBlend()
	
	-- plot the background
	Graphics.drawImage(0,0, img_background)
		
	-- credits help and exit
	Graphics.drawImage(710, 5, img_awesome)
	Graphics.drawImage(10, 5, img_highscore)
	
	-- set font size
	Font.setPixelSizes(fnt_main, 20)
	
	-- show box background slightly selected (when using buttons)
	local color_white = Color.new(255, 255, 255)
	if current_menu == 1 then
		Graphics.drawImage(220, 149, img_box, Color.new(255, 255, 255, 140))
		Font.print(fnt_main, 270, 155, "CLASSIC", Color.new(255, 255, 255, 140))
		
		Graphics.drawImage(476, 120, img_box_select)
		Font.print(fnt_main, 520, 155, "COLOR MATCH", color_white)
		
	elseif current_menu == 2 then
		Graphics.drawImage(191, 120, img_box_select)
		Font.print(fnt_main, 270, 155, "CLASSIC", color_white)
		
		Graphics.drawImage(505, 149, img_box)
		Font.print(fnt_main, 520, 155, "COLOR MATCH", Color.new(255, 255, 255, 140))
	end
	
	-- draw version
	Graphics.drawImage(791, 506, img_version) -- version
	
	-- touch tip
	Graphics.drawImage(5, 470, img_touch, Color.new(255,255,255, 50 + math.floor(animate_touch/3)))
	
	-- end of drawing
	Graphics.termBlend()
	Screen.flip()
end

function menu_user_input()
	local pad = Controls.read()
	
	-- select
	if (Controls.check(pad, SCE_CTRL_CROSS) and not Controls.check(oldpad, SCE_CTRL_CROSS)) or (Controls.check(pad, SCE_CTRL_CIRCLE) and not Controls.check(oldpad, SCE_CTRL_CIRCLE)) then
		-- pick choise
		if current_menu ~= 0 then
			return_value = current_menu
		end
	-- down
	elseif Controls.check(pad, SCE_CTRL_LEFT) and not Controls.check(oldpad, SCE_CTRL_LEFT) then
		current_menu = current_menu + 1
		if current_menu > max_menu then
			current_menu = min_menu
		end
		
	-- up
	elseif Controls.check(pad, SCE_CTRL_RIGHT) and not Controls.check(oldpad, SCE_CTRL_RIGHT) then
		current_menu = current_menu - 1
		if current_menu < min_menu then
			current_menu = max_menu
		end
		
	-- emergency exit
	elseif Controls.check(pad, SCE_CTRL_SELECT) then
		return_value = MENU.QUIT
	end
	
	-- read touch control
	local x, y = Controls.readTouch()

	-- first input only
	if x ~= nil then
		
		-- game buttons
		if y > 110 and y < 410 then
			if x > 210 and x < 450 then
				return_value = MENU.START_CLASSIC
			elseif x > 490 and x < 730 then
				return_value = MENU.START_COLOR
			end
			
		-- awesome buttons
		elseif y < 75 then
		
			if x > 0 and x < 50 then
				return_value = MENU.HIGHSCORE				
			elseif x > 700 and x < 793 then
				return_value = MENU.CREDIT		
			elseif x > 793 and x < 877 then
				return_value = MENU.HELP		
			elseif x > 877 and x < 960 then
				return_value = MENU.QUIT		
			end
		
		end
		
	end
	
	-- remember
	oldpad = pad
end

-- clean up loaded resources
function cleanup ()
	-- free it again
	Graphics.freeImage(img_background)
	Graphics.freeImage(img_touch)
	Graphics.freeImage(img_version)
	Graphics.freeImage(img_awesome)
	Graphics.freeImage(img_box)
	Graphics.freeImage(img_box_select)
	
	-- release font
	Font.unload(fnt_main)
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
	
	-- unload resouces
	cleanup()
	
	-- return
	state = return_value
end

menu()