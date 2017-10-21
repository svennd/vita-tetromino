-- tetrinomi for vita, by svennd
-- version 0.7

-- vita constants
DISPLAY_WIDTH = 960
DISPLAY_HEIGHT = 544

-- application variables
VERSION = "0.7"

-- script constant
MENU = {MENU = 0, START = 1, HELP = 2, CREDIT = 3, QUIT = 4, MIN = 1, MAX = 4}

-- script variables
state = MENU.MENU 

-- main
-- main function
function main()
	-- try to get out, I dare you.
	while true do
		if state == MENU.MENU then
			-- menu
			-- adapts game.state
			dofile("app0:/menu.lua")
			
		elseif state == MENU.START then
			-- game start
			dofile("app0:/classic_tetris.lua")
		
		elseif state == MENU.HELP then
			-- help returns to game.state = 0
			dofile("app0:/help.lua")
			
		elseif state == MENU.CREDIT then
			-- credit screen
			dofile("app0:/credits.lua")
			
		elseif state == MENU.QUIT then
			-- exit
			clean_exit()
		end	
	end
	
	-- end of execution
	-- fuck restarting the goddamn app.
	clean_exit()
end

-- close all resources
-- while not strictly necessary, its clean
function clean_exit()
	
	-- kill app
	System.exit()
	
end

-- run the code
main()