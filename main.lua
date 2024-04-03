-- Stage Counter v1.0.0
-- SmoothSpatula

log.info("Successfully loaded ".._ENV["!guid"]..".")
Toml = require("tomlHelper")

-- ========== Parameters ==========

local default_params = {
    stage_counter_enabled = true,
}

local params = Toml.load_cfg(_ENV["!guid"])

if not params then
    Toml.save_cfg(_ENV["!guid"], default_params)
    params = default_params
end

local isChanged = false
local ingame = false

-- ========== ImGui ==========

gui.add_to_menu_bar(function()
    local new_value, clicked = ImGui.Checkbox("Enable Stage Counter", params['stage_counter_enabled'])
    if clicked then
        params['stage_counter_enabled'] = new_value
        Toml.save_cfg(_ENV["!guid"], params)
    end
end)

-- ========== Main ==========

-- Draw the number of stage passed
-- 640x480 resolution doesn't have 
gm.post_code_execute(function(self, other, code, result, flags)
    if code.name:match("oInit_Draw_6") then
        if not params['stage_counter_enabled'] or not ingame then return end
        local director = gm._mod_game_getDirector()
        if director and gm._mod_instance_valid(director) == 1.0 then
            gm.draw_set_font(5)
            gm.draw_text_transformed_colour(gm.display_get_gui_width()-(105*gm.prefs_get_zoom_scale()), 52*gm.prefs_get_zoom_scale(), "STAGE: "..math.floor(director.stages_passed+100), gm.prefs_get_zoom_scale(), gm.prefs_get_zoom_scale(), 0, 8421504, 8421504, 8421504, 8421504, 1.0)
        end
    end
end)

-- Enable mod when run start
gm.pre_script_hook(gm.constants.run_create, function(self, other, result, args)
    ingame = true
end)

-- Disable mod when run ends
gm.pre_script_hook(gm.constants.run_destroy, function(self, other, result, args)
    ingame = false
end)