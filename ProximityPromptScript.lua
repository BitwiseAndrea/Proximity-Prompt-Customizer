local UserInputService = game:GetService("UserInputService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local GamepadButtonImage = {
	[Enum.KeyCode.ButtonX] = "rbxasset://textures/ui/Controls/xboxX.png",
	[Enum.KeyCode.ButtonY] = "rbxasset://textures/ui/Controls/xboxY.png",
	[Enum.KeyCode.ButtonA] = "rbxasset://textures/ui/Controls/xboxA.png",
	[Enum.KeyCode.ButtonB] = "rbxasset://textures/ui/Controls/xboxB.png",
	[Enum.KeyCode.DPadLeft] = "rbxasset://textures/ui/Controls/dpadLeft.png",
	[Enum.KeyCode.DPadRight] = "rbxasset://textures/ui/Controls/dpadRight.png",
	[Enum.KeyCode.DPadUp] = "rbxasset://textures/ui/Controls/dpadUp.png",
	[Enum.KeyCode.DPadDown] = "rbxasset://textures/ui/Controls/dpadDown.png",
	[Enum.KeyCode.ButtonSelect] = "rbxasset://textures/ui/Controls/xboxmenu.png",
	[Enum.KeyCode.ButtonL1] = "rbxasset://textures/ui/Controls/xboxLS.png",
	[Enum.KeyCode.ButtonR1] = "rbxasset://textures/ui/Controls/xboxRS.png",
}

local KeyboardButtonImage = {
	[Enum.KeyCode.Backspace] = "rbxasset://textures/ui/Controls/backspace.png",
	[Enum.KeyCode.Return] = "rbxasset://textures/ui/Controls/return.png",
	[Enum.KeyCode.LeftShift] = "rbxasset://textures/ui/Controls/shift.png",
	[Enum.KeyCode.RightShift] = "rbxasset://textures/ui/Controls/shift.png",
	[Enum.KeyCode.Tab] = "rbxasset://textures/ui/Controls/tab.png",
}

local KeyboardButtonIconMapping = {
	["'"] = "rbxasset://textures/ui/Controls/apostrophe.png",
	[","] = "rbxasset://textures/ui/Controls/comma.png",
	["`"] = "rbxasset://textures/ui/Controls/graveaccent.png",
	["."] = "rbxasset://textures/ui/Controls/period.png",
	[" "] = "rbxasset://textures/ui/Controls/spacebar.png",
}

local KeyCodeToTextMapping = {
	[Enum.KeyCode.LeftControl] = "Ctrl",
	[Enum.KeyCode.RightControl] = "Ctrl",
	[Enum.KeyCode.LeftAlt] = "Alt",
	[Enum.KeyCode.RightAlt] = "Alt",
	[Enum.KeyCode.F1] = "F1",
	[Enum.KeyCode.F2] = "F2",
	[Enum.KeyCode.F3] = "F3",
	[Enum.KeyCode.F4] = "F4",
	[Enum.KeyCode.F5] = "F5",
	[Enum.KeyCode.F6] = "F6",
	[Enum.KeyCode.F7] = "F7",
	[Enum.KeyCode.F8] = "F8",
	[Enum.KeyCode.F9] = "F9",
	[Enum.KeyCode.F10] = "F10",
	[Enum.KeyCode.F11] = "F11",
	[Enum.KeyCode.F12] = "F12",
	[Enum.KeyCode.PageUp] = "PgUp",
	[Enum.KeyCode.PageDown] = "PgDn",
	[Enum.KeyCode.Home] = "Home",
	[Enum.KeyCode.End] = "End",
	[Enum.KeyCode.Insert] = "Ins",
	[Enum.KeyCode.Delete] = "Del",
}

local function getScreenGui()
	local screenGui = PlayerGui:FindFirstChild("ProximityPrompts")
	if screenGui == nil then
		screenGui = Instance.new("ScreenGui")
		screenGui.Name = "ProximityPrompts"
		screenGui.ResetOnSpawn = false
		screenGui.Parent = PlayerGui
	end
	return screenGui
end

local function setUpCircularProgressBar(bar)
	local leftGradient = bar.LeftGradient.ProgressBarImage.UIGradient
	local rightGradient = bar.RightGradient.ProgressBarImage.UIGradient

	local progress = bar.Progress
	progress.Changed:Connect(function(value)
		local angle = math.clamp(value * 360, 0, 360)
		leftGradient.Rotation = math.clamp(angle, 180, 360)
		rightGradient.Rotation = math.clamp(angle, 0, 180)
	end)
end

local function createPrompt(prompt, inputType, gui)
	local fastTime = 0.2
	local tweensForButtonHoldBegin = {}
	local tweensForButtonHoldEnd = {}
	local tweensForFadeOut = {}
	local tweensForFadeIn = {}
	local tweenInfoInFullDuration = TweenInfo.new(prompt.HoldDuration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
	local tweenInfoFast = TweenInfo.new(fastTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tweenInfoQuick = TweenInfo.new(0.06, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
	local tweenInfoInstant = TweenInfo.new(0, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)

	local promptUI = nil
	local promptTheme = prompt:GetAttribute("Theme")
	if promptTheme then
		local themedPromptUI = script:FindFirstChild(promptTheme)
		if themedPromptUI then
			promptUI = themedPromptUI:Clone()
		end
	end

	if promptUI == nil then
		promptUI = script.Default:Clone()
	end

	promptUI.Enabled = true

	local frame = promptUI.PromptFrame
	local listLayout = frame.UIListLayout
	local padding = frame.UIPadding
	local inputFrame = frame.InputFrame
	local textFrame = frame.TextFrame
	local actionText = textFrame.ActionText
	local objectText = textFrame.ObjectText
	
	-- We need to save this value for later :)
	local initialPaddingRight = padding.PaddingRight

	-- Tween helper functions
	local function setupUIStrokeTweens(uiStroke)
		local transparency = uiStroke.Transparency
		uiStroke.Transparency = 1
		table.insert(tweensForButtonHoldBegin, TweenService:Create(uiStroke, tweenInfoFast, { Transparency = 1 }))
		table.insert(tweensForButtonHoldEnd, TweenService:Create(uiStroke, tweenInfoFast, { Transparency = transparency }))
		table.insert(tweensForFadeOut, TweenService:Create(uiStroke, tweenInfoFast, { Transparency = 1 }))
		table.insert(tweensForFadeIn, TweenService:Create(uiStroke, tweenInfoFast, { Transparency = transparency }))
	end

	local function setupGUIObjectTweens(guiObject)
		local guiObjectBackgroundTransparency = guiObject.BackgroundTransparency
		guiObject.BackgroundTransparency = 1
		table.insert(tweensForButtonHoldBegin, TweenService:Create(guiObject, tweenInfoFast, { BackgroundTransparency = 1 }))
		table.insert(tweensForButtonHoldEnd, TweenService:Create(guiObject, tweenInfoFast, { BackgroundTransparency = guiObjectBackgroundTransparency }))
		table.insert(tweensForFadeOut, TweenService:Create(guiObject, tweenInfoFast, { BackgroundTransparency = 1 }))
		table.insert(tweensForFadeIn, TweenService:Create(guiObject, tweenInfoFast, { BackgroundTransparency = guiObjectBackgroundTransparency }))
	end

	local function setupTextLabelTweens(textLabel)
		local textTransparency = textLabel.TextTransparency
		local textStrokeTransparency = textLabel.TextStrokeTransparency
		textLabel.TextTransparency = 1
		textLabel.TextStrokeTransparency = 1
		table.insert(tweensForButtonHoldBegin, TweenService:Create(textLabel, tweenInfoFast, { TextTransparency = 1, TextStrokeTransparency = 1 }))
		table.insert(tweensForButtonHoldEnd, TweenService:Create(textLabel, tweenInfoFast, { TextTransparency = textTransparency, TextStrokeTransparency = textStrokeTransparency }))
		table.insert(tweensForFadeOut, TweenService:Create(textLabel, tweenInfoFast, { TextTransparency = 1, TextStrokeTransparency = 1 }))
		table.insert(tweensForFadeIn, TweenService:Create(textLabel, tweenInfoFast, { TextTransparency = textTransparency, TextStrokeTransparency = textStrokeTransparency }))
	end

	local function setupImageLabelTweens(imageLabel)
		local imageTransparency = imageLabel.ImageTransparency
		imageLabel.ImageTransparency = 1
		table.insert(tweensForButtonHoldBegin, TweenService:Create(imageLabel, tweenInfoFast, { ImageTransparency = 1 }))
		table.insert(tweensForButtonHoldEnd, TweenService:Create(imageLabel, tweenInfoFast, { ImageTransparency = imageTransparency }))
		table.insert(tweensForFadeOut, TweenService:Create(imageLabel, tweenInfoFast, { ImageTransparency = 1 }))
		table.insert(tweensForFadeIn, TweenService:Create(imageLabel, tweenInfoFast, { ImageTransparency = imageTransparency }))
	end
	
	-- Tweens for Frame and children
	setupImageLabelTweens(frame)
	setupGUIObjectTweens(frame)
	
	local listLayoutPadding = listLayout.Padding
	listLayout.Padding = UDim.new(-0.25, 0)
	table.insert(tweensForButtonHoldBegin, TweenService:Create(listLayout, tweenInfoFast, { Padding = UDim.new(-0.25, 0) }))
	table.insert(tweensForButtonHoldEnd, TweenService:Create(listLayout, tweenInfoFast, { Padding = listLayoutPadding }))
	table.insert(tweensForFadeOut, TweenService:Create(listLayout, tweenInfoFast, { Padding = UDim.new(-0.25, 0) }))
	table.insert(tweensForFadeIn, TweenService:Create(listLayout, tweenInfoFast, { Padding = listLayoutPadding }))


	local function setupUnexpectedChildTweens(child)
		if child:IsA("UIStroke") then
			setupUIStrokeTweens(child)
		elseif child:IsA("UIGradient") then
			-- The Transparency property of UIGradients is not tweenable
		elseif child:IsA("GuiObject") then
			setupGUIObjectTweens(child)

			if child:IsA("TextLabel") then
				setupTextLabelTweens(child)
			elseif child:IsA("ImageLabel") then
				setupImageLabelTweens(child)
			end
		end

		for _, grandChild in pairs(child:GetChildren()) do
			setupUnexpectedChildTweens(grandChild)
		end
	end

	local function handleUnexpectedChildren(parent, expectedChildrenDict)
		for _, child in pairs(parent:GetChildren()) do
			local expectedChildren = expectedChildrenDict[child]
			if expectedChildren == nil then
				-- Unexpected child of the frame and direct children elements
				setupUnexpectedChildTweens(child)
			elseif expectedChildren == true then
				for _, grandChild in pairs(child:GetChildren()) do
					setupUnexpectedChildTweens(grandChild)
				end
			elseif expectedChildren ~= false then
				-- Assert typeof expectedChildren is table
				handleUnexpectedChildren(child, expectedChildren)
			end
		end
	end
	
	-- Key is UI object, value is whether or not we should tween out the children of it in the same manner,
	-- or the children of that frame to handle in the same way? thats the best explanation i have ok
	local expectedFrameChildren = {[inputFrame] = false, [textFrame] = { [actionText] = true, [objectText] = true }}
	handleUnexpectedChildren(frame, expectedFrameChildren)

	-- Tweens for InputFrame
	local resizeableInputFrame = inputFrame.Frame
	local inputFrameScaler = resizeableInputFrame.UIScale
	local inputFrameScaleFactor = inputType == Enum.ProximityPromptInputType.Touch and 1.6 or 1.33
	table.insert(tweensForButtonHoldBegin, TweenService:Create(inputFrameScaler, tweenInfoFast, { Scale = inputFrameScaleFactor }))
	table.insert(tweensForButtonHoldEnd, TweenService:Create(inputFrameScaler, tweenInfoFast, { Scale = 1 }))

	-- Tweens for ActionText and ObjectText
	setupTextLabelTweens(actionText)
	setupTextLabelTweens(objectText)

	local buttonFrame = resizeableInputFrame.ButtonFrame

	local function setupButtonFrameTweens()
		local buttonFrameBackgroundTransparency = buttonFrame.BackgroundTransparency
		local buttonFrameImageTransparency = buttonFrame.ImageTransparency

		table.insert(tweensForFadeOut, TweenService:Create(buttonFrame, tweenInfoQuick, { BackgroundTransparency = 1, ImageTransparency = 1 }))
		table.insert(tweensForFadeIn, TweenService:Create(buttonFrame, tweenInfoQuick, { BackgroundTransparency = buttonFrameBackgroundTransparency, ImageTransparency = buttonFrameImageTransparency }))

		for _, child in pairs(buttonFrame:getChildren()) do
			if child:IsA("UIStroke") then
				local transparency = child.Transparency
				table.insert(tweensForFadeOut, TweenService:Create(child, tweenInfoQuick, { Transparency = 1 }))
				table.insert(tweensForFadeIn, TweenService:Create(child, tweenInfoQuick, { Transparency = transparency }))
			end
			-- Currently not supporting any other children other than UIStroke
		end
	end
	setupButtonFrameTweens()

	local icon = resizeableInputFrame.ButtonTextImage
	local buttonImage = resizeableInputFrame.ButtonImage
	local buttonText = buttonImage.ButtonText

	local function setupButtonTextTweens()
		local textTransparency = buttonText.TextTransparency
		local textStrokeTransparency = buttonText.TextStrokeTransparency
		local textBackgroundTransparency = buttonText.BackgroundTransparency
		buttonText.BackgroundTransparency = 1
		buttonText.TextStrokeTransparency = 1
		buttonText.TextTransparency = 1
		table.insert(tweensForFadeOut, TweenService:Create(buttonText, tweenInfoQuick, { TextTransparency = 1, TextStrokeTransparency = 1, BackgroundTransparency = 1 }))
		table.insert(tweensForFadeIn, TweenService:Create(buttonText, tweenInfoQuick, { TextTransparency = textTransparency, TextStrokeTransparency = textStrokeTransparency, BackgroundTransparency = textBackgroundTransparency }))

		for _, child in pairs(buttonText:getChildren()) do
			if child:IsA("UIStroke") then
				local transparency = child.Transparency
				table.insert(tweensForFadeOut, TweenService:Create(child, tweenInfoQuick, { Transparency = 1 }))
				table.insert(tweensForFadeIn, TweenService:Create(child, tweenInfoQuick, { Transparency = transparency }))
			end
			-- Currently not supporting any other children other than UIStroke
		end
	end

	local function setupButtonImageTweens()
		local buttonImageTransparency = buttonImage.ImageTransparency
		local buttonImageBackgroundTransparency = buttonImage.BackgroundTransparency
		buttonImage.BackgroundTransparency = 1
		buttonImage.ImageTransparency = 1
		table.insert(tweensForFadeOut, TweenService:Create(buttonImage, tweenInfoQuick, { ImageTransparency = 1, BackgroundTransparency = 1 }))
		table.insert(tweensForFadeIn, TweenService:Create(buttonImage, tweenInfoQuick, { ImageTransparency = buttonImageTransparency, BackgroundTransparency = buttonImageBackgroundTransparency }))
	end

	local function setupIconTweens()
		local iconBackgroundTransparency = icon.BackgroundTransparency
		local iconImageTransparency = icon.ImageTransparency
		icon.BackgroundTransparency = 1
		icon.ImageTransparency = 1
		table.insert(tweensForFadeOut, TweenService:Create(icon, tweenInfoQuick, { ImageTransparency = 1, BackgroundTransparency = 1 }))
		table.insert(tweensForFadeIn, TweenService:Create(icon, tweenInfoQuick, { ImageTransparency = iconImageTransparency, BackgroundTransparency = iconBackgroundTransparency }))
	end

	if inputType == Enum.ProximityPromptInputType.Gamepad then
		if GamepadButtonImage[prompt.GamepadKeyCode] then
			setupIconTweens()
			icon.Image = GamepadButtonImage[prompt.GamepadKeyCode]

			-- Hide ButtonText and ButtonImage, show ButtonTextImage
			buttonText.Visible = false
			buttonImage.Visible = false
			icon.Visible = true	
		end
	elseif inputType == Enum.ProximityPromptInputType.Touch then
		setupButtonImageTweens()
		buttonImage.Image = "rbxasset://textures/ui/Controls/TouchTapIcon.png"

		-- Hide ButtonText and ButtonTextImage, show ButtonImage
		buttonText.Visible = false
		icon.Visible = false
		buttonImage.Visible = true	
	else
		setupButtonImageTweens()

		-- Show ButtonImage
		buttonImage.Visible = true

		local buttonTextString = UserInputService:GetStringForKeyCode(prompt.KeyboardKeyCode)

		local buttonTextImage = KeyboardButtonImage[prompt.KeyboardKeyCode]
		if buttonTextImage == nil then
			buttonTextImage = KeyboardButtonIconMapping[buttonTextString]
		end

		if buttonTextImage == nil then
			local keyCodeMappedText = KeyCodeToTextMapping[prompt.KeyboardKeyCode]
			if keyCodeMappedText then
				buttonTextString = keyCodeMappedText
			end
		end

		if buttonTextImage then
			setupIconTweens()
			icon.Image = buttonTextImage

			--  Hide ButtonText, show ButtonTextImage
			buttonText.Visible = false
			icon.Visible = true
		elseif buttonTextString ~= nil and buttonTextString ~= '' then
			setupButtonTextTweens()
			buttonText.Text = buttonTextString

			-- Hide ButtonTextImage, show ButtonText
			icon.Visible = false
			buttonText.Visible = true
		else
			error("ProximityPrompt '" .. prompt.Name .. "' has an unsupported keycode for rendering UI: " .. tostring(prompt.KeyboardKeyCode))
		end
	end

	if inputType == Enum.ProximityPromptInputType.Touch or prompt.ClickablePrompt then
		local button = promptUI.TextButton

		local buttonDown = false

		button.InputBegan:Connect(function(input)
			if (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1) and
				input.UserInputState ~= Enum.UserInputState.Change then
				prompt:InputHoldBegin()
				buttonDown = true
			end
		end)
		button.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
				if buttonDown then
					buttonDown = false
					prompt:InputHoldEnd()
				end
			end
		end)

		promptUI.Active = true
	end

	if prompt.HoldDuration > 0 then
		local circleBar = resizeableInputFrame.ProgressBar
		setUpCircularProgressBar(circleBar)
		table.insert(tweensForButtonHoldBegin, TweenService:Create(circleBar.Progress, tweenInfoInFullDuration, { Value = 1 }))
		table.insert(tweensForButtonHoldEnd, TweenService:Create(circleBar.Progress, tweenInfoInstant, { Value = 0 }))
	end

	local holdBeganConnection
	local holdEndedConnection
	local triggeredConnection
	local triggerEndedConnection

	if prompt.HoldDuration > 0 then
		holdBeganConnection = prompt.PromptButtonHoldBegan:Connect(function()
			for _, tween in ipairs(tweensForButtonHoldBegin) do
				tween:Play()
			end
		end)

		holdEndedConnection = prompt.PromptButtonHoldEnded:Connect(function()
			for _, tween in ipairs(tweensForButtonHoldEnd) do
				tween:Play()
			end
		end)
	end

	triggeredConnection = prompt.Triggered:Connect(function()
		for _, tween in ipairs(tweensForFadeOut) do
			tween:Play()
		end
	end)

	triggerEndedConnection = prompt.TriggerEnded:Connect(function()
		for _, tween in ipairs(tweensForFadeIn) do
			tween:Play()
		end
	end)
	
	local function syncPromptSize()
		promptUI.Size = UDim2.fromOffset(frame.AbsoluteSize.X, frame.AbsoluteSize.Y)
		promptUI.SizeOffset = Vector2.new(prompt.UIOffset.X / promptUI.Size.Width.Offset, prompt.UIOffset.Y / promptUI.Size.Height.Offset)
	end
	
	local function updateUIFromPrompt()
		promptUI.Enabled = prompt.Enabled
		
		local hasActionText = prompt.ActionText ~= nil and prompt.ActionText ~= ''
		local hasObjectText = prompt.ObjectText ~= nil and prompt.ObjectText ~= ''
		local hasText = hasActionText or hasObjectText
		textFrame.Visible = hasText
		objectText.Visible = hasObjectText

		actionText.Text = prompt.ActionText
		objectText.Text = prompt.ObjectText
		actionText.AutoLocalize = prompt.AutoLocalize
		actionText.RootLocalizationTable = prompt.RootLocalizationTable
		objectText.AutoLocalize = prompt.AutoLocalize
		objectText.RootLocalizationTable = prompt.RootLocalizationTable

		if not hasText then
			-- Automatic size destroyed me so we are just going to set the padding
			-- on the right equal to the padding on the left if there is no text
			padding.PaddingRight = padding.PaddingLeft
		else
			padding.PaddingRight = initialPaddingRight
		end

		-- BillboardGuis can't be sized based on their content, so we need to calculate
		-- the size based on the automatically sized prompt frame. The size of the BillboardGui
		-- is important because the text button won't receive input unless it's within it's bounds.
		syncPromptSize()
		task.defer(function ()
			syncPromptSize()
			wait(fastTime)
			syncPromptSize()
		end)
	end

	local changedConnection = prompt.Changed:Connect(updateUIFromPrompt)
	updateUIFromPrompt()

	promptUI.Adornee = prompt.Parent
	promptUI.Parent = gui

	for _, tween in ipairs(tweensForFadeIn) do
		tween:Play()
	end

	local function cleanup()
		if holdBeganConnection then
			holdBeganConnection:Disconnect()
		end

		if holdEndedConnection then
			holdEndedConnection:Disconnect()
		end

		triggeredConnection:Disconnect()
		triggerEndedConnection:Disconnect()
		changedConnection:Disconnect()

		for _, tween in ipairs(tweensForFadeOut) do
			tween:Play()
		end

		wait(fastTime)

		promptUI.Parent = nil
	end

	return cleanup
end

local function onLoad()
	ProximityPromptService.PromptShown:Connect(function(prompt, inputType)
		if prompt.Style == Enum.ProximityPromptStyle.Default then
			return
		end
		
		local gui = getScreenGui()

		local cleanupFunction = createPrompt(prompt, inputType, gui)

		prompt.PromptHidden:Wait()

		cleanupFunction()
	end)
end

onLoad()
