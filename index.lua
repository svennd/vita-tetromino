-- tetrinomi for vita, by svennd
-- version 0.8

-- save power
System.setCpuSpeed(41) -- default : 333
System.setGpuSpeed(41) -- default : 111
System.setBusSpeed(41) -- default : 222

-- vita constants
DISPLAY_WIDTH = 960
DISPLAY_HEIGHT = 544

-- script constant
MENU = {MENU = 0, START_CLASSIC = 1, START_COLOR = 2, HELP = 3, CREDIT = 4, HIGHSCORE = 5, QUIT = 6, MIN = 1, MAX = 5}

-- script variables
state = MENU.MENU 

--
local img_battery_icon 	= Graphics.loadImage("app0:/assets/img/power.png")

-- font
local fnt_main = Font.load("app0:/assets/xolonium.ttf")

-- main
-- main function
function main()
	-- try to get out, I dare you.
	while true do
		if state == MENU.MENU then
			-- menu
			-- adapts game.state
			dofile("app0:/menu.lua")
			
		elseif state == MENU.START_CLASSIC then
			-- game start
			dofile("app0:/classic_tetris.lua")
			
		elseif state == MENU.START_COLOR then
			-- game start
			dofile("app0:/color_match.lua")
		
		elseif state == MENU.HELP then
			-- help returns to game.state = 0
			dofile("app0:/help.lua")
			
		elseif state == MENU.CREDIT then
			-- credit screen
			dofile("app0:/credits.lua")
			
		elseif state == MENU.HIGHSCORE then
			-- credit screen
			dofile("app0:/highscore.lua")
			
		elseif state == MENU.QUIT then
			-- exit
			clean_exit()
		end	
	end
	
	-- end of execution
	-- fuck restarting the goddamn app.
	clean_exit()
end

-- household functions 
--

-- draw battery
function draw_battery()
    local margin = 60
	local y_offset = 5
    local life = System.getBatteryPercentage()
	
	-- icon
	-- ok
	if life > 70 then
		Graphics.drawPartialImage(DISPLAY_WIDTH - margin, y_offset, img_battery_icon, 0, 0, 50, 25)
	elseif life > 50 then
		Graphics.drawPartialImage(DISPLAY_WIDTH - margin, y_offset, img_battery_icon, 0, 26, 50, 25)
	elseif life > 30 then
		Graphics.drawPartialImage(DISPLAY_WIDTH - margin, y_offset, img_battery_icon, 0, 52, 50, 25)
	elseif life > 10 then
		Graphics.drawPartialImage(DISPLAY_WIDTH - margin, y_offset, img_battery_icon, 0, 78, 50, 25)
	end

	-- decrease font size
	Font.setPixelSizes(fnt_main, 16)
	Font.print(fnt_main, DISPLAY_WIDTH - margin - 45, y_offset, life .. "%", Color.new(255, 255, 255))
end


-- close all resources
-- while not strictly necessary, its clean
function clean_exit()
	
	-- unload battery
	Graphics.freeImage(img_battery_icon)
	
	-- unload font
	Font.unload(fnt_main)
	
	-- kill app
	System.exit()
	
end

-- run the code
main()