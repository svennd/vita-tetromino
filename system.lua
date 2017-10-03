-- system mechanics and functions

-- settings
local MIN_INPUT_DELAY = 50 -- mimimun delay between 2 keys are considered pressed in ms

-- variables
local oldpad = SCE_CTRL_CROSS -- user input init
local last_user_tick = 0 -- ticks between userinput is allowed

-- work through user input
function user_input()
	
	-- get time played
	local time_played = Timer.getTime(game.start)
	
	-- last valid input
	local last_input = time_played - last_user_tick

	-- input data
	local pad = Controls.read()
	
	-- add the action to first
	if Controls.check(pad, SCE_CTRL_UP) and not Controls.check(oldpad, SCE_CTRL_UP) then
		table.insert(actions, DIR.UP)
		
	-- sticky key support
	elseif Controls.check(pad, SCE_CTRL_DOWN) and last_input > MIN_INPUT_DELAY then
		table.insert(actions, DIR.DOWN)
		last_user_tick = time_played
		
	-- sticky key support
	elseif Controls.check(pad, SCE_CTRL_LEFT) and last_input > MIN_INPUT_DELAY then
		table.insert(actions, DIR.LEFT)
		last_user_tick = time_played
		
	elseif Controls.check(pad, SCE_CTRL_LTRIGGER) and not Controls.check(oldpad, SCE_CTRL_LTRIGGER ) then
		table.insert(actions, DIR.LEFT)
		
	-- sticky key support
	elseif Controls.check(pad, SCE_CTRL_RIGHT) and last_input > MIN_INPUT_DELAY then
		table.insert(actions, DIR.RIGHT)
		last_user_tick = time_played
		
	elseif Controls.check(pad, SCE_CTRL_RTRIGGER) and not Controls.check(oldpad, SCE_CTRL_RTRIGGER) then
		table.insert(actions, DIR.RIGHT)
		
	elseif Controls.check(pad, SCE_CTRL_CROSS) and not Controls.check(oldpad, SCE_CTRL_CROSS) then
		table.insert(actions, DIR.UP)

	elseif Controls.check(pad, SCE_CTRL_CIRCLE) and not Controls.check(oldpad, SCE_CTRL_CIRCLE) then
		double_down_speed = 1 -- speed down
		
	elseif Controls.check(pad, SCE_CTRL_START) and not Controls.check(oldpad, SCE_CTRL_START) then
		if game.state == STATE.INIT then
			-- give option to start
		elseif game.state == STATE.PLAY then
			-- pauze ?
		elseif game.state == STATE.DEAD then
			game_start()
		end
	elseif Controls.check(pad, SCE_CTRL_SELECT) then
		clean_exit()
	end
	
	-- pepperidge farm remembers
	oldpad = pad
end


-- close all resources
-- while not strictly necessary, its clean
function clean_exit()

	Graphics.freeImage(background)
	Graphics.freeImage(battery_icon)
	Font.unload(main_font)
	System.exit()
	
end

-- version check
function version_check()
	-- initialize network
	Network.init()

	-- Checking if connection is available
	if Network.isWifiEnabled() then

		-- sync send a request for the content
		local uplink_version = Network.requestString("https://raw.githubusercontent.com/svennd/vita-tetromino/master/VERSION.md")

		if uplink_version ~= VERSION then
			draw_new_version = true
		end
	end

	-- Terminating network
	Network.term()
end
