-- help screen for tetris

-- load background
local img_background 	= Graphics.loadImage("app0:/assets/img/bg.png")
local img_touch 		= Graphics.loadImage("app0:/assets/img/touch_negative.png")
local img_control 		= Graphics.loadImage("app0:/assets/img/control.png")
local img_version		= Graphics.loadImage("app0:/assets/img/version.png")

-- font
local fnt_main = Font.load("app0:/assets/fonts/xolonium.ttf")

-- constants
BUTTON = { CROSS = 1, CIRCLE = 2, TRIANGLE = 3, SQUARE = 4, LTRIGGER = 5, RTRIGGER = 6, LEFT = 7, RIGHT = 8, UP = 9, DOWN = 10, ANALOG = 11, START = 12, SELECT = 13 }

-- help vars
local return_value = false
local animate_touch = 1
local animate_touch_direction = 1

-- colors
local white 	= Color.new(255, 255, 255)
local black 	= Color.new(0, 0, 0)

-- help
local function help_draw_control(x, y, button_request)

	if button_request == BUTTON.TRIANGLE then
		Graphics.drawPartialImage(x, y, img_control, 5, 2, 50, 50)
		
	elseif button_request == BUTTON.CIRCLE then
		Graphics.drawPartialImage(x, y, img_control, 60, 2, 50, 50)
		
	elseif button_request == BUTTON.CROSS then
		Graphics.drawPartialImage(x, y, img_control, 115, 2, 50, 50)
		
	elseif button_request == BUTTON.SQUARE then
		Graphics.drawPartialImage(x, y, img_control, 170, 2, 50, 50)
		
	elseif button_request == BUTTON.LTRIGGER then
		Graphics.drawPartialImage(x, y, img_control, 0, 56, 80, 34)
		
	elseif button_request == BUTTON.RTRIGGER then
		Graphics.drawPartialImage(x, y, img_control, 232, 8, 80, 34)
		
	elseif button_request == BUTTON.LEFT then
		Graphics.drawPartialImage(x, y, img_control, 197, 54, 60, 45)
		
	elseif button_request == BUTTON.RIGHT then
		Graphics.drawPartialImage(x, y, img_control, 260, 54, 60, 45)
		
	elseif button_request == BUTTON.UP then
		Graphics.drawPartialImage(x, y, img_control, 97, 59, 40, 54)
		
	elseif button_request == BUTTON.DOWN then
		Graphics.drawPartialImage(x, y, img_control, 150, 62, 40, 54)
		
	elseif button_request == BUTTON.ANALOG then
		Graphics.drawPartialImage(x, y, img_control, 34, 100, 58, 58)
	
	elseif button_request == BUTTON.START then
		Graphics.drawPartialImage(x, y, img_control, 222, 102, 79, 40)
		
	elseif button_request == BUTTON.SELECT then
		Graphics.drawPartialImage(x, y, img_control, 105, 119, 79, 40)
	end

end

-- draw function
local function help_draw()
	-- init
	Graphics.initBlend()
	
	-- plot the background (this one is a bit larger)
	Graphics.drawImage(0,0, img_background)
	
	-- text background
	Graphics.fillRect(140, 840, 60, 440, Color.new(255, 255, 255, 70))
		
	-- set font size
	Font.setPixelSizes(fnt_main, 26)
	
	-- input
	Font.print(fnt_main, 170, 90, "INPUT : ", black)
	
	-- reduce font size
	Font.setPixelSizes(fnt_main, 16)
	
	-- large wide buttons
	help_draw_control(220, 140, BUTTON.START)
	Font.print(fnt_main, 310, 150, "RESTART", black)
	
	help_draw_control(220, 190, BUTTON.SELECT)
	Font.print(fnt_main, 310, 200, "EXIT", black)
	
	-- left and right
	help_draw_control(220, 240, BUTTON.LEFT)
	help_draw_control(360, 240, BUTTON.LTRIGGER)
	Font.print(fnt_main, 310, 250, "LEFT", black)
	
	help_draw_control(220, 290, BUTTON.RIGHT)
	help_draw_control(360, 290, BUTTON.RTRIGGER)
	Font.print(fnt_main, 310, 300, "RIGHT", black)
	
	-- right side : rotate buttons
	help_draw_control(550, 140, BUTTON.UP)
	help_draw_control(680, 140, BUTTON.CROSS)
	Font.print(fnt_main, 600, 150, "ROTATE", black)
	
	help_draw_control(550, 210, BUTTON.CIRCLE)
	Font.print(fnt_main, 610, 220, "INSTANT DROP", black)
	
	help_draw_control(550, 270, BUTTON.DOWN)
	Font.print(fnt_main, 610, 280, "DROP", black)
	
	-- touch tip
	Graphics.drawImage(5, 470, img_touch, Color.new(255,255,255, 50 + math.floor(animate_touch/3)))

	Graphics.termBlend()
	Screen.flip()
end

local function help_user_input()
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
	Graphics.freeImage(img_control)
	Graphics.freeImage(img_version)
	
	-- unload font
	Font.unload(fnt_main)
	
end

-- main menu call
function help()
	-- gameloop
	while not return_value do
		help_draw()
		help_user_input()
		-- we get about 180 fps (not essential)
		if 150*3 < animate_touch then
			animate_touch_direction = -1
		elseif animate_touch < 1 then
			animate_touch_direction = 1
		
		end
		animate_touch = animate_touch + animate_touch_direction
	end
	
	-- clear the loaded resources
	cleanup()
	
	-- return
	state = return_value
end

help()