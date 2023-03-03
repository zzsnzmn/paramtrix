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
  original_enc_fn = nil,
  current_param = nil,
  active_group = 1,
  total_groups = 0,
  btn_press_idx = 0, -- keeps the index of what param if any is active
  groups = {},
  params = {}, -- pages is group param id -> table of params
}

-- make this a data structure that maps the menu
local grid_params = {}

local grid_redraw_group_params = function()
  -- print("ouch")
  for i,v in ipairs(state.params) do 
    if params:t(v) ~= params.tGROUP then
      state.grid_device:led(i, 2, 8)
    end
  end
end

local grid_redraw = function()
  if state.grid_device ~= nil then 
    state.grid_device:all(0)
    state.groups = {} 
    state.total_groups = 0
    local j = 0
    for i=1,params.count do
      if params:t(i) == params.tGROUP then
        table.insert(state.groups, i)
        state.total_groups = state.total_groups + 1
        j = j + 1
        state.grid_device:led(j, 1, 12)
      end
      -- if params:visible(i) then table.insert(state.pages[j], i) end
    end
    
    state.grid_device:led(state.active_group, 1, 8)
    
    grid_redraw_group_params()
    
    state.grid_device:refresh()
  end
end

local param_enc_fn = function(n, d)
  if n == 1 then
    -- print("modifying param enc: " .. d)
    if state.btn_press_idx > 0 then 
      params:lookup_param(state.params[state.btn_press_idx]):delta(d)
    end
  end
end


local grid_key_evt = function(x, y, z)
  -- print(x,y,z)
  if y == 1 and z == 1 then
    -- if state.total_groups <= x then
    state.active_group = x
    -- end
    state.params = {} 
    _end = state.groups[x+1] or params.count
    _start = state.groups[x] or 0
    for i=_start,_end do
      if params:visible(i) and params:t(i) ~= params.tGROUP then table.insert(state.params, i) end
      -- if params:visible(i) then table.insert(state.pages[j], i) end
    end
    
    -- print("active_group:" .. state.active_group)
    -- print("active_group_id:" .. state.groups[state.active_group])
    -- print("btn_idx:" .. state.btn_press_idx)
    -- print("pages: " .. state.pages[state.active_group])
    -- for i=state.groups[state.active_group],
  end
  
  if y >= 2 then
    -- TODO: convert button press to idx for active groups
    -- TODO: turn on leds for params when switching groups
    -- 
    local _y = y - 2
    state.btn_press_idx = x + (_y * 16)
    
    -- print("btn_press_idx: " .. state.btn_press_idx)
    -- print("group: " .. state.groups[state.active_group])
    -- print("params: " .. state.params)
    -- tab.print(state.params)
    state.x = x
    state.y = y
    state.z = z
  end
  
  if z == 0 and state.original_enc_fn ~= nil then
  	_norns.enc = state.original_enc_fn
  else
  	state.original_enc_fn = _norns.enc
  	_norns.enc = param_enc_fn

	-- params:lookup_param(i)

-- 	tab.print(p)
	-- if p.allow_pmap then
		-- table.insert(grid_params, p)
	-- end

-- 	end
  end
  -- print(state.total_groups)
  grid_redraw()
end

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

      script_clear()

      if is_restart then
      -- 	print("mod - paramtrix - clear at (re)start")
      	state.grid_device = grid.connect(4)
      	state.grid_device.key = grid_key_evt
      else
      -- 	print("mod - paramtrix - clear at script stop / pre-start")
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
-- 	tab.print(p)
	if p.allow_pmap then
		table.insert(grid_params, p)
	end
    end

  GRID_WIDTH = 16
  screen.update_default = function()

	  _norns.screen_update()
	  
	  
    grid_redraw()
	  
	  
	  if state.z > 0 and params:t(state.btn_press_idx) ~= params.tGROUP then
		  local p = params:lookup_param(state.params[state.btn_press_idx])
		  -- print(state.btn_press_idx)
		  -- tab.print(state.params)
	  -- text = p.name .. ": " .. string.format("%.2f", p.raw)

		  
      if params:t(state.btn_press_idx) ~= params.tGROUP then
  		  -- text = p.name .. ": " .. p.raw or ""
	      text = p.name .. ": " .. string.format("%.2f", p.raw)
      else
  		  text = p.name .. ": " -- .. p.raw or ""
      end
		  _norns.screen_rect(31-16,33,66+32,18)
		  _norns.screen_level(15)
		  _norns.screen_fill()
		  _norns.screen_rect(32-16,34,64+32,16)
		  _norns.screen_level(0)
		  _norns.screen_fill()
		  _norns.screen_move(64,45)
		  _norns.screen_level(15)
		  -- _norns.screen_text_center(p.name .. ": " .. string.format("%.4f", p.raw))
		  _norns.screen_text_center(text)
		  _norns.screen_update()
	  end
	  state.grid_device:refresh() 
	  
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
