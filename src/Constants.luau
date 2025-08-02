local run_service = game:GetService("RunService")

return {
    -- DONT CHANGE
    ["IS_CLIENT"] = run_service:IsClient(),
    ["IS_SERVER"] = run_service:IsServer(),

    -- CAN CHANGE (SETTINGS)
    ["WHITELIST_ENABLED"] = false,
    ["WHITELIST"] = {
        -- ["GROUP_ID"] = nil,
        -- ["GROUP_MIN_RANK"] = 255,
        ["USERS"] = { -- ids
            
        }
    },

    ["TOGGLE_KEYBIND"] = "RightAlt",

    ["UI"] = {
        ["COLOR_A"] = Color3.fromRGB(45, 45, 45),
        ["COLOR_B"] = Color3.fromRGB(25, 25, 25),
        ["COLOR_C"] = Color3.fromRGB(18, 18, 18),
        ["COLOR_D"] = Color3.fromRGB(60, 60, 60),
        ["COLOR_E"] = Color3.fromRGB(255, 255, 255),
        ["COLOR_TRUE"] = Color3.fromRGB(109, 223, 99),
        ["COLOR_FALSE"] = Color3.fromRGB(),
    }
}
