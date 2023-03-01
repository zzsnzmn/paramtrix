--
-- require the `mods` module to gain access to hooks, menu, and other utility
-- functions.
--

local mod = require 'core/mods'
local script = require 'core/script'
local tabutil = require 'tabutil'
local music = require 'musicutil'
--
-- [optional] a mod is like any normal lua module. local variables can be used
-- to hold any state which needs to be accessible across hooks, the menu, and
-- any api provided by the mod itself.
--
-- here a single table is used to hold some x/y values
--

local state = {
  x = 0,
  y = 0,
  z = 0,
}

-- make this a data structure that maps the menu
local grid_params = {}


local grid_key_evt = function(x, y, z)
  print(x,y,z)
  state.grid_device:led(x,y,z*15)
  state.grid_device:refresh()
  state.x = x
  state.y = y
  state.z = z

end

--
-- [optional] hooks are essentially callbacks which can be used by multiple mods
-- at the same time. each function registered with a hook must also include a
-- name. registering a new function with the name of an existing function will
-- replace the existing function. using descriptive names (which include the
-- name of the mod itself) can help debugging because the name of a callback
-- function will be printed out by matron (making it visible in maiden) before
-- the callback function is called.
--
-- here we have dummy functionality to help confirm things are getting called
-- and test out access to mod level state via mod supplied fuctions.
--

mod.hook.register("script_pre_init", "paramtrix_pre_init", function()
  -- tweak global environment here ahead of the script `init()` function being called
end)



--- when no script gets loaded, activate gridkeys
--- this happens on system (re)start and script stop
mod.hook.register("system_post_startup", "paramtrix_post_system_startup", function ()
    state.system_post_startup = true
    local script_clear = script.clear
    script.clear = function()

      local is_restart = (tabutil.count(params.lookup) == 0)

      -- if state.grid_device ~= nil then
      --   restore_grid_initial_state()
      -- end

      script_clear()

      if is_restart then
	print("mod - paramtrix - clear at (re)start")
	-- startup_init_grid()
	-- init_params()
	-- update_midi_out_device_by_index(1)
	state.grid_device = grid.connect(4)
	state.grid_device.key = grid_key_evt
	-- init_params()
	-- params:set("gridkeys_midi_mode", 3)
      else
	print("mod - paramtrix - clear at script stop / pre-start")
	-- script_init_grid()
	state.grid_device = grid.connect(4)
	state.grid_device.key = grid_key_evt
	-- init_params()
	-- params:set('paramtrix_active', 2)
	-- params:bang()
      end
    end

    grid_params = {}

    for i=1,params.count do
	local p = params:lookup_param(i)
	tab.print(p)
	if p.allow_pmap then
		table.insert(grid_params, p)
	end
    end


  -- replace the default update function
  -- screen.update_default = function()
  -- end

  -- patch screensaver metro event handler to continue
  -- updating NDI after screensaver activates
  -- local original_ss_event = metro[36].event
  -- metro[36].event = function()
    -- original_ss_event()
    -- screen.update = function()
      -- ndi_mod.update()
    -- end
  -- end

  -- clients get confused if norns starts up NDI too quickly
  -- after a restart, so delay it until the first screen update
  -- XXX don't need the ndi blocking probably unless there's
  -- some lazy parameter stuff happening
  -- screen.update = function()
    -- ndi_mod.init()
    -- ndi_mod.start()
    -- screen.update = screen.update_default
    -- screen.update()
--     _norns.screen_update()

  --   screen.move(64,40)
    -- screen.text_center(state.active_button.x .. "/" .. state.active_button.y .. "/" .. state.active_button.z)
--     screen.update()
  -- end
  --
  screen.update_default = function()

	  _norns.screen_update()
	  if state.z > 0 then

		  print(state.x + ((state.y-1) * 8))
		  _norns.screen_rect(31,33,66,18)
		  _norns.screen_level(15)
		  _norns.screen_fill()
		  _norns.screen_rect(32,34,64,16)
		  _norns.screen_level(0)
		  _norns.screen_fill()
		  _norns.screen_move(64,45)
		  _norns.screen_level(15)
		  _norns.screen_text_center(params:lookup_param(state.x + ((state.y-1) * 8)).name)
		  _norns.screen_update()
	  end
  end

  screen.update = function()
	  screen.update = screen.update_default
	  screen.update()
  end

end)


--
-- [optional] menu: extending the menu system is done by creating a table with
-- all the required menu functions defined.
--

local m = {}

m.key = function(n, z)
  if n == 2 and z == 1 then
    -- return to the mod selection menu
    mod.menu.exit()
  end
end

m.enc = function(n, d)
  if n == 2 then state.x = state.x + d
  elseif n == 3 then state.y = state.y + d end
  -- tell the menu system to redraw, which in turn calls the mod's menu redraw
  -- function
  mod.menu.redraw()
end

m.redraw = function()
  screen.clear()
  screen.move(64,40)
  screen.text_center(state.x .. "/" .. state.y)
  screen.update()
end

m.init = function() end -- on menu entry, ie, if you wanted to start timers
m.deinit = function() end -- on menu exit

-- register the mod menu
--
-- NOTE: `mod.this_name` is a convienence variable which will be set to the name
-- of the mod which is being loaded. in order for the menu to work it must be
-- registered with a name which matches the name of the mod in the dust folder.
--
mod.menu.register(mod.this_name, m)


--
-- [optional] returning a value from the module allows the mod to provide
-- library functionality to scripts via the normal lua `require` function.
--
-- NOTE: it is important for scripts to use `require` to load mod functionality
-- instead of the norns specific `include` function. using `require` ensures
-- that only one copy of the mod is loaded. if a script were to use `include`
-- new copies of the menu, hook functions, and state would be loaded replacing
-- the previous registered functions/menu each time a script was run.
--
-- here we provide a single function which allows a script to get the mod's
-- state table. using this in a script would look like:
--
-- local mod = require 'name_of_mod/lib/mod'
-- local the_state = mod.get_state()
--
local api = {}

api.get_state = function()
  return state
end

return api
