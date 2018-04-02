-- tetrinomi for vita, by svennd
-- version 0.8

-- save power
System.setCpuSpeed(41) -- default : 333
System.setGpuSpeed(41) -- default : 111
System.setBusSpeed(41) -- default : 222

-- vita constants
DISPLAY_WIDTH = 960
DISPLAY_HEIGHT = 544

-- debug mode
DEBUG_MODE = false

-- script constant
MENU = {MENU = 0, START_CLASSIC = 1, HIGHSCORE = 2, HELP = 3, CREDIT = 4, QUIT = 5, MIN = 1, MAX = 5}

-- script variables
state = MENU.MENU 

-- load battery
local img_battery_icon 	= Graphics.loadImage("app0:/assets/img/power.png")

-- font
local fnt_main = Font.load("app0:/assets/fonts/xolonium.ttf")

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

		elseif state == MENU.HELP then
			-- help returns to state = 0
			dofile("app0:/help.lua")
			
		elseif state == MENU.CREDIT then
			-- credit screen
			dofile("app0:/credits.lua")
			
		elseif state == MENU.HIGHSCORE then
			-- highscore screen
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

-- make a new highscore entry
-- note : current_score could also be called from file, but file calls are slower then ram, and since this is open-format anyways 
--		  it does not matter much in way of "cheating"
function new_highscore(mode, current_score, high_score, playtime, stats)

    -- current score is higher then one of the top_5
	local new_high = 0
	local i = 1
	while high_score[1][i] do
		if high_score[1][i] < current_score then
			new_high = 1
		end
		i = i + 1
	end
	
	-- no new highscore
	if new_high ~= 1 then
		return false
	end
	
	-- get the username
	-- init keyboard
	Keyboard.show("New highscore : player", "")
	
	local player = ""
	while true do
		-- exception we need to draw here
		Graphics.initBlend()
		Screen.clear()
	
		status = Keyboard.getState()
		
		-- not running
		if status ~= RUNNING then
		
			-- Check if user didn't canceled the keyboard
			if status ~= CANCELED then
				-- only allow 8 char names
				player = string.sub(Keyboard.getInput(), 0, 16)
			else
				player = "Guest"
			end
			
			-- Terminating keyboard
			Keyboard.clear()
			-- back to execution
			break
		end
		Graphics.termBlend()
		Screen.flip()		
	end
	
	-- create it a new highscore file
	write_score(mode, current_score, player, playtime, stats)
	
	return true
end

-- get highest 5 score for a certain mode
function get_high_score(mode)
	-- just in case
	create_data_dir()
	
	-- check if file exist
	if System.doesFileExist("ux0:/data/tetrinomi/tetromino.score") then
		
		-- init
		local top_1 = 0
		local top_2 = 0
		local top_3 = 0
		local top_4 = 0
		local top_5 = 0
		
		local player_1 = 0
		local player_2 = 0
		local player_3 = 0
		local player_4 = 0
		local player_5 = 0
		
		-- score file
		local score_file = System.openFile("ux0:/data/tetrinomi/tetromino.score", FREAD)

		-- read content
		scores = System.readFile(score_file, System.sizeFile(score_file))
	
		-- close file again
		System.closeFile(score_file)	
		
		-- get score_lines
		score_lines = explode("\n", scores)
		
		-- no score lines yet
		if #score_lines == 0 then
			return {{0, 0, 0, 0, 0}, {"guest","guest","guest","guest","guest"}}
		end
		
		-- loop through all the scores
		local x = 1
		while score_lines[x] do
			-- get all values
			v = explode("|", score_lines[x])
			
			-- if mode is right
			if v[1] == mode then
				-- higher score ?
				local value = tonumber(v[2])
				local player = v[3]
				
				if value >= top_1 then
					-- push all the scores down
					top_5 = top_4
					top_4 = top_3
					top_3 = top_2
					top_2 = top_1
					top_1 = value
					
					-- push all player down
					player_5 = player_4
					player_4 = player_3
					player_3 = player_2
					player_2 = player_1
					player_1 = player
					
				elseif value >= top_2 then
					-- push all the scores down from top_2
					top_5 = top_4
					top_4 = top_3
					top_3 = top_2
					top_2 = value
					
					-- push all player down from p2
					player_5 = player_4
					player_4 = player_3
					player_3 = player_2
					player_2 = player
					
				elseif value >= top_3 then
					top_5 = top_4
					top_4 = top_3
					top_3 = value
					
					-- push all player down from p3
					player_5 = player_4
					player_4 = player_3
					player_3 = player
					
				elseif value >= top_4 then
					top_5 = top_4
					top_4 = value
					
					-- push all player down from p4
					player_5 = player_4
					player_4 = player
					
				elseif value > top_5 then
					top_5 = value
					
					player_5 = player
				end
			end
			x = x + 1
		end
		
		return {{top_1, top_2, top_3, top_4, top_5}, {player_1, player_2, player_3, player_4, player_5}}
		
	else
		return {{0, 0, 0, 0, 0}, {"guest","guest","guest","guest","guest"}}
	end
end

-- write the score to file
function write_score(mode, value, player, playtime, stats)

	-- just to be sure
	create_data_dir()
	
	-- current time/date (hour:minute - month/day/year) (crazy 'mericans)
	timestamp = os.date("%H:%M - %x")
	
	-- score line (if you wanted to encrypt and later decrypt this would be the place)
	score_line = mode .. "|" .. value .. "|" .. player .. "|" .. timestamp .. "|" .. playtime .. "|" .. stats ..  "\n"

	-- open for writing, if not exist create
	score_file = System.openFile("ux0:/data/tetrinomi/tetromino.score", FCREATE)
	
	-- set pointer to end of the file
	System.seekFile(score_file, 0, END)
	
	-- write the "score" line to file
	System.writeFile(score_file, score_line, string.len(score_line))
	System.closeFile(score_file)
	
end

-- create the data dir if it not there
function create_data_dir()
	-- check if it does not exist and create it when needed
	if not System.doesDirExist("ux0:/data/tetrinomi") then
		System.createDirectory("ux0:/data/tetrinomi")
	end
end

-- http://lua-users.org/wiki/SplitJoin
-- explode(seperator, string)
function explode(d,p)
   local t, ll
   t={}
   ll=0
   if(#p == 1) then
      return {p}
   end
   while true do
      l = string.find(p, d, ll, true) -- find the next d in the string
      if l ~= nil then -- if "not not" found then..
         table.insert(t, string.sub(p,ll,l-1)) -- Save it in our array.
         ll = l + 1 -- save just after where we found it for searching next time.
      else
         table.insert(t, string.sub(p,ll)) -- Save what's left in our array.
         break -- Break at end, as it should be, according to the lua manual.
      end
   end
   return t
end

-- debug function
if DEBUG_MODE then
	handle = System.openFile("ux0:/data/tetris_debug.txt", FCREATE)
	function debug_msg(msg)
		System.writeFile(handle, msg, string.len(msg))
	end
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