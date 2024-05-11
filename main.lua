-- Stage Counter v1.0.3
-- SmoothSpatula

log.info("Successfully loaded ".._ENV["!guid"]..".")

-- ========== Parameters ==========

mods.on_all_mods_loaded(function() for k, v in pairs(mods) do if type(v) == "table" and v.tomlfuncs then Toml = v end end 
    params = {
        pos_x = 105,
        pos_y = 52,
        scale = 1.0,
        stage_counter_enabled = true,
        show_stage_name = true,
        show_stage_variant = true
    }
    params = Toml.config_update(_ENV["!guid"], params) -- Load Save
end)

local zoom_scale = 1.0
local ingame = false
local current_stage_str = ''
local current_variant = ''
local stage_count = 1

-- ========== ImGui ==========

gui.add_to_menu_bar(function()
    local new_value, clicked = ImGui.Checkbox("Enable Stage Counter", params['stage_counter_enabled'])
    if clicked then
        params['stage_counter_enabled'] = new_value
        Toml.save_cfg(_ENV["!guid"], params)
    end
end)

gui.add_to_menu_bar(function()
    local new_value, clicked = ImGui.Checkbox("Show Stage Name", params['show_stage_name'])
    if clicked then
        params['show_stage_name'] = new_value
        Toml.save_cfg(_ENV["!guid"], params)
    end
end)

gui.add_to_menu_bar(function()
    local new_value, clicked = ImGui.Checkbox("Show Stage Variant", params['show_stage_variant'])
    if clicked then
        params['show_stage_variant'] = new_value
        Toml.save_cfg(_ENV["!guid"], params)
    end
end)

gui.add_to_menu_bar(function()
    local new_value, clicked = ImGui.DragInt("X position from the right part of the screen", params['pos_x'], 1, 0, gm.display_get_gui_width()//zoom_scale)
    if clicked then
        params['pos_x'] = new_value
        Toml.save_cfg(_ENV["!guid"], params)
    end
end)

gui.add_to_menu_bar(function()
    local new_value, clicked = ImGui.DragInt("Y position from the top part of the screen", params['pos_y'], 1, 0, gm.display_get_gui_height()//zoom_scale)
    if clicked then
        params['pos_y'] = new_value
        Toml.save_cfg(_ENV["!guid"], params)
    end
end)

gui.add_to_menu_bar(function()
    local new_value, isChanged = ImGui.InputFloat("Scale of the text", params['scale'], 0.05, 0.2, "%.2f", 0)
    if isChanged and new_value >= -0.01 then -- due to floating point precision error, checking against 0 does not work
        params['scale'] = math.abs(new_value) -- same as above, so it display -0.0
        Toml.save_cfg(_ENV["!guid"], params)
    end
end)

-- ========== Main ==========

-- Draw the number of stage passed
-- 640x480 resolution doesn't work properly
gm.post_code_execute(function(self, other, code, result, flags)
    if code.name:match("oInit_Draw_6") then
        if not params['stage_counter_enabled'] or not ingame then return end
        gm.draw_set_font(5)
        gm.draw_text_transformed_colour(
            gm.display_get_gui_width()-(params['pos_x']*zoom_scale),
            params['pos_y']*zoom_scale,
            "STAGE: "..stage_count..
            "\n"..current_stage_str..current_variant,
            zoom_scale*params['scale'],
            zoom_scale*params['scale'],
            0, 8421504, 8421504, 8421504, 8421504, 1.0)
    end
end)

gm.pre_script_hook(gm.constants.__input_system_tick, function(self, other, result, args)
    zoom_scale = gm.prefs_get_hud_scale()
end)

-- Enable mod when run start
gm.pre_script_hook(gm.constants.run_create, function(self, other, result, args)
    ingame = true
end)

-- Disable mod when run ends
gm.pre_script_hook(gm.constants.run_destroy, function(self, other, result, args)
    ingame = false
end)

-- Update values after new level is loaded
gm.post_script_hook(gm.constants.texture_flush_group, function(self, other, result, args)
    if not params['stage_counter_enabled'] or not ingame then return end
    local director = gm._mod_game_getDirector()
    if not director or not gm._mod_instance_valid(director) == 1.0 then return end

    stage_count = math.floor(director.stages_passed+1)

    local lang_map = gm.variable_global_get("_language_map")
    local class_stage = gm.variable_global_get("class_stage")
    current_stage = gm._mod_game_getCurrentStage()
    current_room = gm.variable_global_get("room")
    
    if params['show_stage_name'] then
        current_stage_str = string.upper(gm.ds_map_find_value(lang_map, class_stage[current_stage+1][3]))
    else 
        current_stage_str = ''
    end
    if params['show_stage_variant'] then
        if current_stage < 11 then
            current_variant = " ("..math.floor(current_room - 9 - 6 * current_stage)..")"
        else 
            current_variant = " (1)"
        end
    else 
        current_variant = ''
    end
end)
