local MIN_SIZE_X = 180 -- pixels

local DRAG_LERP_ALPHA = 0.25
local RESIZE_LERP_ALPHA = 1
local RESIZING_SPEED = 1

local players = game:GetService("Players")

local player = players.LocalPlayer
local player_gui = player:WaitForChild("PlayerGui")

local interface = {}
interface.__index = interface

function interface.new()
	local self = setmetatable({}, interface)

	self.ui = script.Interface

	self:_Init()

	return self
end

function interface:_Init()
	self.ui.Parent = player_gui
end

-- return interface



function configify_ui:_Init()
	self._ScreenGui = ui

	local scrolling_frame = ui.Container.ScrollingFrame
	local env_container = ui.Container.EnvContainer
	local tab_container = ui.Container.TabContainer
	local drag_btn: TextButton = ui.Container.Drag
	local resize_btn: ImageButton = ui.Container.Resize

	local export_client: TextButton = tab_container.Client.Export
	local export_server = tab_container.Server.Export

	-- export logic
	local function export()
		if self._current_tab == nil then
			return
		end

		self.Export:Fire(self._current_tab)
	end
	export_client.MouseButton1Down:Connect(export)
	export_server.MouseButton1Down:Connect(export)

	-- dragging/minimize logic
	drag_btn.MouseButton1Down:Connect(function(x, y)
		local click_or_hold = nil

		local thread = task.delay(0.1, function()
			if click_or_hold and click_or_hold.Connected then
				click_or_hold:Disconnect()
				click_or_hold = nil
			end

			local offset = ui.Container.AbsolutePosition - Vector2.new(mouse.X, mouse.Y)

			runservice:BindToRenderStep("Configify_DragStart", Enum.RenderPriority.Last.Value + 10, function(dt)
				local goal = UDim2.fromOffset(
					mouse.X + offset.X, 
					mouse.Y + offset.Y + env_container.Size.Y.Offset + tab_container.Size.Y.Offset
				)
				ui.Container.Position = ui.Container.Position:Lerp(goal, DRAG_LERP_ALPHA)
			end)

			local c
			c = uis.InputEnded:Connect(function(input)
				if not (input.UserInputType == Enum.UserInputType.MouseButton1) then
					return
				end

				runservice:UnbindFromRenderStep("Configify_DragStart")
				c:Disconnect()
				c = nil
			end)
		end)

		click_or_hold = uis.InputEnded:Connect(function(input)
			if not (input.UserInputType == Enum.UserInputType.MouseButton1) then
				return
			end

			task.cancel(thread)
			click_or_hold:Disconnect()
			click_or_hold = nil

			-- Click/minimize behavior
			env_container.Visible = not env_container.Visible
			ui.Container.ScrollingFrame.Visible = not ui.Container.ScrollingFrame.Visible
			tab_container.Visible = not tab_container.Visible
			resize_btn.Visible = not resize_btn.Visible

			local container_size_Y = ui.Container.Size.Y.Offset
			local stored_size_Y = ui.Container:GetAttribute("PreviousSize")

			if container_size_Y == 0 then
				-- was closed, open
				ui.Container.Size = UDim2.fromOffset(ui.Container.Size.X.Offset, stored_size_Y or 0)
			else
				-- was open, close
				ui.Container:SetAttribute("PreviousSize", ui.Container.Size.Y.Offset)
				ui.Container.Size = UDim2.fromOffset(ui.Container.Size.X.Offset, 0)
			end
		end)
	end)

	-- resizing logic
	resize_btn.MouseButton1Down:Connect(function(x, y)
		local mouse_delta = Vector2.zero
		local mouse_pos = Vector2.new(mouse.X, mouse.Y)
		ui.Container.Size = UDim2.fromOffset(ui.Container.Size.X.Offset, math.max(0, ui.Container.Size.Y.Offset))

		runservice:BindToRenderStep("Configify_ResizeStart", Enum.RenderPriority.Last.Value + 10, function(dt)
			local goal = UDim2.fromOffset(
				math.max(ui.Container.Size.X.Offset - (mouse_delta.X * RESIZING_SPEED), MIN_SIZE_X),
				ui.Container.Size.Y.Offset - (mouse_delta.Y * RESIZING_SPEED)
			)

			ui.Container.Size = ui.Container.Size:Lerp(goal, RESIZE_LERP_ALPHA)

			local new_pos = Vector2.new(mouse.X, mouse.Y)
			mouse_delta = mouse_pos - new_pos

			mouse_pos = new_pos
		end)

		local c
		c = uis.InputEnded:Connect(function(input)
			if not (input.UserInputType == Enum.UserInputType.MouseButton1) then
				return
			end

			runservice:UnbindFromRenderStep("Configify_ResizeStart")
			c:Disconnect()
			c = nil
		end)
	end)

	local function setup_hover(ui_obj: Frame)
		ui_obj.MouseEnter:Connect(function(x, y)
			self:_HoverStart(ui_obj)
		end)

		ui_obj.MouseLeave:Connect(function(x, y)
			self:_HoverStop(ui_obj)
		end)
	end

	setup_hover(env_container.ClientBtn)
	setup_hover(env_container.ServerBtn)

	env_container.ClientBtn.MouseButton1Click:Connect(function()
		self:_SelectEnvironment("Client")
	end)

	env_container.ServerBtn.MouseButton1Click:Connect(function()
		self:_SelectEnvironment("Server")
	end)

	--Init
	self:_SelectEnvironment("Client")
end

function configify_ui:AddTab(module_name, env_type: "Client" | "Server")
	-- Make folder for any config for this tab
	local tab_folder = create(
		"Folder", {
			["Name"] = module_name,
			["Parent"] = self._ScreenGui.Container.ScrollingFrame
		},

		create(
			"UIListLayout", {
				["HorizontalAlignment"] = Enum.HorizontalAlignment.Center,
				["Padding"] = UDim.new(0, 5)
			}
		),

		create(
			"UIPadding", {
				["PaddingBottom"] = UDim.new(0, 10),
				["PaddingTop"] = UDim.new(0, 10),
				["PaddingLeft"] = UDim.new(0, 10),
				["PaddingRight"] = UDim.new(0, 10),
			}
		)
	)

	-- Make tab button
	local tab: TextButton = create(
		"TextButton", {
			["Name"] = module_name,
			["BackgroundColor3"] = COLOR_C,
			["Font"] = Enum.Font.SourceSans,
			["Text"] = module_name,
			["TextColor3"] = Color3.fromRGB(255, 255, 255),
			["TextScaled"] = true,
			["Size"] = UDim2.new(0, 80, 1, 0),
			["AutoButtonColor"] = false,
			["LayoutOrder"] = 1,
		},

		create(
			"UIStroke", {
				["Color"] = COLOR_D,
				["ApplyStrokeMode"] = Enum.ApplyStrokeMode.Border
			}
		)
	)

	if not self._current_env or self._current_env ~= env_type then
		tab.Visible = false
	end

	tab.Parent = self._ScreenGui.Container.TabContainer[env_type]

	-- if not self._current_tab then
	--     self:_SelectTab(module_name)
	-- end

	tab.MouseEnter:Connect(function()
		self:_HoverStart(tab)
	end)

	tab.MouseLeave:Connect(function()
		self:_HoverStop(tab)
	end)

	tab.MouseButton1Click:Connect(function()
		self:_SelectTab(module_name)
	end)
end

function configify_ui:_SelectEnvironment(env_name)
	local container = self._ScreenGui.Container
	local other_env = env_name == "Client" and "Server" or "Client"

	if self._current_env and self._current_env == env_name then
		return
	end

	if self._current_tab then
		self:_SelectTab(nil)
	end

	set_visible(container.TabContainer[other_env], false)
	set_visible(container.TabContainer[env_name], true)

	self._current_env = env_name
end

function configify_ui:_SelectTab(tab_name)
	local scrolling_frame = self._ScreenGui.Container.ScrollingFrame

	if self._current_tab then
		set_visible(scrolling_frame[self._current_tab], false)
	end

	self._current_tab = tab_name

	if tab_name then
		set_visible(scrolling_frame[tab_name], true)
	end
end

function configify_ui:UpdateConfig(att_name, tab_name, value)
	local config = self._ScreenGui.Container.ScrollingFrame[tab_name][att_name]

	if config:IsA("Frame") then -- string
		config.TextBox.Text = value
	elseif config:IsA("TextButton") then -- number/bool
		local amt = config:FindFirstChild("Amount")

		if amt then -- number
			local min = config:GetAttribute("Min")
			local max = config:GetAttribute("Max")
			local slider = config.SliderContainer.SliderBG.Slider
			local percent = (value - min) / (max - min)

			amt.Text = value
			slider.Size = UDim2.fromScale(percent, 1)
		else -- bool
			config.ToggleBtn.BackgroundTransparency = value == true and 0 or 1
		end
	end
end

function configify_ui:AddConfig(att_name, initial, min, max, module_name)
	local initial_type = typeof(initial)
	local config = nil

	if initial_type == "number" then
		config = self:_CreateSliderConfig(att_name, initial, min, max)
	elseif initial_type == "boolean" then
		config = self:_CreateToggleConfig(att_name, initial, min, max)
	elseif initial_type == "string" then
		config = self:_CreateEntryConfig(att_name, initial)
	elseif initial_type == "function" then
		config = self:_CreateFunctionConfig(att_name, initial)
	else
		warn("This type isn't implemented yet")
		return
	end

	config.Parent = self._ScreenGui.Container.ScrollingFrame:FindFirstChild(module_name)
end

function configify_ui:_CreateFunctionConfig(att_name, fn)
	local config: TextButton = create(
		"TextButton", {
			["Name"] = att_name,
			["Size"] = UDim2.new(1, 0, 0, 20),
			["BackgroundColor3"] = COLOR_C,
			["Text"] = "",
			["AutoButtonColor"] = false,
			["Visible"] = false
		},

		create(
			"UIStroke", {
				["Color"] = COLOR_D,
				["ApplyStrokeMode"] = Enum.ApplyStrokeMode.Border
			}
		),

		create(
			"TextLabel", {
				["Name"] = att_name,
				["AnchorPoint"] = Vector2.new(0, 0.5),
				["Position"] = UDim2.new(0, 3, 0.5, 0),
				["BackgroundTransparency"] = 1,
				["Size"] = UDim2.new(1, -23, 0, 16),
				["Font"] = Enum.Font.SourceSans,
				["Text"] = att_name,
				["TextColor3"] = Color3.fromRGB(255, 255, 255),
				["TextScaled"] = true,
			}
		)
	)

	config.MouseEnter:Connect(function(x, y)
		self:_HoverStart(config)
	end)

	config.MouseLeave:Connect(function(x, y)
		self:_HoverStop(config)
	end)

	config.MouseButton1Click:Connect(function()
		fn()
		-- local env = get_env_from_config_element(self, config)
		-- self.UIChanged:Fire(att_name, fn, env)
	end)

	return config
end

function configify_ui:_CreateSliderConfig(att_name, initial, min, max)
	local config: TextButton = create(
		"TextButton", {
			["Name"] = att_name,
			["Size"] = UDim2.new(1, 0, 0, 30),
			["BackgroundColor3"] = COLOR_C,
			["Text"] = "",
			["AutoButtonColor"] = false,
			["Visible"] = false
		},

		create(
			"UIStroke", {
				["Color"] = COLOR_D,
				["ApplyStrokeMode"] = Enum.ApplyStrokeMode.Border
			}
		),

		create(
			"TextLabel", {
				["Name"] = att_name,
				["BackgroundTransparency"] = 1,
				["Size"] = UDim2.new(1, 0, 0, 15),
				["Font"] = Enum.Font.SourceSans,
				["Text"] = att_name,
				["TextColor3"] = Color3.fromRGB(255, 255, 255),
				["TextScaled"] = true,
			}
		),

		create(
			"TextLabel", {
				["Name"] = "Amount",
				["Position"] = UDim2.new(0, 0, 0, 12),
				["Size"] = UDim2.new(1, 0, 0, 20),
				["ZIndex"] = 2,
				["BackgroundTransparency"] = 1,
				["Font"] = Enum.Font.SourceSans,
				["Text"] = initial,
				["TextColor3"] = Color3.fromRGB(255, 255, 255),
				["TextScaled"] = true,
				["TextStrokeTransparency"] = 0.2,
			}
		),

		create(
			"Frame", {
				["Name"] = "SliderContainer",
				["BackgroundTransparency"] = 1,
				["Position"] = UDim2.fromOffset(0, 15),
				["Size"] = UDim2.new(1, 0, 0, 15),
			},

			create(
				"UIPadding", {
					["PaddingBottom"] = UDim.new(0, 4),
					["PaddingTop"] = UDim.new(0, 4),
					["PaddingLeft"] = UDim.new(0, 5),
					["PaddingRight"] = UDim.new(0, 5),
				}
			),

			create(
				"Frame", {
					["Name"] = "SliderBG",
					["BackgroundColor3"] = COLOR_B,
					["Size"] = UDim2.fromScale(1, 1),
				},

				create(
					"UICorner", {
						["CornerRadius"] = UDim.new(1, 0)
					}
				),

				create(
					"UIStroke", {
						["ApplyStrokeMode"] = Enum.ApplyStrokeMode.Border,
						["Color"] = COLOR_D,
						["LineJoinMode"] = Enum.LineJoinMode.Round,
						["Thickness"] = 1,
						["Transparency"] = 0.4,
					}
				),

				create(
					"Frame", {
						["Name"] = "Slider",
						["BackgroundColor3"] = COLOR_A,
						["Size"] = UDim2.fromScale(0.5, 1),
					},

					create(
						"UICorner", {
							["CornerRadius"] = UDim.new(1, 0)
						}
					)
				)
			)
		)
	)

	config:SetAttribute("Min", min)
	config:SetAttribute("Max", max)

	--Initialize slider size based off initial
	local slider_container = config.SliderContainer
	local slider_bg = slider_container.SliderBG
	local slider = slider_bg.Slider
	local percent = (initial - min) / (max - min)
	slider.Size = UDim2.fromScale(percent, 1)

	config.MouseEnter:Connect(function(x, y)
		self:_HoverStart(config)
	end)

	config.MouseLeave:Connect(function(x, y)
		self:_HoverStop(config)
	end)

	config.MouseButton1Down:Connect(function()
		self:_SliderStart(config, min, max)
	end)

	return config
end

function configify_ui:_CreateToggleConfig(att_name, initial, min, max)
	local config: TextButton = create(
		"TextButton", {
			["Name"] = att_name,
			["Size"] = UDim2.new(1, 0, 0, 20),
			["BackgroundColor3"] = COLOR_C,
			["Text"] = "",
			["AutoButtonColor"] = false,
			["Visible"] = false
		},

		create(
			"UIStroke", {
				["Color"] = COLOR_D,
				["ApplyStrokeMode"] = Enum.ApplyStrokeMode.Border
			}
		),

		create(
			"TextLabel", {
				["Name"] = att_name,
				["AnchorPoint"] = Vector2.new(0, 0.5),
				["Position"] = UDim2.new(0, 3, 0.5, 0),
				["BackgroundTransparency"] = 1,
				["Size"] = UDim2.new(1, -23, 0, 16),
				["Font"] = Enum.Font.SourceSans,
				["Text"] = att_name,
				["TextColor3"] = Color3.fromRGB(255, 255, 255),
				["TextScaled"] = true,
				["TextXAlignment"] = Enum.TextXAlignment.Left,
			}
		),

		create(
			"ImageButton", {
				["Name"] = "ToggleBtn",
				["ImageTransparency"] = 1,
				["BackgroundTransparency"] = 1,
				["BackgroundColor3"] = COLOR_TRUE,
				["Size"] = UDim2.fromOffset(11, 11),
				["AnchorPoint"] = Vector2.new(1, 0.5),
				["Position"] = UDim2.new(1, -5, 0.5, 0),
			},

			create(
				"UIStroke", {
					["Color"] = COLOR_D
				}
			)
		)
	)

	if initial == true then
		config:SetAttribute("Active", true)
		config.ToggleBtn.BackgroundTransparency = 0
	else
		config:SetAttribute("Active", false)
		config.ToggleBtn.BackgroundTransparency = 1
	end

	config.MouseEnter:Connect(function(x, y)
		self:_HoverStart(config)
	end)

	config.MouseLeave:Connect(function(x, y)
		self:_HoverStop(config)
	end)

	config.MouseButton1Click:Connect(function()
		self:_ConfigToggleClick(config)
	end)

	return config
end

function configify_ui:_CreateEntryConfig(att_name, initial)
	local config: Frame = create(
		"Frame", {
			["Name"] = att_name,
			["BackgroundColor3"] = COLOR_C,
			["Size"] = UDim2.new(1, 0, 0, 45),
			["Visible"] = false,
		},

		create(
			"UIStroke", {
				["Color"] = COLOR_D,
				["ApplyStrokeMode"] = Enum.ApplyStrokeMode.Border
			}
		),

		create(
			"UIPadding", {
				["PaddingTop"] = UDim.new(0, 3),
				["PaddingBottom"] = UDim.new(0, 5),
				["PaddingLeft"] = UDim.new(0, 5),
				["PaddingRight"] = UDim.new(0, 5)
			}
		),

		create(
			"TextLabel", {
				["Name"] = "Title",
				["BackgroundTransparency"] = 1,
				["Size"] = UDim2.new(1, 0, 0.4, 0),
				["Text"] = att_name,
				["TextColor3"] = COLOR_E,
				["TextScaled"] = true,
				["TextYAlignment"] = Enum.TextYAlignment.Top
			}
		),

		create(
			"TextBox", {
				["AnchorPoint"] = Vector2.new(0, 1),
				["Position"] = UDim2.new(0, 0, 1, 0),
				["Size"] = UDim2.new(1, 0, 0.6, -3),
				["Text"] = initial,
				["Font"] = Enum.Font.SourceSans,
				["BackgroundColor3"] = COLOR_B,
				["TextScaled"] = true,
				["TextColor3"] = COLOR_E,
				["PlaceholderText"] = "Enter a value.",
				["ClearTextOnFocus"] = false,
				["PlaceholderColor3"] = COLOR_A,
				["TextXAlignment"] = Enum.TextXAlignment.Left,
				["Visible"] = true,
			}
		)
	)

	local TextBox: TextBox = config.TextBox

	TextBox.FocusLost:Connect(function(enterPressed, inputThatCausedFocusLoss)
		if not enterPressed then
			return
		end

		self:_ConfigEntrySubmit(TextBox)
	end)

	config.MouseEnter:Connect(function(x, y)
		self:_HoverStart(config)
	end)

	config.MouseLeave:Connect(function(x, y)
		self:_HoverStop(config)
	end)

	return config
end

function configify_ui:_HoverStart(ui_object)
	for i, v in ui_object:GetDescendants() do
		if v:IsA("UIStroke") then
			v.Color = COLOR_E
		end
	end
end

function configify_ui:_HoverStop(ui_object)
	for i, v in ui_object:GetDescendants() do
		if v:IsA("UIStroke") then
			v.Color = COLOR_D
		end
	end
end

function configify_ui:_ConfigToggleClick(ui_object)
	local Active = ui_object:GetAttribute("Active")

	if Active then
		ui_object:SetAttribute("Active", false)
		ui_object.ToggleBtn.BackgroundTransparency = 1
	else
		ui_object:SetAttribute("Active", true)
		ui_object.ToggleBtn.BackgroundTransparency = 0
	end

	local env = get_env_from_config_element(self, ui_object)

	self.UIChanged:Fire(ui_object.Name, ui_object:GetAttribute("Active"), env)
end

function configify_ui:_ConfigEntrySubmit(ui_object)
	local env = get_env_from_config_element(self, ui_object.Parent)

	local config_name = ui_object.Parent.Name -- textbox inside frame
	local current_value = ui_object.Text

	self.UIChanged:Fire(config_name, current_value, env)
end

function configify_ui:_SliderStart(ui_object, min, max)
	local slider_container = ui_object.SliderContainer
	local slider_bg = slider_container.SliderBG
	local slider = slider_bg.Slider

	slider.BackgroundColor3 = COLOR_D

	runservice:BindToRenderStep("Configify_SliderStart", Enum.RenderPriority.Last.Value + 10, function(dt)
		local diff = mouse.X - slider_bg.AbsolutePosition.X
		local percent = math.clamp(diff / slider_bg.AbsoluteSize.X, 0, 1)
		local n = min + (max - min) * percent

		slider.Size = UDim2.fromScale(percent, 1)
		ui_object.Amount.Text = string.format("%.2f", n)
	end)

	local c1
	local c2

	c1 = uis.WindowFocusReleased:Connect(function()
		c1:Disconnect()
		c2:Disconnect()
		c1 = nil
		c2 = nil

		self:_SliderStop(ui_object)
	end)

	c2 = uis.InputEnded:Connect(function(input, gpe)
		if not (input.UserInputType == Enum.UserInputType.MouseButton1) then
			return
		end

		c1:Disconnect()
		c2:Disconnect()
		c1 = nil
		c2 = nil

		self:_SliderStop(ui_object)
	end)
end

function configify_ui:_SliderStop(ui_object)
	local slider_container = ui_object.SliderContainer
	local slider_bg = slider_container.SliderBG
	local slider = slider_bg.Slider

	slider.BackgroundColor3 = COLOR_A

	runservice:UnbindFromRenderStep("Configify_SliderStart")

	local env = get_env_from_config_element(self, ui_object)

	self.UIChanged:Fire(ui_object.Name, ui_object.Amount.Text, env)
end

function configify_ui:Toggle()
	if not self._ScreenGui then
		return
	end

	self._ScreenGui.Enabled = not self._ScreenGui.Enabled
end
