-- Stage Counter v1.0.2
-- SmoothSpatula

log.info("Successfully loaded ".._ENV["!guid"]..".")
Toml = require("tomlHelper")

-- ========== Parameters ==========

local default_params = {
    pos_x = 105,
    pos_y = 52,
    scale = 1.0,
    stage_counter_enabled = true
}

local params = Toml.load_cfg(_ENV["!guid"])

if not params then
    Toml.save_cfg(_ENV["!guid"], default_params)
    params = default_params
end

local zoom_scale = 1.0
local ingame = false

-- ========== ImGui ==========

gui.add_to_menu_bar(function()
    local new_value, clicked = ImGui.Checkbox("Enable Stage Counter", params['stage_counter_enabled'])
    if clicked then
        params['stage_counter_enabled'] = new_value
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
        local director = gm._mod_game_getDirector()
        if director and gm._mod_instance_valid(director) == 1.0 then
            gm.draw_set_font(5)
            gm.draw_text_transformed_colour(
                gm.display_get_gui_width()-(params['pos_x']*zoom_scale),
                params['pos_y']*zoom_scale,
                "STAGE: "..math.floor(director.stages_passed+1),
                zoom_scale*params['scale'],
                zoom_scale*params['scale'],
                0, 8421504, 8421504, 8421504, 8421504, 1.0)
        end
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
