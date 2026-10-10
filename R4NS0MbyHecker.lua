-- DOORS Compatible GUI + Spawn Sound + Fixed Movement Detection (R4NS0M Title + Custom Pop-up Names + Shaking Popups + Honeypot + Tiny Coin Bits)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
local playerGui = player:WaitForChild("PlayerGui")

-- SOUND SETTINGS
local JUMPSCARE_SOUND_ID = 80491955969050 -- phase 1 + 2 jumpscare / downloading sound (plays fully, never cut off)[cite: 1]
local VICTORY_SOUND_ID = 124923188934894 -- victory pop-up sound[cite: 1]
local THEME_SOUND_ID = 135885597215283 -- theme song (only plays while the R4NS0M window is on screen)[cite: 1]
local THEME_SPEED = 0.1 -- starting speed (it is auto-corrected once the length is known)[cite: 1]
local THEME_TARGET_SECONDS = 90 -- the theme is stretched / squeezed to last exactly this long (1:30)[cite: 1]
local THEME_VOLUME = 10 -- loud[cite: 1]
local THEME_EXTEND_JUMPSCARE = false -- true = after the jumpscare audio ends, the FIRST HALF of the theme is cloned in to extend the music[cite: 1]

-- BACKGROUND IMAGE (used for the "Downloading" screen AND the dark bg of the PRE-phase jumpscare)[cite: 1]
local DOWNLOAD_BG_IMAGE_ID = 122867299887975

-- MAIN R4NS0M WINDOW SIZE (the image the tiny coins fly into) - it was 450 x 292[cite: 1]
local WINDOW_WIDTH = 520
local WINDOW_HEIGHT = 338

-- "STAND STILL" WARNING (the corner image -> center images, before the jumpscare)[cite: 1]
local PRE_IMAGE_A = 12350997710 -- shows in the top-left corner, then comes back to the center[cite: 1]
local PRE_IMAGE_B = 12440673966 -- the quick flash in the center[cite: 1]
local PRE_CORNER_TIME = 0.5 -- seconds the image stays in the corner[cite: 1]
local PRE_FLASH_TIME = 0.4 -- seconds the flash image + bg stay in the center[cite: 1]
local PRE_GAP_TIME = 0.4 -- seconds of nothing between the flash and the final stare[cite: 1]
local PRE_STARE_TIME = 0.7 -- seconds the final image stays in the center (with the flickering bg)[cite: 1]
local PRE_CORNER_SIZE = 300 -- size of the corner image (pixels)[cite: 1]
local PRE_CENTER_SIZE = 420 -- size of the center images (pixels)[cite: 1]
local PRE_FLICKER_SPEED = 0.06 -- how fast the bg flickers during the final stare[cite: 1]
local PRE_DETECT_IN_FLASH = false -- false = moving only counts during the final stare (when he is at the center), true = also counts during the flash[cite: 1]

-- COIN MODEL SETTINGS[cite: 1]
local COIN_ASSET_ID = 130662993839681
local COIN_SCALE = 1 -- make bigger/smaller (example: 1.5 or 0.7)[cite: 1]
local COIN_ROTATION = CFrame.Angles(0, 0, 0) -- if the coin lies wrong, try CFrame.Angles(math.rad(90), 0, 0) or CFrame.Angles(0, 0, math.rad(90))[cite: 1]
local COIN_HOVER = 0.15 -- how far the coin floats above the ground[cite: 1]
local PICKUP_DISTANCE = 10 -- how close you must be to see the "Collect Coins" / "Pick Up" option[cite: 1]

-- TINY COINS (the little coin images that burst out when you collect gold and fly into the R4NS0M window)[cite: 1]
local COIN_BIT_IMAGE_ID = 12771100802 -- the tiny coin image[cite: 1]
local COIN_BIT_SIZE_MIN = 45 -- Increased minimum size (pixels)[cite: 1]
local COIN_BIT_SIZE_MAX = 65 -- Increased maximum size (pixels)[cite: 1]
local COIN_BITS_PER_GOLD = 0.4 -- how many tiny coins per gold (500 gold x 0.4 = 200 coins)[cite: 1]
local COIN_BITS_MIN = 10 -- a tiny amount of gold still gives at least this many tiny coins[cite: 1]
local COIN_BITS_MAX = 200
local COIN_BIT_SCATTER_TIME = 1 -- seconds they take to burst out around the coin[cite: 1]
local COIN_BIT_GATHER_TIME = 3.0 -- seconds they hang / gather in the air before flying[cite: 1]
local COIN_BIT_STAGGER = 0.5 -- each coin leaves a random 0 - this many seconds later (so they don't all go at once)[cite: 1]
local COIN_BIT_FLY_MIN = 0.33 -- seconds a coin takes to fly into the window (fastest)[cite: 1]
local COIN_BIT_FLY_MAX = 0.9 -- (slowest)[cite: 1]
local COIN_BIT_SCATTER_MIN = 70 -- how far they burst out (pixels)[cite: 1]
local COIN_BIT_SCATTER_MAX = 150
local COIN_BIT_RECT_IMAGE_ID = 0 -- optional: put an image id here to use as the rectangle on some coins[cite: 1]
local COIN_ARRIVE_SOUND_ID = 103145890200043 -- plays (by chance) when a tiny coin reaches the window[cite: 1]
local COIN_ARRIVE_SOUND_CHANCE = 0.3 -- 30% per tiny coin[cite: 1]
local COIN_ARRIVE_SOUND_VOLUME = 3
local COIN_ARRIVE_SOUND_MIN_GAP = 0.5 -- seconds between those sounds[cite: 1]
local COUNTER_DROP_SPEED = 30 -- how fast the gold counter counts down[cite: 1]

-- HONEYPOT SETTINGS (pick it up, equip it, tap to throw it, it explodes into yellow cubes when it hits something = instant gold)[cite: 1]
local HONEYPOT_ASSET_ID = 446555612
local HONEYPOT_CHANCE = 0.05 -- 5% chance per spawn cycle[cite: 1]
local HONEYPOT_TOOL_NAME = "Honeypot"
local HONEYPOT_SCALE = 1
local HONEYPOT_GRIP = CFrame.new(0, 0, 0) -- how it sits in your hand (only used if the model isn't already a Tool)[cite: 1]
local HONEYPOT_GOLD = 500 -- gold you get when it explodes (that also sends 200 tiny coins)[cite: 1]
local HONEYPOT_THROW_SPEED = 90 -- how hard you throw it[cite: 1]
local HONEYPOT_THROW_UP = 0.15 -- upward tilt of the throw[cite: 1]
local HONEYPOT_MAX_FLIGHT = 8 -- explodes by itself after this many seconds if it never hits anything[cite: 1]
local HONEYPOT_CUBE_COUNT = 45 -- how many yellow cubes fly out[cite: 1]
local HONEYPOT_CUBE_COLOR = Color3.fromRGB(255, 220, 0)
local HONEYPOT_CUBE_LIFETIME = 3
local HONEYPOT_EXPLODE_SPEED = 60

-- CD-1 TOOL SETTINGS[cite: 1]
local CD_ASSET_ID = 116084743176043
local CD_CHANCE = 0.03 -- chance per spawn (only ONE CD ever spawns per run)[cite: 1]
local CD_TOOL_NAME = "CD-1"
local CD_SCALE = 0.4 -- size of the CD (on the ground AND in your hand). 1 = original size[cite: 1]
local CD_GRIP = CFrame.new(0, 0, 0) -- how the CD sits in your hand (only used if the model isn't already a Tool)[cite: 1]

-- CRUCIFIX SETTINGS[cite: 1]
local CRUCIFIX_ASSET_ID = 11650774915 -- the pickup / tool model[cite: 1]
local CRUCIFIX_CHANCE = 0.05 -- 5% chance per spawn cycle[cite: 1]
local CRUCIFIX_MAX_SPAWNS = 1 -- how many crucifixes can spawn per run (raise it if you want more)[cite: 1]
local CRUCIFIX_TOOL_NAME = "Crucifix"
local CRUCIFIX_SCALE = 1
local CRUCIFIX_GRIP = CFrame.new(0, 0, 0) -- how it sits in your hand[cite: 1]
local CRUCIFIX_CONSUMED = true -- true = the crucifix is used up when you use it on R4NS0M[cite: 1]
local CRUCIFIX_CROSS_ASSET_ID = 12570023741 -- the big cross that appears on the ground[cite: 1]
local CRUCIFIX_CROSS_DISTANCE = 10 -- studs in front of you[cite: 1]
local CRUCIFIX_CROSS_ROTATION = CFrame.Angles(0, 0, 0) -- if the big cross faces the wrong way[cite: 1]
local CRUCIFIX_IMAGE_ID = 12436809176 -- image in the middle of the cross[cite: 1]
local CRUCIFIX_IMAGE_SIZE = 0.6 -- image size compared to the cross (1 = as big as the cross)[cite: 1]
local CRUCIFIX_STAY_TIME = 5 -- seconds before the cross sinks into the ground[cite: 1]
local CRUCIFIX_SINK_TIME = 1.5 -- how long the sinking takes[cite: 1]
local CRUCIFIX_LIGHT_COLOR = Color3.fromRGB(120, 200, 255) -- light blue[cite: 1]
local CRUCIFIX_LIGHT_BRIGHTNESS = 10
local CRUCIFIX_LIGHT_RANGE = 40
local CRUCIFIX_SOUND_ID_1 = 105524657454474 -- both play at the same moment when you use the crucifix[cite: 1]
local CRUCIFIX_SOUND_ID_2 = 115833319186798
local CRUCIFIX_SOUND_VOLUME = 6

-- TV SETTINGS[cite: 1]
local TV_ASSET_ID = 17307663311 -- TV model[cite: 1]
local TV_SCALE = 2.5 -- HOW BIG THE TV IS (1 = original size, 2 = twice as big...)[cite: 1]
local TV_CHANCE = 0.03 -- chance per spawn (only ONE TV ever spawns per run)[cite: 1]
local TV_ROTATION = CFrame.Angles(0, 0, 0) -- if the TV faces the wrong way[cite: 1]
local TV_STATIC_SOUND_ID = 138347177735590
local TV_IDLE_STATIC_VOLUME = 0 -- quiet static while the TV just stands there (0 = silent)[cite: 1]
local TV_ACTIVE_STATIC_VOLUME = 3 -- static volume while opening / shaking[cite: 1]
local TV_STAY_WHITE = false -- false = TV goes back to normal after the clone is out, true = stays white[cite: 1]
local CD_CONSUMED = true -- true = the CD-1 is used up when you insert it[cite: 1]

-- TV PUSHING (touch the side of the TV, you stick to it, walk and it moves with you, jump to let go)[cite: 1]
local TV_PUSH_ENABLED = true
local TV_PUSH_AXIS = "X" -- "X" = you grab it from the left / right sides of the model[cite: 1]
local TV_PUSH_TOUCH_DISTANCE = 2.5 -- how close you must be to the side[cite: 1]
local TV_PUSH_STICK_GAP = 1.6 -- how far from the TV's side you are held while you move it[cite: 1]

-- "OPEN TV?" SETTINGS[cite: 1]
local TV_OPEN_DELAY = 5 -- seconds the TV screen glows white (with static) before the clone appears[cite: 1]
local TV_OPEN_LIGHT_COLOR = Color3.fromRGB(255, 255, 255)
local TV_OPEN_LIGHT_BRIGHTNESS = 10
local TV_OPEN_LIGHT_RANGE = 5

-- "INSERT DISC?" SETTINGS[cite: 1]
local TV_INSERT_SOUND_1 = 78535264432518 -- plays for 1 second[cite: 1]
local TV_INSERT_SOUND_1_TIME = 1
local TV_INSERT_SOUND_2 = 926658585 -- plays for 7 seconds straight (the TV shakes during this)[cite: 1]
local TV_SHAKE_TIME = 7
local TV_INSERT_SOUND_3 = 84909470598244 -- plays after that, the image shows and shakes during it[cite: 1]
local TV_INSERT_SOUND_3_MAX_WAIT = 10 -- never waits longer than this for sound 3 to end[cite: 1]
local TV_INSERT_SOUND_VOLUME = 5
local TV_EVIL_DELAY = 1 -- seconds after sound 3 ends before the evil clone comes out[cite: 1]

-- TV DISC GLOW / PARTICLES / IMAGE SETTINGS (only the TV SCREEN glows, like when the normal clone comes out)[cite: 1]
local TV_GLOW_COLOR = Color3.fromRGB(255, 110, 110) -- light red glow[cite: 1]
local TV_GLOW_LIGHT_COLOR = Color3.fromRGB(255, 60, 60)
local TV_GLOW_BRIGHTNESS = 10 -- how bright the red light around the TV is[cite: 1]
local TV_GLOW_RANGE = 5
local TV_CENTER_IMAGE_ID = 12436809176 -- image in the center of the TV (shakes like the TV is corrupted)[cite: 1]
local TV_CENTER_IMAGE_SIZE = 0.8 -- image size compared to the TV (1 = as big as the TV)[cite: 1]
local TV_GLOW_STAY_AFTER = false -- false = glow / particles / image go away when the evil clone spawns, true = they stay[cite: 1]

-- CLONE SETTINGS[cite: 1]
local CLONE_SPEED = 12 -- normal clone speed (your walk speed is 16)[cite: 1]
local EVIL_CLONE_SPEED = 17 -- evil clone speed[cite: 1]
local EVIL_STOP_EVERY = 2 -- evil clone stops every X seconds[cite: 1]
local EVIL_STOP_TIME = 0.5 -- and stays still for this long[cite: 1]
local CLONE_EMERGE_TIME = 1.6 -- how long it takes to come out of the TV[cite: 1]
local CLONE_KILL_DISTANCE = 3.2 -- how close it has to get to kill you[cite: 1]
local EVIL_IMAGE_ID = 105690422013136
local REWIND_MAX_TIME = 2.5 -- the normal clone's rewind never takes longer than this (seconds)[cite: 1]
local REWIND_MIN_RATE = 120 -- minimum rewind speed (recorded frames per second)[cite: 1]
local NORMAL_CLONE_LIGHT_BRIGHTNESS = 3 -- how strongly the white clone glows (0 = no light, only neon)[cite: 1]
local NORMAL_CLONE_LIGHT_RANGE = 16

-- DRAWER SETTINGS[cite: 1]
local DRAWER_ASSET_ID = 11213956867
local DRAWER_CHANCE = 0.10 -- 10% chance per spawn cycle that a drawer spawns instead of a coin[cite: 1]
local DRAWER_COIN_CHANCE = 0.5 -- chance that looting a drawer gives you a coin (0.5 = 50%)[cite: 1]
local DRAWER_ROTATION = CFrame.Angles(0, 0, 0) -- if the drawer faces the wrong way[cite: 1]
local DRAWER_PERSIST = false -- false = drawers are removed when R4NS0M ends, true = they stay forever like the TV[cite: 1]

-- POP-UP SETTINGS[cite: 1]
local POPUP_COUNT = 12 -- how many pop-ups spawn[cite: 1]
local POPUP_DELAY = 0.1 -- seconds between each pop-up appearing[cite: 1]
local POPUP_POP_TIME = 0.3 -- how long each pop-in animation takes[cite: 1]
local POPUP_LIFETIME_MIN = 11 -- each pop-up lives a random whole number of seconds from MIN to MAX[cite: 1]
local POPUP_LIFETIME_MAX = 15
local POPUP_FLICKER_CHANCE = 0.10 -- chance (rolled every POPUP_FLICKER_CHECK seconds, per window) that a window flickers[cite: 1]
local POPUP_FLICKER_CHECK = 1
local POPUP_FLICKER_TIME = 0.1 -- how long the red flicker lasts[cite: 1]
local POPUP_FLICKER_IMAGE_ID = 12436809176 -- image shown on the red flicker (only inside that window)[cite: 1]

-- Only one TV and one CD can ever spawn[cite: 1]
local tvSpawned = false
local cdSpawned = false
local crucifixSpawnCount = 0

-- Clean up any old GUI or leftover sounds from previous executions[cite: 1]
if playerGui:FindFirstChild("JumpscareDownloadGui") then
	playerGui.JumpscareDownloadGui:Destroy()
end
if playerGui:FindFirstChild("FinalShakyGui") then
	playerGui.FinalShakyGui:Destroy()
end
if playerGui:FindFirstChild("FailureJumpscareGui") then
	playerGui.FailureJumpscareGui:Destroy()
end
if playerGui:FindFirstChild("VictoryPopupGui") then
	playerGui.VictoryPopupGui:Destroy()
end
for _, g in ipairs(playerGui:GetChildren()) do
	if g.Name == "R4NS0MCoinBits" then
		g:Destroy()
	end
end
if SoundService:FindFirstChild("JumpscareSound") then
	SoundService.JumpscareSound:Destroy()
end
if SoundService:FindFirstChild("SpawnSound") then
	SoundService.SpawnSound:Destroy()
end
if SoundService:FindFirstChild("VictorySound") then
	SoundService.VictorySound:Destroy()
end
if SoundService:FindFirstChild("TVDiscSound") then
	SoundService.TVDiscSound:Destroy()
end
if SoundService:FindFirstChild("R4NS0MTheme") then
	SoundService.R4NS0MTheme:Destroy()
end
if SoundService:FindFirstChild("R4NS0MThemeExtension") then
	SoundService.R4NS0MThemeExtension:Destroy()
end

-- Cleanup old spawned map coins / CDs / TV / drawers / clones from a previous run[cite: 1]
for _, obj in ipairs(Workspace:GetChildren()) do
	if obj.Name == "MapCollectibleCoin" or obj.Name == "R4NS0M_TV" or obj.Name == "R4NS0M_Drawer"
		or obj.Name == "R4NS0M_Clone" or obj.Name == "R4NS0M_EvilClone" or obj.Name == "R4NS0M_CrucifixCross"
		or obj.Name == "R4NS0M_HoneypotThrown" or obj.Name == "HoneyCube" then
		obj:Destroy()
	end
end

-- Removes what belongs to the R4NS0M round when it ends (coins, and drawers unless DRAWER_PERSIST)[cite: 1]
local function clearRoundObjects()
	for _, obj in ipairs(Workspace:GetChildren()) do
		if obj.Name == "MapCollectibleCoin" or (not DRAWER_PERSIST and obj.Name == "R4NS0M_Drawer") then
			obj:Destroy()
		end
	end
end

-- Plays a one-shot sound and cleans it up[cite: 1]
local function playOneShot(id, volume)
	local s = Instance.new("Sound")
	s.SoundId = "rbxassetid://" .. tostring(id)
	s.Volume = volume
	s.Parent = SoundService
	s.Ended:Connect(function()
		s:Destroy()
	end)
	Debris:AddItem(s, 60)
	s:Play()
	return s
end

-- Creates a sound (not playing yet)[cite: 1]
local function makeSound(id, volume)
	local s = Instance.new("Sound")
	s.Name = "TVDiscSound"
	s.SoundId = "rbxassetid://" .. tostring(id)
	s.Volume = volume
	s.Parent = SoundService
	return s
end

-- Plays a sound for exactly `seconds` (cut off if longer), then removes it[cite: 1]
local function playTimed(id, volume, seconds)
	local s = makeSound(id, volume)
	s:Play()
	task.wait(seconds)
	s:Stop()
	s:Destroy()
end

-- Plays a sound until it ends (never longer than maxWait), then removes it[cite: 1]
local function playUntilEnd(id, volume, maxWait)
	local s = makeSound(id, volume)
	local ended = false
	s.Ended:Connect(function()
		ended = true
	end)
	s:Play()
	local t0 = os.clock()
	while not ended and os.clock() - t0 < maxWait do
		if os.clock() - t0 > 1 and s.TimeLength == 0 then
			break
		end
		RunService.Heartbeat:Wait()
	end
	s:Destroy()
end

-- Biggest BasePart of a model / part (holds prompts)[cite: 1]
local function getMainPart(obj)
	if obj:IsA("BasePart") then
		return obj
	end
	local main, bestVol = nil, -1
	for _, d in ipairs(obj:GetDescendants()) do
		if d:IsA("BasePart") then
			local v = d.Size.X * d.Size.Y * d.Size.Z
			if v > bestVol then
				bestVol = v
				main = d
			end
		end
	end
	return main
end

-- Adds a tap prompt ("Collect Coins", "Pick Up CD-1", ...) to an object[cite: 1]
local function addPickupPrompt(obj, actionText)
	local main = getMainPart(obj)
	if not main then return nil end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "PickupPrompt"
	prompt.ObjectText = ""
	prompt.ActionText = actionText
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = PICKUP_DISTANCE
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.Parent = main
	return prompt
end

--------------------------------------------------------------------------------
-- TINY COIN IMAGES (the little coins that fly into the R4NS0M window)
-- variants: gold (normal) / white / red with black rectangle / red / generic rectangle[cite: 1]
--------------------------------------------------------------------------------
local function pickBitVariant()
	local r = math.random()
	if r < 0.30 then
		return "gold"
	elseif r < 0.50 then
		return "white"
	elseif r < 0.70 then
		return "red_black_rect"
	elseif r < 0.85 then
		return "red"
	else
		return "rect"
	end
end

local function makeCoinBit(parent, size)
	local variant = pickBitVariant()
	
	local holder = Instance.new("Frame")
	holder.Name = "CoinBit"
	holder.BackgroundTransparency = 1
	holder.BorderSizePixel = 0
	holder.Size = UDim2.new(0, size, 0, size)
	holder.AnchorPoint = Vector2.new(0.5, 0.5)
	holder.Parent = parent
	
	if variant == "white" then
		local disc = Instance.new("Frame")
		disc.Name = "WhiteDisc"
		disc.AnchorPoint = Vector2.new(0.5, 0.5)
		disc.Position = UDim2.new(0.5, 0, 0.5, 0)
		disc.Size = UDim2.new(0.86, 0, 0.86, 0)
		disc.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		disc.BorderSizePixel = 0
		disc.ZIndex = 1
		disc.Parent = holder
		local discCorner = Instance.new("UICorner")
		discCorner.CornerRadius = UDim.new(0.5, 0)
		discCorner.Parent = disc
	end
	
	local img = Instance.new("ImageLabel")
	img.Name = "CoinImage"
	img.Image = "rbxthumb://type=Asset&id=" .. tostring(COIN_BIT_IMAGE_ID) .. "&w=150&h=150"
	img.BackgroundTransparency = 1
	img.Size = UDim2.new(1, 0, 1, 0)
	img.ZIndex = 2
	img.Parent = holder
	
	if variant == "red" then
		img.ImageColor3 = Color3.fromRGB(255, 40, 40)
	elseif variant == "white" then
		img.ImageTransparency = 0.6
	elseif variant == "red_black_rect" then
		img.ImageColor3 = Color3.fromRGB(255, 40, 40)
		local rect = Instance.new("Frame")
		rect.Name = "BlackRectangle"
		rect.AnchorPoint = Vector2.new(0.5, 0.5)
		rect.Position = UDim2.new(0.5, 0, 0.5, 0)
		rect.Size = UDim2.new(0.7, 0, 0.45, 0)
		rect.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		rect.BorderSizePixel = 0
		rect.ZIndex = 3
		rect.Parent = holder
		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.fromRGB(40, 40, 40)
		stroke.Thickness = 2
		stroke.Parent = rect
	elseif variant == "rect" then
		local rect = Instance.new("Frame")
		rect.Name = "RedRectangle"
		rect.AnchorPoint = Vector2.new(0.5, 0.5)
		rect.Position = UDim2.new(0.5, 0, 0.5, 0)
		rect.Size = UDim2.new(0.7, 0, 0.45, 0)
		rect.BackgroundColor3 = Color3.fromRGB(220, 0, 0)
		rect.BorderSizePixel = 0
		rect.ZIndex = 3
		rect.Parent = holder
		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.fromRGB(70, 0, 0)
		stroke.Thickness = 2
		stroke.Parent = rect
	end
	
	return holder
end

--------------------------------------------------------------------------------
-- LOAD COIN MODEL (Delta compatible: game:GetObjects)[cite: 1]
--------------------------------------------------------------------------------
local coinTemplate = nil

task.spawn(function()
	local ok, result = pcall(function()
		return game:GetObjects("rbxassetid://" .. tostring(COIN_ASSET_ID))
	end)
	if ok and result and result[1] then
		local template = result[1]
		for _, d in ipairs(template:GetDescendants()) do
			if d:IsA("Script") or d:IsA("LocalScript") then
				d:Destroy()
			end
		end
		local function preparePart(p)
			p.Anchored = true
			p.CanCollide = false
			p.CanTouch = false
			p.CanQuery = false
			p.Massless = true
		end
		if template:IsA("BasePart") then
			preparePart(template)
		end
		for _, d in ipairs(template:GetDescendants()) do
			if d:IsA("BasePart") then
				preparePart(d)
			end
		end
		coinTemplate = template
	else
		warn("Coin model failed to load, using cylinder coins instead.")
	end
end)

--------------------------------------------------------------------------------
-- LOAD TOOLS (CD-1 + Crucifix + Honeypot)[cite: 1]
--------------------------------------------------------------------------------
local cdToolTemplate = nil
local crucifixToolTemplate = nil
local honeyToolTemplate = nil

local function scaleInstance(inst, s)
	if s == 1 then return end
	pcall(function()
		if inst:IsA("Model") then
			inst:ScaleTo(s)
		elseif inst:IsA("BasePart") then
			inst.Size = inst.Size * s
		else
			local wrapper = Instance.new("Model")
			for _, child in ipairs(inst:GetChildren()) do
				child.Parent = wrapper
			end
			wrapper:ScaleTo(s)
			for _, child in ipairs(wrapper:GetChildren()) do
				child.Parent = inst
			end
			wrapper:Destroy()
		end
	end)
end

local function buildToolFromAsset(loaded, toolName, grip, scale)
	local source = loaded:Clone()
	for _, d in ipairs(source:GetDescendants()) do
		if d:IsA("Script") or d:IsA("LocalScript") then
			d:Destroy()
		end
	end
	
	local tool
	if source:IsA("Tool") and source:FindFirstChild("Handle") then
		tool = source
	else
		local parts = {}
		if source:IsA("BasePart") then
			parts = {source}
		else
			for _, d in ipairs(source:GetDescendants()) do
				if d:IsA("BasePart") then
					table.insert(parts, d)
				end
			end
		end
		if #parts == 0 then
			error(toolName .. " asset has no parts")
		end
		
		local handle = nil
		if source:IsA("Model") and source.PrimaryPart then
			handle = source.PrimaryPart
		end
		if not handle then
			local bestVolume = -1
			for _, p in ipairs(parts) do
				local v = p.Size.X * p.Size.Y * p.Size.Z
				if v > bestVolume then
					bestVolume = v
					handle = p
				end
			end
		end
		
		tool = Instance.new("Tool")
		tool.RequiresHandle = true
		tool.Grip = grip
		
		for _, p in ipairs(parts) do
			p.Anchored = false
			p.CanCollide = false
			if p ~= handle then
				local weld = Instance.new("Weld")
				weld.Part0 = handle
				weld.Part1 = p
				weld.C0 = handle.CFrame:ToObjectSpace(p.CFrame)
				weld.Parent = p
			end
		end
		
		handle.Name = "Handle"
		for _, p in ipairs(parts) do
			p.Parent = tool
		end
	end
	
	tool.Name = toolName
	tool.ToolTip = toolName
	tool.CanBeDropped = false
	scaleInstance(tool, scale)
	return tool
end

local function loadToolTemplate(assetId, toolName, grip, scale, onDone)
	task.spawn(function()
		local ok, result = pcall(function()
			return game:GetObjects("rbxassetid://" .. tostring(assetId))
		end)
		if ok and result and result[1] then
			local built, tool = pcall(buildToolFromAsset, result[1], toolName, grip, scale)
			if built and tool then
				onDone(tool)
			else
				warn(toolName .. " failed to build: " .. tostring(tool))
			end
		else
			warn(toolName .. " model failed to load.")
		end
	end)
end

loadToolTemplate(CD_ASSET_ID, CD_TOOL_NAME, CD_GRIP, CD_SCALE, function(t)
	cdToolTemplate = t
end)
loadToolTemplate(CRUCIFIX_ASSET_ID, CRUCIFIX_TOOL_NAME, CRUCIFIX_GRIP, CRUCIFIX_SCALE, function(t)
	crucifixToolTemplate = t
end)
loadToolTemplate(HONEYPOT_ASSET_ID, HONEYPOT_TOOL_NAME, HONEYPOT_GRIP, HONEYPOT_SCALE, function(t)
	honeyToolTemplate = t
end)

local function makeToolDisplay(template)
	local model = Instance.new("Model")
	model.Name = "MapCollectibleCoin"
	local clone = template:Clone()
	for _, child in ipairs(clone:GetChildren()) do
		child.Parent = model
	end
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.CanTouch = false
			d.CanQuery = false
		end
	end
	return model
end

--------------------------------------------------------------------------------
-- LOAD STATIC MODELS (TV + DRAWER)[cite: 1]
--------------------------------------------------------------------------------
local tvTemplate = nil
local drawerTemplate = nil
local crossTemplate = nil

local function buildStaticModel(assetId, modelName, collide)
	local ok, result = pcall(function()
		return game:GetObjects("rbxassetid://" .. tostring(assetId))
	end)
	if not ok or not result or #result == 0 then
		warn(modelName .. " model failed to load.")
		return nil
	end
	local model = Instance.new("Model")
	model.Name = modelName
	for _, inst in ipairs(result) do
		inst.Parent = model
	end
	local hasPart = false
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("LuaSourceContainer") or d:IsA("ClickDetector") or d:IsA("ProximityPrompt") or d:IsA("Sound") then
			d:Destroy()
		elseif d:IsA("BasePart") then
			hasPart = true
			d.Anchored = true
			d.CanCollide = collide
			if not collide then
				d.CanTouch = false
				d.CanQuery = false
			end
		end
	end
	if not hasPart then
		warn(modelName .. " model has no parts.")
		return nil
	end
	return model
end

task.spawn(function()
	tvTemplate = buildStaticModel(TV_ASSET_ID, "R4NS0M_TV", true)
end)
task.spawn(function()
	drawerTemplate = buildStaticModel(DRAWER_ASSET_ID, "R4NS0M_Drawer", true)
end)
task.spawn(function()
	crossTemplate = buildStaticModel(CRUCIFIX_CROSS_ASSET_ID, "R4NS0M_CrucifixCross", false)
end)

--------------------------------------------------------------------------------
-- HELPERS[cite: 1]
--------------------------------------------------------------------------------
local function tintModel(model, color)
	local undo = {}
	local list = model:GetDescendants()
	table.insert(list, model)
	for _, d in ipairs(list) do
		if d:IsA("BasePart") then
			local oc, om = d.Color, d.Material
			table.insert(undo, function()
				d.Color = oc
				d.Material = om
			end)
			d.Color = color
			d.Material = Enum.Material.Neon
			if d:IsA("MeshPart") then
				local ot = d.TextureID
				if ot ~= "" then
					table.insert(undo, function()
						d.TextureID = ot
					end)
					pcall(function()
						d.TextureID = ""
					end)
				end
			end
		elseif d:IsA("SpecialMesh") then
			local ot = d.TextureId
			if ot ~= "" then
				table.insert(undo, function()
					d.TextureId = ot
				end)
				pcall(function()
					d.TextureId = ""
				end)
			end
		elseif d:IsA("Decal") or d:IsA("Texture") then
			local ot = d.Transparency
			table.insert(undo, function()
				d.Transparency = ot
			end)
			d.Transparency = 1
		end
	end
	return function()
		for _, f in ipairs(undo) do
			pcall(f)
		end
	end
end

local function findScreenPart(tv)
	local best, bestVol = nil, -1
	for _, d in ipairs(tv:GetDescendants()) do
		if d:IsA("BasePart") then
			local n = string.lower(d.Name)
			if string.find(n, "screen") or string.find(n, "display") or string.find(n, "glass") or string.find(n, "monitor") then
				local v = d.Size.X * d.Size.Y * d.Size.Z
				if v > bestVol then
					bestVol = v
					best = d
				end
			end
		end
	end
	return best
end

local function killPlayer(hum)
	pcall(function()
		hum.Health = 0
	end)
	pcall(function()
		hum:ChangeState(Enum.HumanoidStateType.Dead)
	end)
end

--------------------------------------------------------------------------------
-- AVATAR CLONE[cite: 1]
--------------------------------------------------------------------------------
local RED = Color3.fromRGB(255, 0, 0)
local WHITE = Color3.fromRGB(255, 255, 255)

local function makeAvatarClone(evil)
	local char = player.Character
	if not char then return nil end
	
	char.Archivable = true
	local okClone, clone = pcall(function()
		return char:Clone()
	end)
	if not okClone or not clone then return nil end
	clone.Name = evil and "R4NS0M_EvilClone" or "R4NS0M_Clone"
	
	for _, d in ipairs(clone:GetDescendants()) do
		if d:IsA("LuaSourceContainer") or d:IsA("Sound") or d:IsA("BillboardGui") or d:IsA("ForceField") or d:IsA("Tool") then
			d:Destroy()
		end
	end
	
	for _, d in ipairs(clone:GetDescendants()) do
		if d:IsA("Shirt") or d:IsA("Pants") or d:IsA("ShirtGraphic") or d:IsA("BodyColors")
			or d:IsA("Decal") or d:IsA("Texture") or d:IsA("SurfaceAppearance") then
			d:Destroy()
		end
	end
	
	local tintColor = evil and RED or WHITE
	
	for _, d in ipairs(clone:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = false
			d.CanCollide = false
			d.CanTouch = false
			d.CanQuery = false
			d.Massless = true
			d.Color = tintColor
			d.Material = Enum.Material.Neon
			if d:IsA("MeshPart") then
				pcall(function()
					d.TextureID = ""
				end)
			end
		elseif d:IsA("SpecialMesh") then
			pcall(function()
				d.TextureId = ""
			end)
		end
	end
	
	local hrp = clone:FindFirstChild("HumanoidRootPart")
	if not hrp then
		clone:Destroy()
		return nil
	end
	hrp.Anchored = true
	
	local hum = clone:FindFirstChildOfClass("Humanoid")
	if hum then
		pcall(function()
			hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
			hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
			hum.BreakJointsOnDeath = false
			hum.RequiresNeck = false
			hum.MaxHealth = 1e9
			hum.Health = 1e9
			hum.WalkSpeed = 0
		end)
		pcall(function()
			hum.EvaluateStateMachine = false
		end)
	end
	
	local torso = clone:FindFirstChild("UpperTorso") or clone:FindFirstChild("Torso")
	if torso then
		local light = Instance.new("PointLight")
		if evil then
			light.Color = RED
			light.Range = 14
			light.Brightness = 2
		else
			light.Color = WHITE
			light.Range = NORMAL_CLONE_LIGHT_RANGE
			light.Brightness = NORMAL_CLONE_LIGHT_BRIGHTNESS
		end
		light.Parent = torso
	end
	
	return clone
end

local function attachEvilBillboard(clone)
	local torso = clone:FindFirstChild("UpperTorso") or clone:FindFirstChild("Torso")
	if not torso then return nil, nil end
	
	local gui = Instance.new("BillboardGui")
	gui.Name = "EvilImage"
	gui.Adornee = torso
	gui.AlwaysOnTop = true
	gui.LightInfluence = 0
	gui.Size = UDim2.new(4, 0, 4, 0)
	gui.Enabled = false
	gui.Parent = torso
	
	local img = Instance.new("ImageLabel")
	img.Name = "Image"
	img.BackgroundTransparency = 1
	img.AnchorPoint = Vector2.new(0.5, 0.5)
	img.Position = UDim2.new(0.5, 0, 0.5, 0)
	img.Size = UDim2.new(1, 0, 1, 0)
	img.Image = "rbxthumb://type=Asset&id=" .. tostring(EVIL_IMAGE_ID) .. "&w=420&h=420"
	img.Parent = gui
	
	return gui, img
end

local function buildMotorPairs(srcChar, clone)
	local src = {}
	for _, d in ipairs(srcChar:GetDescendants()) do
		if d:IsA("Motor6D") then
			src[d.Name] = d
		end
	end
	local list = {}
	for _, d in ipairs(clone:GetDescendants()) do
		if d:IsA("Motor6D") and src[d.Name] then
			table.insert(list, {clone = d, src = src[d.Name]})
		end
	end
	return list
end

--------------------------------------------------------------------------------
-- RUNS A CLONE[cite: 1]
--------------------------------------------------------------------------------
local function runCloneEntity(evil, tvModel, tvGroundY, onEmerged, onGone)
	local ownerChar = player.Character
	local ownerHrp = ownerChar and ownerChar:FindFirstChild("HumanoidRootPart")
	local ownerHum = ownerChar and ownerChar:FindFirstChildOfClass("Humanoid")
	if not ownerHrp or not ownerHum or ownerHum.Health <= 0 then
		if onGone then task.spawn(onGone) end
		return nil
	end
	
	local clone = makeAvatarClone(evil)
	if not clone then
		if onGone then task.spawn(onGone) end
		return nil
	end
	local cHrp = clone:FindFirstChild("HumanoidRootPart")
	
	local hipOffset = 3
	if ownerHum.RigType == Enum.HumanoidRigType.R15 then
		hipOffset = ownerHum.HipHeight + ownerHrp.Size.Y / 2
	end
	
	local tvCF, tvSize = tvModel:GetBoundingBox()
	local tvCenter = tvCF.Position
	local toPlayer = Vector3.new(ownerHrp.Position.X - tvCenter.X, 0, ownerHrp.Position.Z - tvCenter.Z)
	local dir = toPlayer.Magnitude > 0.1 and toPlayer.Unit or Vector3.new(0, 0, -1)
	local emergeDist = math.max(tvSize.X, tvSize.Z) / 2 + 3.5
	local startPos = Vector3.new(tvCenter.X, tvGroundY + hipOffset, tvCenter.Z)
	local endPos = startPos + dir * emergeDist
	
	local fadeList = {}
	for _, d in ipairs(clone:GetDescendants()) do
		if d:IsA("BasePart") or d:IsA("Decal") or d:IsA("Texture") then
			table.insert(fadeList, {inst = d, orig = d.Transparency})
			d.Transparency = 1
		end
	end
	
	local motorPairs = buildMotorPairs(ownerChar, clone)
	local billboard, billboardImg = nil, nil
	if evil then
		billboard, billboardImg = attachEvilBillboard(clone)
	end
	
	clone.Parent = Workspace
	cHrp.CFrame = CFrame.lookAt(startPos, startPos + dir)
	
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.IgnoreWater = true
	rayParams.FilterDescendantsInstances = {ownerChar, clone, tvModel}
	
	local speed = evil and EVIL_CLONE_SPEED or CLONE_SPEED
	local state = "emerge"
	local elapsed = 0
	local curY = startPos.Y
	local facing = dir
	local stopped = false
	local phaseTimer = 0
	local glitchTimer = 0
	local finished = false
	local conn
	
	local hist = {}
	local rewindCb = nil
	local rewindIdx = 0
	
	local function record(a)
		local poses = {}
		for k, m in ipairs(motorPairs) do
			poses[k] = m.src.Transform
		end
		hist[#hist + 1] = {cf = cHrp.CFrame, a = a, poses = poses}
		if #hist > 6000 then
			local thinned = {}
			for i = 1, #hist, 2 do
				thinned[#thinned + 1] = hist[i]
			end
			hist = thinned
		end
	end
	
	local function finish()
		if finished then return end
		finished = true
		if conn then conn:Disconnect() end
		if clone then clone:Destroy() end
		if rewindCb then
			task.spawn(rewindCb)
		elseif onGone then
			task.spawn(onGone)
		end
	end
	
	local ctl = {}
	function ctl.IsReady()
		return (not finished) and (not evil) and state == "chase"
	end
	function ctl.Rewind(cb)
		if not ctl.IsReady() or #hist < 2 then
			return false
		end
		rewindCb = cb
		rewindIdx = #hist
		state = "rewind"
		return true
	end
	
	local function copyPose()
		for _, m in ipairs(motorPairs) do
			if m.src.Parent and m.clone.Parent then
				m.clone.Transform = m.src.Transform
			end
		end
	end
	
	conn = RunService.RenderStepped:Connect(function(dt)
		if finished then return end
		
		local char = player.Character
		local pHrp = char and char:FindFirstChild("HumanoidRootPart")
		local pHum = char and char:FindFirstChildOfClass("Humanoid")
		if char ~= ownerChar or not pHrp or not pHum or pHum.Health <= 0 or not clone.Parent then
			finish()
			return
		end
		
		if not stopped and state ~= "rewind" then
			copyPose()
		end
		
		if state == "rewind" then
			local n = #hist
			local rate = math.max(REWIND_MIN_RATE, n / REWIND_MAX_TIME)
			rewindIdx = rewindIdx - rate * dt
			local s = hist[math.max(1, math.floor(rewindIdx))]
			if s then
				cHrp.CFrame = s.cf
				for k, m in ipairs(motorPairs) do
					if s.poses[k] and m.clone.Parent then
						m.clone.Transform = s.poses[k]
					end
				end
				for _, item in ipairs(fadeList) do
					item.inst.Transparency = 1 - (1 - item.orig) * s.a
				end
			end
			if rewindIdx <= 1 then
				finish()
			end
			return
		end
		
		if state == "emerge" then
			elapsed += dt
			local a = math.clamp(elapsed / CLONE_EMERGE_TIME, 0, 1)
			local eased = 1 - (1 - a) * (1 - a)
			local pos = startPos:Lerp(endPos, eased)
			cHrp.CFrame = CFrame.lookAt(pos, pos + dir)
			for _, item in ipairs(fadeList) do
				item.inst.Transparency = 1 - (1 - item.orig) * a
			end
			if not evil then
				record(a)
			end
			if a >= 1 then
				state = "chase"
				curY = pos.Y
				if billboard then billboard.Enabled = true end
				if onEmerged then task.spawn(onEmerged) end
			end
			return
		end
		
		local cPos = cHrp.Position
		local toP = Vector3.new(pHrp.Position.X - cPos.X, 0, pHrp.Position.Z - cPos.Z)
		local flatDist = toP.Magnitude
		
		if evil then
			phaseTimer += dt
			if not stopped and phaseTimer >= EVIL_STOP_EVERY then
				stopped = true
				phaseTimer = 0
				if billboardImg then
					billboardImg.Position = UDim2.new(0.5, 0, 0.5, 0)
					billboardImg.ImageTransparency = 0
				end
			elseif stopped and phaseTimer >= EVIL_STOP_TIME then
				stopped = false
				phaseTimer = 0
				glitchTimer = 1
			end
		end
		
		if not stopped then
			if flatDist > 0.05 then
				facing = toP.Unit
			end
			local step = math.min(speed * dt, flatDist)
			local newX = cPos.X + facing.X * step
			local newZ = cPos.Z + facing.Z * step
			
			local hit = Workspace:Raycast(Vector3.new(newX, curY + 4, newZ), Vector3.new(0, -25, 0), rayParams)
			local targetY = hit and (hit.Position.Y + hipOffset) or curY
			curY = curY + (targetY - curY) * math.min(1, dt * 12)
			
			local newPos = Vector3.new(newX, curY, newZ)
			cHrp.CFrame = CFrame.lookAt(newPos, newPos + facing)
			
			if billboardImg then
				glitchTimer += dt
				if glitchTimer >= 0.05 then
					glitchTimer = 0
					billboardImg.Position = UDim2.new(0.5 + (math.random() - 0.5) * 0.7, 0, 0.5 + (math.random() - 0.5) * 0.9, 0)
					billboardImg.ImageTransparency = 0.45 + math.random() * 0.5
				end
			end
		end
		
		if not evil then
			record(1)
		end
		
		local dx = pHrp.Position.X - cHrp.Position.X
		local dz = pHrp.Position.Z - cHrp.Position.Z
		local dy = math.abs(pHrp.Position.Y - cHrp.Position.Y)
		if math.sqrt(dx * dx + dz * dz) < CLONE_KILL_DISTANCE and dy < 5 then
			killPlayer(pHum)
			finish()
		end
	end)
	
	return ctl
end

--------------------------------------------------------------------------------
-- TV SETUP[cite: 1]
--------------------------------------------------------------------------------
local function setupTV(tv, groundY)
	local main = getMainPart(tv)
	if not main then
		tv:Destroy()
		return
	end
	
	local screenPart = findScreenPart(tv)
	
	local staticSound = Instance.new("Sound")
	staticSound.Name = "TVStatic"
	staticSound.SoundId = "rbxassetid://" .. tostring(TV_STATIC_SOUND_ID)
	staticSound.Looped = true
	staticSound.Volume = TV_IDLE_STATIC_VOLUME
	staticSound.RollOffMaxDistance = 45
	staticSound.Parent = main
	
	local function setStatic(vol)
		if vol <= 0 then
			staticSound:Stop()
		else
			staticSound.Volume = vol
			if not staticSound.IsPlaying then
				staticSound:Play()
			end
		end
	end
	setStatic(TV_IDLE_STATIC_VOLUME)
	
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "TVPrompt"
	prompt.ObjectText = ""
	prompt.ActionText = "Open TV?"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.Parent = main
	
	local phase = "idle"
	local normalCtl = nil
	local restoreTV = nil
	
	local function doRestoreTV()
		if restoreTV then
			local r = restoreTV
			restoreTV = nil
			r()
		end
	end
	
	local function holdingCD()
		local char = player.Character
		local t = char and char:FindFirstChild(CD_TOOL_NAME)
		if t and t:IsA("Tool") then
			return t
		end
		return nil
	end
	
	local promptConn
	promptConn = RunService.Heartbeat:Connect(function()
		if not tv.Parent then
			promptConn:Disconnect()
			return
		end
		local holding = holdingCD() ~= nil
		local want = holding and "Insert Disc?" or "Open TV?"
		if prompt.ActionText ~= want then
			prompt.ActionText = want
		end
		local canUse = (phase == "idle")
			or (phase == "normal" and holding and normalCtl ~= nil and normalCtl.IsReady())
		if prompt.Enabled ~= canUse then
			prompt.Enabled = canUse
		end
	end)
	
	local function cycleDone()
		phase = "idle"
		normalCtl = nil
		setStatic(TV_IDLE_STATIC_VOLUME)
	end
	
	local glowRestore = nil
	local glowCenter = nil
	local glowEmitter = nil
	local glowLight = nil
	local glowBillboard = nil
	local glowSize = Vector3.new(4, 4, 4)
	
	local function startGlow()
		if glowCenter then return end
		doRestoreTV()
		
		if screenPart then
			glowRestore = tintModel(screenPart, TV_GLOW_COLOR)
		end
		
		local cf, size = tv:GetBoundingBox()
		glowSize = size
		
		glowCenter = Instance.new("Part")
		glowCenter.Name = "TVCenter"
		glowCenter.Size = Vector3.new(0.3, 0.3, 0.3)
		glowCenter.Transparency = 1
		glowCenter.Anchored = true
		glowCenter.CanCollide = false
		glowCenter.CanTouch = false
		glowCenter.CanQuery = false
		glowCenter.CFrame = cf
		glowCenter.Parent = tv
		
		glowLight = Instance.new("PointLight")
		glowLight.Color = TV_GLOW_LIGHT_COLOR
		glowLight.Brightness = TV_GLOW_BRIGHTNESS
		glowLight.Range = TV_GLOW_RANGE
		glowLight.Shadows = false
		glowLight.Parent = screenPart or glowCenter
		
		glowEmitter = Instance.new("ParticleEmitter")
		glowEmitter.Name = "TVParticles"
		glowEmitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		glowEmitter.Color = ColorSequence.new(Color3.fromRGB(255, 70, 70), Color3.fromRGB(255, 190, 190))
		glowEmitter.LightEmission = 1
		glowEmitter.LightInfluence = 0
		glowEmitter.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.6),
			NumberSequenceKeypoint.new(1, 0),
		})
		glowEmitter.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(1, 1),
		})
		glowEmitter.Lifetime = NumberRange.new(0.8, 1.6)
		glowEmitter.Rate = 60
		glowEmitter.Speed = NumberRange.new(4, 10)
		glowEmitter.SpreadAngle = Vector2.new(180, 180)
		glowEmitter.RotSpeed = NumberRange.new(-90, 90)
		glowEmitter.Parent = glowCenter
	end
	
	local function showCenterImage()
		if not glowCenter or glowBillboard then return end
		local s = math.max(glowSize.X, glowSize.Y) * TV_CENTER_IMAGE_SIZE
		
		local gui = Instance.new("BillboardGui")
		gui.Name = "TVCenterImage"
		gui.Adornee = glowCenter
		gui.AlwaysOnTop = true
		gui.LightInfluence = 0
		gui.Size = UDim2.new(s, 0, s, 0)
		gui.Parent = glowCenter
		glowBillboard = gui
		
		local img = Instance.new("ImageLabel")
		img.BackgroundTransparency = 1
		img.AnchorPoint = Vector2.new(0.5, 0.5)
		img.Position = UDim2.new(0.5, 0, 0.5, 0)
		img.Size = UDim2.new(1, 0, 1, 0)
		img.Image = "rbxthumb://type=Asset&id=" .. tostring(TV_CENTER_IMAGE_ID) .. "&w=420&h=420"
		img.Parent = gui
		
		task.spawn(function()
			while glowBillboard == gui and gui.Parent do
				img.Position = UDim2.new(0.5 + (math.random() - 0.5) * 0.3, 0, 0.5 + (math.random() - 0.5) * 0.3, 0)
				img.Rotation = (math.random() - 0.5) * 16
				img.ImageTransparency = (math.random() < 0.15) and (0.3 + math.random() * 0.4) or 0
				RunService.Heartbeat:Wait()
			end
		end)
	end
	
	local function stopGlow()
		if glowEmitter then
			glowEmitter.Enabled = false
		end
		if glowRestore then
			local r = glowRestore
			glowRestore = nil
			r()
		end
		if glowLight then
			glowLight:Destroy()
		end
		if glowCenter then
			glowCenter:Destroy()
		end
		glowCenter, glowEmitter, glowLight, glowBillboard = nil, nil, nil, nil
	end
	
	local function insertDisc(cdTool, ctl)
		phase = "busy"
		if CD_CONSUMED then
			cdTool:Destroy()
		end
		task.spawn(function()
			setStatic(TV_ACTIVE_STATIC_VOLUME)
			startGlow()
			
			local rewound = true
			if ctl then
				rewound = false
				normalCtl = nil
				local started = ctl.Rewind(function()
					rewound = true
				end)
				if not started then
					rewound = true
				end
			end
			
			playTimed(TV_INSERT_SOUND_1, TV_INSERT_SOUND_VOLUME, TV_INSERT_SOUND_1_TIME)
			
			local soundTwo = makeSound(TV_INSERT_SOUND_2, TV_INSERT_SOUND_VOLUME)
			soundTwo:Play()
			local base = tv:GetPivot()
			local t0 = os.clock()
			while os.clock() - t0 < TV_SHAKE_TIME and tv.Parent do
				local ox = (math.random() - 0.5) * 0.24
				local oz = (math.random() - 0.5) * 0.24
				local rz = math.rad((math.random() - 0.5) * 3)
				tv:PivotTo(base * CFrame.new(ox, 0, oz) * CFrame.Angles(0, 0, rz))
				RunService.Heartbeat:Wait()
			end
			soundTwo:Stop()
			soundTwo:Destroy()
			if tv.Parent then
				tv:PivotTo(base)
			end
			
			local waited = os.clock()
			while not rewound and os.clock() - waited < 10 do
				RunService.Heartbeat:Wait()
			end
			
			setStatic(0)
			showCenterImage()
			playUntilEnd(TV_INSERT_SOUND_3, TV_INSERT_SOUND_VOLUME, TV_INSERT_SOUND_3_MAX_WAIT)
			
			if not tv.Parent then
				cycleDone()
				return
			end
			
			task.wait(TV_EVIL_DELAY)
			if not tv.Parent then
				cycleDone()
				return
			end
			
			if not TV_GLOW_STAY_AFTER then
				stopGlow()
			end
			runCloneEntity(true, tv, groundY, nil, function()
				if TV_GLOW_STAY_AFTER then
					stopGlow()
				end
				cycleDone()
			end)
		end)
	end
	
	local function openTV()
		phase = "busy"
		task.spawn(function()
			local target = screenPart or tv
			local tintUndo = tintModel(target, TV_OPEN_LIGHT_COLOR)
			local openLight = Instance.new("PointLight")
			openLight.Color = TV_OPEN_LIGHT_COLOR
			openLight.Brightness = TV_OPEN_LIGHT_BRIGHTNESS
			openLight.Range = TV_OPEN_LIGHT_RANGE
			openLight.Shadows = false
			openLight.Parent = screenPart or main
			
			restoreTV = function()
				openLight:Destroy()
				tintUndo()
			end
			
			setStatic(TV_ACTIVE_STATIC_VOLUME)
			
			local flickerTime = 0
			for i = 1, 6 do
				if not tv.Parent then break end
				openLight.Brightness = (i % 2 == 0) and TV_OPEN_LIGHT_BRIGHTNESS or 0
				task.wait(0.08)
				flickerTime += 0.08
			end
			openLight.Brightness = TV_OPEN_LIGHT_BRIGHTNESS
			
			task.wait(math.max(0, TV_OPEN_DELAY - flickerTime))
			
			if not tv.Parent then
				cycleDone()
				return
			end
			
			normalCtl = runCloneEntity(false, tv, groundY, function()
				phase = "normal"
				if not TV_STAY_WHITE then
					doRestoreTV()
				end
			end, function()
				if not TV_STAY_WHITE then
					doRestoreTV()
				end
				cycleDone()
			end)
		end)
	end
	
	prompt.Triggered:Connect(function(plr)
		if plr ~= player then return end
		local cdTool = holdingCD()
		
		if phase == "idle" then
			if cdTool then
				insertDisc(cdTool, nil)
			else
				openTV()
			end
		elseif phase == "normal" and cdTool and normalCtl and normalCtl.IsReady() then
			insertDisc(cdTool, normalCtl)
		end
	end)
	
	if TV_PUSH_ENABLED then
		local pivot0 = tv:GetPivot()
		local extMin = Vector3.new(math.huge, math.huge, math.huge)
		local extMax = Vector3.new(-math.huge, -math.huge, -math.huge)
		local tvParts = {}
		for _, d in ipairs(tv:GetDescendants()) do
			if d:IsA("BasePart") then
				table.insert(tvParts, d)
				local half = d.Size / 2
				for sx = -1, 1, 2 do
					for sy = -1, 1, 2 do
						for sz = -1, 1, 2 do
							local c = pivot0:PointToObjectSpace((d.CFrame * CFrame.new(half.X * sx, half.Y * sy, half.Z * sz)).Position)
							extMin = Vector3.new(math.min(extMin.X, c.X), math.min(extMin.Y, c.Y), math.min(extMin.Z, c.Z))
							extMax = Vector3.new(math.max(extMax.X, c.X), math.max(extMax.Y, c.Y), math.max(extMax.Z, c.Z))
						end
					end
				end
			end
		end
		
		if #tvParts > 0 then
			local extSize = extMax - extMin
			local extMid = (extMin + extMax) / 2
			
			local useZ = (TV_PUSH_AXIS == "Z")
			local axisUnit = useZ and Vector3.new(0, 0, 1) or Vector3.new(1, 0, 0)
			local function across(v)
				return useZ and v.Z or v.X
			end
			local function along(v)
				return useZ and v.X or v.Z
			end
			local minAcross, maxAcross = across(extMin), across(extMax)
			local minAlong, maxAlong = along(extMin), along(extMax)
			
			local function sideContact(worldPos, dist)
				local rel = tv:GetPivot():PointToObjectSpace(worldPos)
				if rel.Y < extMin.Y - 1 or rel.Y > extMax.Y + 3 then return 0 end
				local a, l = across(rel), along(rel)
				if l < minAlong - 0.5 or l > maxAlong + 0.5 then return 0 end
				if a > maxAcross and a - maxAcross <= dist then return 1 end
				if a < minAcross and minAcross - a <= dist then return -1 end
				return 0
			end
			
			local overlap = OverlapParams.new()
			overlap.FilterType = Enum.RaycastFilterType.Exclude
			local function blockedAt(newCF)
				local list = {tv}
				if player.Character then
					table.insert(list, player.Character)
				end
				overlap.FilterDescendantsInstances = list
				local boxSize = Vector3.new(math.max(extSize.X - 0.4, 0.2), math.max(extSize.Y - 1.2, 0.2), math.max(extSize.Z - 0.4, 0.2))
				for _, p in ipairs(Workspace:GetPartBoundsInBox(newCF * CFrame.new(extMid), boxSize, overlap)) do
					if p.CanCollide then
						return true
					end
				end
				return false
			end
			
			local pushing = false
			local needExit = false
			local jumpFlag = false
			local offset = Vector3.new(0, 0, 0)
			local baseY = 0
			
			local function attach(hrp, sign)
				local pivot = tv:GetPivot()
				local off = pivot:PointToObjectSpace(hrp.Position)
				local a = (sign > 0) and (maxAcross + TV_PUSH_STICK_GAP) or (minAcross - TV_PUSH_STICK_GAP)
				if useZ then
					off = Vector3.new(off.X, off.Y, a)
				else
					off = Vector3.new(a, off.Y, off.Z)
				end
				offset = off
				baseY = pivot.Position.Y
				pushing = true
				for _, p in ipairs(tvParts) do
					if p.Parent then
						p.CanCollide = false
					end
				end
			end
			
			local function detach()
				if not pushing then return end
				pushing = false
				needExit = true
				for _, p in ipairs(tvParts) do
					if p.Parent then
						p.CanCollide = true
					end
				end
			end
			
			local jumpConn = UserInputService.JumpRequest:Connect(function()
				jumpFlag = true
			end)
			
			local pushConn
			pushConn = RunService.Heartbeat:Connect(function()
				if not tv.Parent then
					pushConn:Disconnect()
					jumpConn:Disconnect()
					return
				end
				
				local char = player.Character
				local hrp = char and char:FindFirstChild("HumanoidRootPart")
				local hum = char and char:FindFirstChildOfClass("Humanoid")
				local jumped = jumpFlag
				jumpFlag = false
				
				if not hrp or not hum or hum.Health <= 0 or phase ~= "idle" then
					detach()
					return
				end
				
				if pushing then
					if jumped or hum:GetState() == Enum.HumanoidStateType.Jumping then
						detach()
						return
					end
					
					local pivot = tv:GetPivot()
					local rot = pivot - pivot.Position
					local want = hrp.Position - rot:VectorToWorldSpace(offset)
					want = Vector3.new(want.X, baseY, want.Z)
					local cur = pivot.Position
					local delta = want - cur
					
					if delta.Magnitude > 3 then
						detach()
						return
					end
					
					if delta.Magnitude > 0.002 then
						local function cfAt(pos)
							return CFrame.new(pos) * rot
						end
						if not blockedAt(cfAt(want)) then
							tv:PivotTo(cfAt(want))
						else
							local tryX = Vector3.new(want.X, baseY, cur.Z)
							local tryZ = Vector3.new(cur.X, baseY, want.Z)
							if not blockedAt(cfAt(tryX)) then
								tv:PivotTo(cfAt(tryX))
							elseif not blockedAt(cfAt(tryZ)) then
								tv:PivotTo(cfAt(tryZ))
							end
						end
					end
					return
				end
				
				if needExit then
					if sideContact(hrp.Position, TV_PUSH_TOUCH_DISTANCE * 2.5) == 0 then
						needExit = false
					end
					return
				end
				
				local sign = sideContact(hrp.Position, TV_PUSH_TOUCH_DISTANCE)
				if sign ~= 0 and not jumped then
					local into = tv:GetPivot():VectorToWorldSpace(axisUnit) * (-sign)
					if hum.MoveDirection:Dot(into) > 0.3 then
						attach(hrp, sign)
					end
				end
			end)
		end
	end
end

local function spawnTV(groundPos, playerPos)
	if not tvTemplate then return end
	local tv = tvTemplate:Clone()
	tv.Name = "R4NS0M_TV"
	
	if TV_SCALE ~= 1 then
		pcall(function()
			tv:ScaleTo(TV_SCALE)
		end)
	end
	
	local look = Vector3.new(playerPos.X - groundPos.X, 0, playerPos.Z - groundPos.Z)
	local faceCF = CFrame.new(groundPos)
	if look.Magnitude > 0.1 then
		faceCF = CFrame.lookAt(groundPos, groundPos + look)
	end
	tv:PivotTo(faceCF * TV_ROTATION)
	
	local cf, size = tv:GetBoundingBox()
	tv:PivotTo(tv:GetPivot() + Vector3.new(0, groundPos.Y - (cf.Position.Y - size.Y / 2), 0))
	
	tv.Parent = Workspace
	setupTV(tv, groundPos.Y)
end

--------------------------------------------------------------------------------
-- PRE-PHASE[cite: 1]
--------------------------------------------------------------------------------
local preGui = Instance.new("ScreenGui")
preGui.Name = "JumpscareDownloadGui"
preGui.IgnoreGuiInset = true
preGui.ResetOnSpawn = false
preGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
preGui.Parent = playerGui

local preBg = Instance.new("ImageLabel")
preBg.Name = "PreBackground"
preBg.Size = UDim2.new(1, 0, 1, 0)
preBg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
preBg.BackgroundTransparency = 1
preBg.BorderSizePixel = 0
preBg.Image = "rbxthumb://type=Asset&id=" .. tostring(DOWNLOAD_BG_IMAGE_ID) .. "&w=768&h=432"
preBg.ScaleType = Enum.ScaleType.Crop
preBg.ImageTransparency = 1
preBg.Visible = false
preBg.ZIndex = 1
preBg.Parent = preGui

local function makePreImage(id, size, anchor, pos)
	local img = Instance.new("ImageLabel")
	img.Image = "rbxthumb://type=Asset&id=" .. tostring(id) .. "&w=420&h=420"
	img.BackgroundTransparency = 1
	img.Size = UDim2.new(0, size, 0, size)
	img.AnchorPoint = anchor
	img.Position = pos
	img.ZIndex = 2
	img.Visible = false
	img.Parent = preGui
	return img
end

local cornerImage = makePreImage(PRE_IMAGE_A, PRE_CORNER_SIZE, Vector2.new(0, 0), UDim2.new(0, 20, 0, 20))
local flashImage = makePreImage(PRE_IMAGE_B, PRE_CENTER_SIZE, Vector2.new(0.5, 0.5), UDim2.new(0.5, 0, 0.5, 0))
local stareImage = makePreImage(PRE_IMAGE_A, PRE_CENTER_SIZE, Vector2.new(0.5, 0.5), UDim2.new(0.5, 0, 0.5, 0))
cornerImage.Visible = true

local spawnSound = Instance.new("Sound")
spawnSound.Name = "SpawnSound"
spawnSound.SoundId = "rbxassetid://92453621152905"
spawnSound.Volume = 5
spawnSound.Parent = SoundService
spawnSound:Play()

local function releaseSpawnSound()
	local s = spawnSound
	spawnSound = nil
	if not s then return end
	s.Ended:Connect(function()
		s:Destroy()
	end)
	Debris:AddItem(s, 60)
end

local mainSequenceTriggered = false

local function startMainSequence()
	if mainSequenceTriggered then return end
	mainSequenceTriggered = true
	
	if preGui then preGui:Destroy() end
	releaseSpawnSound()
	
	local sound = Instance.new("Sound")
	sound.Name = "JumpscareSound"
	sound.SoundId = "rbxassetid://" .. tostring(JUMPSCARE_SOUND_ID)
	sound.Volume = 10
	sound.PlaybackSpeed = 1.0
	sound.Parent = SoundService
	sound:Play()

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "JumpscareDownloadGui"
	screenGui.IgnoreGuiInset = true
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui

	local phase1Bg = Instance.new("Frame")
	phase1Bg.Name = "Phase1Background"
	phase1Bg.Size = UDim2.new(1, 0, 1, 0)
	phase1Bg.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
	phase1Bg.BorderSizePixel = 0
	phase1Bg.Parent = screenGui

	local imageLabel = Instance.new("ImageLabel")
	imageLabel.Name = "CenterImage"
	imageLabel.Image = "rbxthumb://type=Asset&id=12351005389&w=420&h=420"
	imageLabel.BackgroundTransparency = 1
	imageLabel.Size = UDim2.new(0, 350, 0, 350)
	imageLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	imageLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
	imageLabel.Parent = phase1Bg

	local originalPosition = imageLabel.Position
	local phase1Duration = 0.8
	local elapsed = 0
	local shakeIntensity = 12

	local connection
	connection = RunService.RenderStepped:Connect(function(dt)
		elapsed += dt
		
		if math.random(1, 3) == 1 then
			phase1Bg.BackgroundColor3 = Color3.fromRGB(math.random(150, 255), 0, 0)
		end
		
		if elapsed >= phase1Duration then
			connection:Disconnect()
			phase1Bg:Destroy()
			return
		end
		
		local offsetX = math.random(-shakeIntensity, shakeIntensity)
		local offsetY = math.random(-shakeIntensity, shakeIntensity)
		imageLabel.Position = originalPosition + UDim2.new(0, offsetX, 0, offsetY)
		
		if math.floor(elapsed * 40) % 2 == 0 then
			imageLabel.ImageColor3 = Color3.fromRGB(255, 255, 255)
		else
			imageLabel.ImageColor3 = Color3.fromRGB(255, 0, 0)
		end
	end)

	task.delay(phase1Duration, function()
		local bgFrame = Instance.new("ImageLabel")
		bgFrame.Name = "DownloadBackground"
		bgFrame.Size = UDim2.new(1, 0, 1, 0)
		bgFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		bgFrame.BorderSizePixel = 0
		bgFrame.Image = "rbxthumb://type=Asset&id=" .. tostring(DOWNLOAD_BG_IMAGE_ID) .. "&w=768&h=432"
		bgFrame.ScaleType = Enum.ScaleType.Crop
		bgFrame.Parent = screenGui
		
		local textLabel = Instance.new("TextLabel")
		textLabel.Name = "DownloadingText"
		textLabel.Size = UDim2.new(0, 500, 0, 80)
		textLabel.AnchorPoint = Vector2.new(0.5, 0.5)
		textLabel.Position = UDim2.new(0.5, 0, 0.43, 0)
		textLabel.BackgroundTransparency = 1
		textLabel.Text = "Downloading."
		textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		textLabel.TextScaled = true
		textLabel.Font = Enum.Font.Arcade
		textLabel.Parent = bgFrame
		
		local barContainer = Instance.new("Frame")
		barContainer.Name = "LoadingBarContainer"
		barContainer.Size = UDim2.new(0, 480, 0, 36)
		barContainer.AnchorPoint = Vector2.new(0.5, 0.5)
		barContainer.Position = UDim2.new(0.5, 0, 0.57, 0)
		barContainer.BackgroundTransparency = 0.3
		barContainer.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
		barContainer.BorderSizePixel = 0
		barContainer.Parent = bgFrame
		
		local uiList = Instance.new("UIListLayout")
		uiList.FillDirection = Enum.FillDirection.Horizontal
		uiList.HorizontalAlignment = Enum.HorizontalAlignment.Center
		uiList.VerticalAlignment = Enum.VerticalAlignment.Center
		uiList.Padding = UDim.new(0, 8)
		uiList.Parent = barContainer
		
		local blocks = {}
		for i = 1, 5 do
			local block = Instance.new("Frame")
			block.Name = "Block_" .. i
			block.Size = UDim2.new(0, 84, 0, 22)
			block.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
			block.BorderSizePixel = 0
			block.Parent = barContainer
			table.insert(blocks, block)
		end
		
		local originalTextPos = textLabel.Position
		local originalBarPos = barContainer.Position
		local phase2Elapsed = 0
		local totalPhase2Duration = 1.2
		local textConn
		
		textConn = RunService.RenderStepped:Connect(function(dt)
			phase2Elapsed += dt
			
			local progress = math.clamp(phase2Elapsed / totalPhase2Duration, 0, 1)
			
			local activeBlocksCount = math.ceil(progress * 5)
			for index, block in ipairs(blocks) do
				if index <= activeBlocksCount then
					block.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				else
					block.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
				end
			end
			
			if progress >= 1 then
				textConn:Disconnect()
				if screenGui then screenGui:Destroy() end
				
				if sound then
					if sound.IsPlaying then
						sound.Ended:Connect(function()
							sound:Destroy()
						end)
						Debris:AddItem(sound, 120)
					else
						sound:Destroy()
					end
				end
				
				local finalGui = Instance.new("ScreenGui")
				finalGui.Name = "FinalShakyGui"
				finalGui.IgnoreGuiInset = true
				finalGui.ResetOnSpawn = false
				finalGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
				finalGui.Parent = playerGui
				
				local themeSound = Instance.new("Sound")
				themeSound.Name = "R4NS0MTheme"
				themeSound.SoundId = "rbxassetid://" .. tostring(THEME_SOUND_ID)
				themeSound.Volume = THEME_VOLUME
				themeSound.PlaybackSpeed = THEME_SPEED
				themeSound.Looped = true
				themeSound.Parent = SoundService
				themeSound:Play()
				
				local themeExt = nil
				
				local function stopTheme()
					if themeSound then
						themeSound:Stop()
						themeSound:Destroy()
						themeSound = nil
					end
					if themeExt then
						themeExt:Stop()
						themeExt:Destroy()
						themeExt = nil
					end
				end
				
				task.spawn(function()
					local ref = themeSound
					local t0 = os.clock()
					while ref and ref.Parent and ref.TimeLength == 0 and os.clock() - t0 < 5 do
						task.wait(0.1)
					end
					if ref and ref.Parent and ref.TimeLength > 0 then
						ref.PlaybackSpeed = ref.TimeLength / THEME_TARGET_SECONDS
						ref.Looped = false
					end
				end)
				
				if THEME_EXTEND_JUMPSCARE then
					task.spawn(function()
						local w0 = os.clock()
						while sound and sound.Parent and sound.IsPlaying and os.clock() - w0 < 10 do
							task.wait(0.1)
						end
						if not themeSound then return end
						
						local ext = Instance.new("Sound")
						ext.Name = "R4NS0MThemeExtension"
						ext.SoundId = "rbxassetid://" .. tostring(THEME_SOUND_ID)
						ext.Volume = THEME_VOLUME
						ext.PlaybackSpeed = 1
						ext.Looped = false
						ext.Parent = SoundService
						themeExt = ext
						ext:Play()
						
						local l0 = os.clock()
						while ext.Parent and ext.TimeLength == 0 and os.clock() - l0 < 5 do
							task.wait(0.1)
						end
						local half = ext.TimeLength / 2
						while ext.Parent and half > 0 and ext.TimePosition < half do
							task.wait(0.1)
						end
						if ext.Parent then
							ext:Stop()
							ext:Destroy()
						end
						if themeExt == ext then
							themeExt = nil
						end
					end)
				end
				
				local backgroundPopups = {}
				local hasFailed = false
				local hasWon = false
				
				local randomAssetList = {
					"17665445431",
					"17297286789",
					"15145168263",
					"13875885601",
					"140614440237846",
					"3128134660",
					"5490671314"
				}
				
				local titleOptions = {
					"F0UND Y0U",
					"RANSOM",
					"MOSNAR",
					"YOURGOLDISTASTY",
					"ENCRYPTED",
					"R4NS0M1SH3R3",
					"RANNSOM",
					"ENCRYPTION"
				}
				
				local function getRandomWindowSize()
					local shapeType = math.random(1, 3)
					if shapeType == 1 then
						local sz = math.random(110, 145)
						return UDim2.new(0, sz, 0, sz + 22)
					elseif shapeType == 2 then
						return UDim2.new(0, math.random(160, 220), 0, math.random(120, 180) + 22)
					else
						return UDim2.new(0, math.random(230, 310), 0, math.random(170, 230) + 22)
					end
				end
				
				for i = 1, POPUP_COUNT do
					task.delay((i - 1) * POPUP_DELAY, function()
						if not finalGui or not finalGui.Parent or hasFailed or hasWon then return end
						
						local chosenAsset = randomAssetList[math.random(1, #randomAssetList)]
						local windowSize = getRandomWindowSize()
						
						local popWindow = Instance.new("Frame")
						popWindow.Name = "VirusWindow_" .. i
						popWindow.BackgroundColor3 = Color3.fromRGB(60, 0, 0)
						popWindow.BorderSizePixel = 0
						popWindow.Size = UDim2.new(0, 0, 0, 0)
						popWindow.AnchorPoint = Vector2.new(0.5, 0.5)
						popWindow.Position = UDim2.new(math.random(10, 90)/100, 0, math.random(10, 90)/100, 0)
						popWindow.ClipsDescendants = true
						popWindow.ZIndex = 1
						popWindow.Parent = finalGui
						
						local corner = Instance.new("UICorner")
						corner.CornerRadius = UDim.new(0, 5)
						corner.Parent = popWindow
						
						local innerContainer = Instance.new("Frame")
						innerContainer.Name = "InnerContainer"
						innerContainer.Size = UDim2.new(1, -4, 1, -4)
						innerContainer.Position = UDim2.new(0, 2, 0, 2)
						innerContainer.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
						innerContainer.BorderSizePixel = 0
						innerContainer.Parent = popWindow
						
						local innerCorner = Instance.new("UICorner")
						innerCorner.CornerRadius = UDim.new(0, 4)
						innerCorner.Parent = innerContainer
						
						local headerBar = Instance.new("Frame")
						headerBar.Name = "HeaderBar"
						headerBar.Size = UDim2.new(1, 0, 0, 22)
						headerBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
						headerBar.BackgroundTransparency = 0
						headerBar.BorderSizePixel = 0
						headerBar.Parent = innerContainer
						
						local headerCorner = Instance.new("UICorner")
						headerCorner.CornerRadius = UDim.new(0, 4)
						headerCorner.Parent = headerBar
						
						local headerText = Instance.new("TextLabel")
						headerText.Name = "HeaderTitle"
						headerText.Size = UDim2.new(1, -12, 1, 0)
						headerText.Position = UDim2.new(0, 6, 0, 0)
						headerText.BackgroundTransparency = 1
						headerText.Text = titleOptions[math.random(1, #titleOptions)]
						headerText.TextColor3 = Color3.fromRGB(20, 20, 20)
						headerText.TextSize = 11
						headerText.Font = Enum.Font.SourceSansBold
						headerText.TextXAlignment = Enum.TextXAlignment.Left
						headerText.Parent = headerBar
						
						local popImg = Instance.new("ImageLabel")
						popImg.Name = "PopupImage"
						popImg.Image = "rbxthumb://type=Asset&id=" .. chosenAsset .. "&w=420&h=420"
						popImg.BackgroundTransparency = 1
						popImg.Size = UDim2.new(1, 0, 1, -22)
						popImg.Position = UDim2.new(0, 0, 0, 22)
						popImg.Parent = innerContainer
						
						local flicker = Instance.new("Frame")
						flicker.Name = "FlickerOverlay"
						flicker.Size = UDim2.new(1, 0, 1, 0)
						flicker.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
						flicker.BorderSizePixel = 0
						flicker.Visible = false
						flicker.ZIndex = 5
						flicker.Parent = popWindow
						
						local flickerCorner = Instance.new("UICorner")
						flickerCorner.CornerRadius = UDim.new(0, 5)
						flickerCorner.Parent = flicker
						
						local flickerImg = Instance.new("ImageLabel")
						flickerImg.BackgroundTransparency = 1
						flickerImg.Size = UDim2.new(1, 0, 1, 0)
						flickerImg.Image = "rbxthumb://type=Asset&id=" .. tostring(POPUP_FLICKER_IMAGE_ID) .. "&w=420&h=420"
						flickerImg.ZIndex = 6
						flickerImg.Parent = flicker
						
						local popInfo = TweenInfo.new(POPUP_POP_TIME, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
						TweenService:Create(popWindow, popInfo, {Size = windowSize}):Play()
						
						table.insert(backgroundPopups, {
							Object = popWindow,
							BasePosition = popWindow.Position,
							DespawnTimer = math.random(POPUP_LIFETIME_MIN, POPUP_LIFETIME_MAX),
							Elapsed = 0,
							IsDespawning = false,
							IsShaking = (math.random(1, 2) == 1),
							Flicker = flicker,
							FlickerTimer = 0,
							FlickerLeft = 0
						})
					end)
				end
				
				local mainWindow = Instance.new("Frame")
				mainWindow.Name = "ShapeImage_MainContainer"
				mainWindow.BackgroundColor3 = Color3.fromRGB(60, 0, 0)
				mainWindow.BorderSizePixel = 0
				mainWindow.Size = UDim2.new(0, WINDOW_WIDTH, 0, WINDOW_HEIGHT)
				mainWindow.AnchorPoint = Vector2.new(0.5, 0.5)
				mainWindow.Position = UDim2.new(math.random(20, 80)/100, 0, math.random(20, 80)/100, 0)
				mainWindow.ZIndex = 10
				mainWindow.Parent = finalGui
				
				local mainCorner = Instance.new("UICorner")
				mainCorner.CornerRadius = UDim.new(0, 5)
				mainCorner.Parent = mainWindow
				
				local mainInner = Instance.new("Frame")
				mainInner.Name = "InnerContainer"
				mainInner.Size = UDim2.new(1, -4, 1, -4)
				mainInner.Position = UDim2.new(0, 2, 0, 2)
				mainInner.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
				mainInner.BorderSizePixel = 0
				mainInner.Parent = mainWindow
				
				local mainInnerCorner = Instance.new("UICorner")
				mainInnerCorner.CornerRadius = UDim.new(0, 4)
				mainInnerCorner.Parent = mainInner
				
				local mainHeaderBar = Instance.new("Frame")
				mainHeaderBar.Name = "HeaderBar"
				mainHeaderBar.Size = UDim2.new(1, 0, 0, 22)
				mainHeaderBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				mainHeaderBar.BackgroundTransparency = 0
				mainHeaderBar.BorderSizePixel = 0
				mainHeaderBar.Parent = mainInner
				
				local mainHeaderCorner = Instance.new("UICorner")
				mainHeaderCorner.CornerRadius = UDim.new(0, 4)
				mainHeaderCorner.Parent = mainHeaderBar
				
				local mainHeaderText = Instance.new("TextLabel")
				mainHeaderText.Name = "HeaderTitle"
				mainHeaderText.Size = UDim2.new(1, -12, 1, 0)
				mainHeaderText.Position = UDim2.new(0, 6, 0, 0)
				mainHeaderText.BackgroundTransparency = 1
				mainHeaderText.Text = "R4NS0M"
				mainHeaderText.TextColor3 = Color3.fromRGB(20, 20, 20)
				mainHeaderText.TextSize = 11
				mainHeaderText.Font = Enum.Font.SourceSansBold
				mainHeaderText.TextXAlignment = Enum.TextXAlignment.Left
				mainHeaderText.Parent = mainHeaderBar
				
				local mainImage = Instance.new("ImageLabel")
				mainImage.Name = "ShapeImage_Main"
				mainImage.Image = "rbxthumb://type=Asset&id=133985779703515&w=420&h=420"
				mainImage.BackgroundTransparency = 1
				mainImage.Size = UDim2.new(1, 0, 1, -22)
				mainImage.Position = UDim2.new(0, 0, 0, 22)
				mainImage.Parent = mainInner
				
				local mainTargetPos = mainWindow.Position
				local mainTpElapsed = 0
				local mainTpInterval = math.random(3, 5)
				
				local container = Instance.new("Frame")
				container.Name = "CoinTextContainer"
				container.Size = UDim2.new(0, 140, 0, 45)
				container.AnchorPoint = Vector2.new(0, 1)
				container.Position = UDim2.new(0, 22, 1, -12)
				container.BackgroundTransparency = 1
				container.Parent = mainImage
				
				local listLayout = Instance.new("UIListLayout")
				listLayout.FillDirection = Enum.FillDirection.Horizontal
				listLayout.VerticalAlignment = Enum.VerticalAlignment.Center
				listLayout.Padding = UDim.new(0, 4)
				listLayout.Parent = container
				
				local displayCoins = 500.0
				local targetCoins = 500
				
				local subText = Instance.new("TextLabel")
				subText.Name = "BottomLeftText"
				subText.Size = UDim2.new(0, 75, 0, 40)
				subText.BackgroundTransparency = 1
				subText.Text = tostring(targetCoins)
				subText.TextColor3 = Color3.fromRGB(255, 255, 0)
				subText.TextScaled = true
				subText.TextXAlignment = Enum.TextXAlignment.Left
				
				local textFontSuccess, textFontResult = pcall(function()
					return Enum.Font.Oswald
				end)
				subText.Font = textFontSuccess and textFontResult or Enum.Font.SourceSansBold
				subText.Parent = container
				
				local coinImage = Instance.new("ImageLabel")
				coinImage.Name = "CoinImage"
				coinImage.Image = "rbxthumb://type=Asset&id=12771100802&w=150&h=150"
				coinImage.BackgroundTransparency = 1
				coinImage.Size = UDim2.new(0, 40, 0, 40)
				coinImage.Parent = container
				
				local timerText = Instance.new("TextLabel")
				timerText.Name = "TimerText"
				timerText.Size = UDim2.new(0, 115, 0, 50)
				timerText.AnchorPoint = Vector2.new(1, 1)
				timerText.Position = UDim2.new(1, -35, 1, -12)
				timerText.BackgroundTransparency = 1
				timerText.TextColor3 = Color3.fromRGB(0, 0, 0)
				timerText.TextScaled = true
				timerText.TextXAlignment = Enum.TextXAlignment.Right
				timerText.Font = subText.Font
				timerText.Parent = mainImage
				
				local timeRemaining = 90.0
				
				local finalConn
				finalConn = RunService.RenderStepped:Connect(function(dt)
					if hasFailed or hasWon then return end
					
					if targetCoins <= 0 and displayCoins <= 0 and not hasWon then
						hasWon = true
						if finalConn then finalConn:Disconnect() end
						
						stopTheme()
						clearRoundObjects()
						
						local vicSound = Instance.new("Sound")
						vicSound.Name = "VictorySound"
						vicSound.SoundId = "rbxassetid://" .. tostring(VICTORY_SOUND_ID)
						vicSound.Volume = 5
						vicSound.Parent = SoundService
						vicSound:Play()
						
						for _, popData in ipairs(backgroundPopups) do
							if popData.Object and popData.Object.Parent then
								popData.Object:Destroy()
							end
						end
						
						task.delay(0.4, function()
							if finalGui then finalGui:Destroy() end
							
							local vicGui = Instance.new("ScreenGui")
							vicGui.Name = "VictoryPopupGui"
							vicGui.IgnoreGuiInset = true
							vicGui.ResetOnSpawn = false
							vicGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
							vicGui.Parent = playerGui
							
							local vicWindow = Instance.new("Frame")
							vicWindow.Name = "VictoryWindow"
							vicWindow.BackgroundColor3 = Color3.fromRGB(60, 0, 0)
							vicWindow.BorderSizePixel = 0
							vicWindow.Size = UDim2.new(0, WINDOW_WIDTH, 0, WINDOW_HEIGHT)
							vicWindow.AnchorPoint = Vector2.new(0.5, 0.5)
							vicWindow.Position = UDim2.new(0.5, 0, 0.5, 0)
							vicWindow.ClipsDescendants = true
							vicWindow.Parent = vicGui
							
							local vicCorner = Instance.new("UICorner")
							vicCorner.CornerRadius = UDim.new(0, 5)
							vicCorner.Parent = vicWindow
							
							local vicInner = Instance.new("Frame")
							vicInner.Name = "InnerContainer"
							vicInner.Size = UDim2.new(1, -4, 1, -4)
							vicInner.Position = UDim2.new(0, 2, 0, 2)
							vicInner.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
							vicInner.BorderSizePixel = 0
							vicInner.Parent = vicWindow
							
							local vicInnerCorner = Instance.new("UICorner")
							vicInnerCorner.CornerRadius = UDim.new(0, 4)
							vicInnerCorner.Parent = vicInner
							
							local vicHeaderBar = Instance.new("Frame")
							vicHeaderBar.Name = "HeaderBar"
							vicHeaderBar.Size = UDim2.new(1, 0, 0, 22)
							vicHeaderBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
							vicHeaderBar.BackgroundTransparency = 0
							vicHeaderBar.BorderSizePixel = 0
							vicHeaderBar.Parent = vicInner
							
							local vicHeaderCorner = Instance.new("UICorner")
							vicHeaderCorner.CornerRadius = UDim.new(0, 4)
							vicHeaderCorner.Parent = vicHeaderBar
							
							local vicHeaderText = Instance.new("TextLabel")
							vicHeaderText.Name = "HeaderTitle"
							vicHeaderText.Size = UDim2.new(1, -12, 1, 0)
							vicHeaderText.Position = UDim2.new(0, 6, 0, 0)
							vicHeaderText.BackgroundTransparency = 1
							vicHeaderText.Text = "R4NS0M"
							vicHeaderText.TextColor3 = Color3.fromRGB(20, 20, 20)
							vicHeaderText.TextSize = 11
							vicHeaderText.Font = Enum.Font.SourceSansBold
							vicHeaderText.TextXAlignment = Enum.TextXAlignment.Left
							vicHeaderText.Parent = vicHeaderBar
							
							local vicImage = Instance.new("ImageLabel")
							vicImage.Name = "CenterVictoryImage"
							vicImage.Image = "rbxthumb://type=Asset&id=134494788780774&w=420&h=420"
							vicImage.BackgroundTransparency = 1
							vicImage.Size = UDim2.new(1, 0, 1, -22)
							vicImage.Position = UDim2.new(0, 0, 0, 22)
							vicImage.Parent = vicInner
							
							task.delay(4.0, function()
								if vicWindow and vicWindow.Parent then
									local tweenInfo = TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
									local shrinkTween = TweenService:Create(vicWindow, tweenInfo, {
										Size = UDim2.new(0, 0, 0, 0),
										BackgroundTransparency = 1
									})
									shrinkTween:Play()
									shrinkTween.Completed:Connect(function()
										vicGui:Destroy()
										if vicSound then vicSound:Destroy() end
									end)
								end
							end)
						end)
						return
					end
					
					timeRemaining -= dt
					local mins = math.floor(timeRemaining / 60)
					local secs = math.floor(timeRemaining % 60)
					timerText.Text = string.format("%d:%02d", mins, secs)
					
					if timeRemaining <= 0 and not hasFailed then
						hasFailed = true
						if finalConn then finalConn:Disconnect() end
						
						stopTheme()
						clearRoundObjects()
						if finalGui then finalGui:Destroy() end
						
						local failGui = Instance.new("ScreenGui")
						failGui.Name = "FailureJumpscareGui"
						failGui.IgnoreGuiInset = true
						failGui.ResetOnSpawn = false
						failGui.Parent = playerGui
						
						local failBg = Instance.new("Frame")
						failBg.Size = UDim2.new(1, 0, 1, 0)
						failBg.BackgroundColor3 = Color3.fromRGB(40, 0, 0)
						failBg.BorderSizePixel = 0
						failBg.Parent = failGui
						
						local failImage = Instance.new("ImageLabel")
						failImage.Image = "rbxthumb://type=Asset&id=12436809176&w=420&h=420"
						failImage.BackgroundTransparency = 1
						failImage.Size = UDim2.new(0, 400, 0, 400)
						failImage.AnchorPoint = Vector2.new(0.5, 0.5)
						failImage.Position = UDim2.new(0.5, 0, 0.5, 0)
						failImage.Parent = failBg
						
						local failElapsed = 0
						local failImageOriginalPos = failImage.Position
						local failConn
						failConn = RunService.RenderStepped:Connect(function(fDt)
							failElapsed += fDt
							local sx = math.random(-8, 8)
							local sy = math.random(-8, 8)
							failImage.Position = failImageOriginalPos + UDim2.new(0, sx, 0, sy)
							
							if failElapsed >= 0.8 then
								failConn:Disconnect()
								if failGui then failGui:Destroy() end
								
								local char = player.Character
								if char then
									local humanoid = char:FindFirstChildOfClass("Humanoid")
									if humanoid then
										local damageAmount = humanoid.MaxHealth * 0.9
										humanoid.Health = math.max(0, humanoid.Health - damageAmount)
									end
								end
							end
						end)
						return
					end
					
					mainTpElapsed += dt
					mainWindow.Position = mainWindow.Position:Lerp(mainTargetPos, dt * 6)
					
					if mainTpElapsed >= mainTpInterval then
						mainTpElapsed = 0
						mainTpInterval = math.random(3, 5)
						mainTargetPos = UDim2.new(math.random(15, 85)/100, 0, math.random(15, 85)/100, 0)
					end
					
					local rx = math.random(-1, 1)
					local ry = math.random(-1, 1)
					mainWindow.Position = mainWindow.Position + UDim2.new(0, rx, 0, ry)
					
					for _, popData in ipairs(backgroundPopups) do
						if popData.Object and popData.Object.Parent then
							if not popData.IsDespawning then
								popData.Elapsed += dt
								
								if popData.IsShaking then
									local sx = math.random(-3, 3)
									local sy = math.random(-3, 3)
									popData.Object.Position = popData.BasePosition + UDim2.new(0, sx, 0, sy)
								end
								
								if popData.FlickerLeft > 0 then
									popData.FlickerLeft -= dt
									if popData.FlickerLeft <= 0 then
										popData.Flicker.Visible = false
									end
								elseif popData.Elapsed > POPUP_POP_TIME then
									popData.FlickerTimer += dt
									if popData.FlickerTimer >= POPUP_FLICKER_CHECK then
										popData.FlickerTimer -= POPUP_FLICKER_CHECK
										if math.random() < POPUP_FLICKER_CHANCE then
											popData.Flicker.Visible = true
											popData.FlickerLeft = POPUP_FLICKER_TIME
										end
									end
								end
								
								if popData.Elapsed >= popData.DespawnTimer then
									popData.IsDespawning = true
									popData.Flicker.Visible = false
									task.spawn(function()
										local win = popData.Object
										if not win or not win.Parent then return end
										local info = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
										local shrink = TweenService:Create(win, info, {
											Size = UDim2.new(0, 0, 0, 0),
											BackgroundTransparency = 1
										})
										shrink:Play()
										shrink.Completed:Connect(function()
											if win then win:Destroy() end
										end)
									end)
								end
							end
						end
					end
					
					if displayCoins > targetCoins then
						displayCoins = math.max(targetCoins, displayCoins - (dt * COUNTER_DROP_SPEED))
						subText.Text = tostring(math.round(displayCoins))
					elseif displayCoins < targetCoins then
						displayCoins = math.min(targetCoins, displayCoins + (dt * COUNTER_DROP_SPEED))
						subText.Text = tostring(math.round(displayCoins))
					end
				end)
				
				local crucifyBusy = false
				
				local function isRoundActive()
					return finalGui ~= nil and finalGui.Parent ~= nil and not hasWon and not hasFailed
				end
				
				local function crucifyRound()
					hasWon = true
					if finalConn then finalConn:Disconnect() end
					stopTheme()
					clearRoundObjects()
					
					local info = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In)
					mainWindow.ClipsDescendants = true
					TweenService:Create(mainWindow, info, {
						Size = UDim2.new(0, 0, 0, 0),
						BackgroundTransparency = 1
					}):Play()
					for _, popData in ipairs(backgroundPopups) do
						if popData.Object and popData.Object.Parent then
							TweenService:Create(popData.Object, info, {
								Size = UDim2.new(0, 0, 0, 0),
								BackgroundTransparency = 1
							}):Play()
						end
					end
					task.delay(0.6, function()
						if finalGui then
							finalGui:Destroy()
						end
					end)
				end
				
				local function spawnCrucifixCross()
					if not crossTemplate then return end
					local char = player.Character
					local hrp = char and char:FindFirstChild("HumanoidRootPart")
					if not hrp then return end
					
					local flat = Vector3.new(hrp.CFrame.LookVector.X, 0, hrp.CFrame.LookVector.Z)
					if flat.Magnitude < 0.1 then
						flat = Vector3.new(0, 0, -1)
					end
					flat = flat.Unit
					
					local target = hrp.Position + flat * CRUCIFIX_CROSS_DISTANCE
					local rp = RaycastParams.new()
					rp.FilterType = Enum.RaycastFilterType.Exclude
					rp.IgnoreWater = true
					rp.FilterDescendantsInstances = {char}
					local hit = Workspace:Raycast(target + Vector3.new(0, 6, 0), Vector3.new(0, -40, 0), rp)
					local groundPos = hit and hit.Position or Vector3.new(target.X, hrp.Position.Y - 3, target.Z)
					
					local cross = crossTemplate:Clone()
					cross.Name = "R4NS0M_CrucifixCross"
					cross:PivotTo(CFrame.lookAt(groundPos, groundPos - flat) * CRUCIFIX_CROSS_ROTATION)
					
					local cf, size = cross:GetBoundingBox()
					cross:PivotTo(cross:GetPivot() + Vector3.new(0, groundPos.Y - (cf.Position.Y - size.Y / 2), 0))
					cf, size = cross:GetBoundingBox()
					
					tintModel(cross, CRUCIFIX_LIGHT_COLOR)
					
					local center = Instance.new("Part")
					center.Name = "CrossCenter"
					center.Size = Vector3.new(0.3, 0.3, 0.3)
					center.Transparency = 1
					center.Anchored = true
					center.CanCollide = false
					center.CanTouch = false
					center.CanQuery = false
					center.CFrame = cf
					center.Parent = cross
					
					local light = Instance.new("PointLight")
					light.Color = CRUCIFIX_LIGHT_COLOR
					light.Brightness = CRUCIFIX_LIGHT_BRIGHTNESS
					light.Range = CRUCIFIX_LIGHT_RANGE
					light.Shadows = false
					light.Parent = center
					
					local s = math.max(size.X, size.Y) * CRUCIFIX_IMAGE_SIZE
					local gui = Instance.new("BillboardGui")
					gui.Name = "CrossImage"
					gui.Adornee = center
					gui.AlwaysOnTop = true
					gui.LightInfluence = 0
					gui.Size = UDim2.new(s, 0, s, 0)
					gui.Parent = center
					
					local img = Instance.new("ImageLabel")
					img.BackgroundTransparency = 1
					img.AnchorPoint = Vector2.new(0.5, 0.5)
					img.Position = UDim2.new(0.5, 0, 0.5, 0)
					img.Size = UDim2.new(1, 0, 1, 0)
					img.Image = "rbxthumb://type=Asset&id=" .. tostring(CRUCIFIX_IMAGE_ID) .. "&w=420&h=420"
					img.Parent = gui
					
					cross.Parent = Workspace
					
					task.spawn(function()
						local t0 = os.clock()
						while os.clock() - t0 < CRUCIFIX_STAY_TIME and cross.Parent do
							img.Position = UDim2.new(0.5 + (math.random() - 0.5) * 0.4, 0, 0.5 + (math.random() - 0.5) * 0.4, 0)
							img.Rotation = (math.random() - 0.5) * 24
							RunService.Heartbeat:Wait()
						end
						
						if cross.Parent then
							img.Position = UDim2.new(0.5, 0, 0.5, 0)
							local base = cross:GetPivot()
							local depth = size.Y + 1
							local s0 = os.clock()
							while cross.Parent do
								local a = math.clamp((os.clock() - s0) / CRUCIFIX_SINK_TIME, 0, 1)
								local off = Vector3.new(0, -depth * a, 0)
								cross:PivotTo(base + off)
								center.CFrame = cf + off
								img.Position = UDim2.new(0.5 + (math.random() - 0.5) * 0.2, 0, 0.5 + (math.random() - 0.5) * 0.2, 0)
								img.ImageTransparency = a
								light.Brightness = CRUCIFIX_LIGHT_BRIGHTNESS * (1 - a)
								if a >= 1 then break end
								RunService.Heartbeat:Wait()
							end
						end
						if cross.Parent then
							cross:Destroy()
						end
					end)
				end
				
				local function onCrucifixActivated(tool)
					if crucifyBusy or not isRoundActive() then return end
					crucifyBusy = true
					
					playOneShot(CRUCIFIX_SOUND_ID_1, CRUCIFIX_SOUND_VOLUME)
					playOneShot(CRUCIFIX_SOUND_ID_2, CRUCIFIX_SOUND_VOLUME)
					
					spawnCrucifixCross()
					crucifyRound()
					
					if CRUCIFIX_CONSUMED and tool then
						tool:Destroy()
					end
				end
				
				local function playCollectSound()
					local collectSound = Instance.new("Sound")
					collectSound.SoundId = "rbxassetid://97921187742784"
					collectSound.Volume = 3
					collectSound.Parent = SoundService
					collectSound:Play()
					task.delay(2, function()
						if collectSound then collectSound:Destroy() end
					end)
				end
				
				local lastArriveSound = 0
				
				local function awardCoin(coinWorldPos, amount)
					amount = amount or ({5, 10, 20, 50, 100})[math.random(1, 5)]
					local numBits = math.clamp(math.floor(amount * COIN_BITS_PER_GOLD + 0.5), COIN_BITS_MIN, COIN_BITS_MAX)
					
					task.spawn(function()
						local particleGui = Instance.new("ScreenGui")
						particleGui.Name = "R4NS0MCoinBits"
						particleGui.IgnoreGuiInset = true
						particleGui.ResetOnSpawn = false
						particleGui.DisplayOrder = 10
						particleGui.Parent = playerGui
						
						local camera = Workspace.CurrentCamera
						local vector, onScreen = camera:WorldToViewportPoint(coinWorldPos)
						local startX = onScreen and vector.X or (camera.ViewportSize.X / 2)
						local startY = onScreen and vector.Y or (camera.ViewportSize.Y / 2)
						
						local bits = {}
						for b = 1, numBits do
							local size = math.random(COIN_BIT_SIZE_MIN, COIN_BIT_SIZE_MAX)
							local holder = makeCoinBit(particleGui, size)
							holder.Position = UDim2.new(0, startX, 0, startY)
							holder.Rotation = math.random(0, 359)
							
							local ang = math.random() * math.pi * 2
							local dist = COIN_BIT_SCATTER_MIN + math.random() * (COIN_BIT_SCATTER_MAX - COIN_BIT_SCATTER_MIN)
							local peakX = startX + math.cos(ang) * dist
							local peakY = startY + math.sin(ang) * dist
							
							bits[b] = {
								Object = holder,
								StartX = startX,
								StartY = startY,
								PeakX = peakX,
								PeakY = peakY,
								HoverX = peakX,
								HoverY = peakY,
								LeaveAt = COIN_BIT_SCATTER_TIME + COIN_BIT_GATHER_TIME + math.random() * COIN_BIT_STAGGER,
								FlyTime = COIN_BIT_FLY_MIN + math.random() * (COIN_BIT_FLY_MAX - COIN_BIT_FLY_MIN),
								FlyStartT = nil,
								Phase = math.random() * math.pi * 2,
								Spin = (math.random() - 0.5) * 360,
								Bend = (math.random() - 0.5) * 320,
								Done = false
							}
						end
						
						local t = 0
						local remaining = numBits
						local arrived = 0
						local targetX, targetY = startX, startY
						
						while remaining > 0 and t < 20 do
							local dt = RunService.RenderStepped:Wait()
							t += dt
							
							if mainWindow and mainWindow.Parent then
								local c = mainWindow.AbsolutePosition + mainWindow.AbsoluteSize / 2
								targetX, targetY = c.X, c.Y
							end
							
							for _, d in ipairs(bits) do
								if not d.Done then
									local x, y
									
									if t < COIN_BIT_SCATTER_TIME then
										local a = t / COIN_BIT_SCATTER_TIME
										a = 1 - (1 - a) * (1 - a)
										x = d.StartX + (d.PeakX - d.StartX) * a
										y = d.StartY + (d.PeakY - d.StartY) * a
										d.HoverX, d.HoverY = x, y
									elseif t < d.LeaveAt then
										x = d.PeakX + math.sin(t * 7 + d.Phase) * 7
										y = d.PeakY + math.cos(t * 6 + d.Phase) * 7
										d.HoverX, d.HoverY = x, y
									else
										if not d.FlyStartT then
											d.FlyStartT = t
										end
										local a = math.clamp((t - d.FlyStartT) / d.FlyTime, 0, 1)
										local e = a * a
										local p0x, p0y = d.HoverX, d.HoverY
										local dx, dy = targetX - p0x, targetY - p0y
										local len = math.max(1, math.sqrt(dx * dx + dy * dy))
										local cx = (p0x + targetX) / 2 + (-dy / len) * d.Bend
										local cy = (p0y + targetY) / 2 + (dx / len) * d.Bend
										local inv = 1 - e
										x = inv * inv * p0x + 2 * inv * e * cx + e * e * targetX
										y = inv * inv * p0y + 2 * inv * e * cy + e * e * targetY
										
										if a >= 1 then
											d.Done = true
											d.Object:Destroy()
											remaining -= 1
											arrived += 1
											
											if not hasWon and not hasFailed and targetCoins > 0 then
												local part = math.floor(amount * arrived / numBits) - math.floor(amount * (arrived - 1) / numBits)
												targetCoins = math.max(0, targetCoins - part)
											end
											
											if math.random() < COIN_ARRIVE_SOUND_CHANCE and os.clock() - lastArriveSound >= COIN_ARRIVE_SOUND_MIN_GAP then
												lastArriveSound = os.clock()
												playOneShot(COIN_ARRIVE_SOUND_ID, COIN_ARRIVE_SOUND_VOLUME)
											end
										end
									end
									
									if not d.Done then
										d.Object.Position = UDim2.new(0, x, 0, y)
										d.Object.Rotation = d.Object.Rotation + d.Spin * dt
									end
								end
							end
						end
						
						particleGui:Destroy()
					end)
				end
				
				local function explodeHoneypot(pos)
					for _ = 1, HONEYPOT_CUBE_COUNT do
						local cube = Instance.new("Part")
						cube.Name = "HoneyCube"
						local s = 0.4 + math.random() * 0.6
						cube.Size = Vector3.new(s, s, s)
						cube.Color = HONEYPOT_CUBE_COLOR
						cube.Material = Enum.Material.Neon
						cube.Anchored = false
						cube.CanCollide = true
						cube.CanTouch = false
						cube.CanQuery = false
						cube.CFrame = CFrame.new(pos + Vector3.new((math.random() - 0.5) * 1.5, (math.random() - 0.5) * 1.5, (math.random() - 0.5) * 1.5))
							* CFrame.Angles(math.random() * 6, math.random() * 6, math.random() * 6)
						cube.Parent = Workspace
						
						local dir = Vector3.new(math.random() - 0.5, math.random() * 0.8 + 0.2, math.random() - 0.5)
						if dir.Magnitude < 0.01 then
							dir = Vector3.new(0, 1, 0)
						end
						cube.AssemblyLinearVelocity = dir.Unit * (HONEYPOT_EXPLODE_SPEED * (0.4 + math.random() * 0.6))
						cube.AssemblyAngularVelocity = Vector3.new((math.random() - 0.5) * 30, (math.random() - 0.5) * 30, (math.random() - 0.5) * 30)
						
						Debris:AddItem(cube, HONEYPOT_CUBE_LIFETIME)
						task.delay(math.max(0, HONEYPOT_CUBE_LIFETIME - 0.6), function()
							if cube and cube.Parent then
								TweenService:Create(cube, TweenInfo.new(0.5), {Transparency = 1}):Play()
							end
						end)
					end
				end
				
				local function makeThrownHoneypot(template)
					local model = Instance.new("Model")
					model.Name = "R4NS0M_HoneypotThrown"
					
					local clone = template:Clone()
					for _, child in ipairs(clone:GetChildren()) do
						child.Parent = model
					end
					clone:Destroy()
					
					local parts = {}
					for _, d in ipairs(model:GetDescendants()) do
						if d:IsA("BasePart") then
							table.insert(parts, d)
						end
					end
					
					local main = getMainPart(model)
					if not main then
						model:Destroy()
						return nil
					end
					
					for _, p in ipairs(parts) do
						p.Anchored = false
						p.CanTouch = true
						p.CanQuery = true
						p.CanCollide = (p == main)
						p.Massless = (p ~= main)
						if p ~= main then
							local wc = Instance.new("WeldConstraint")
							wc.Part0 = main
							wc.Part1 = p
							wc.Parent = p
						end
					end
					model.PrimaryPart = main
					
					return model, main, parts
				end
				
				local function throwHoneypot(tool)
					if not tool or tool:GetAttribute("Thrown") then return end
					if not honeyToolTemplate then return end
					
					local char = player.Character
					local hrp = char and char:FindFirstChild("HumanoidRootPart")
					local camera = Workspace.CurrentCamera
					if not hrp or not camera then return end
					
					tool:SetAttribute("Thrown", true)
					
					local model, main, parts = makeThrownHoneypot(honeyToolTemplate)
					if not model then
						tool:SetAttribute("Thrown", false)
						return
					end
					
					local dir = (camera.CFrame.LookVector + Vector3.new(0, HONEYPOT_THROW_UP, 0)).Unit
					local startPos = hrp.Position + Vector3.new(0, 1.5, 0) + dir * 3
					
					model.Parent = Workspace
					model:PivotTo(CFrame.new(startPos))
					main.AssemblyLinearVelocity = dir * HONEYPOT_THROW_SPEED
					main.AssemblyAngularVelocity = Vector3.new((math.random() - 0.5) * 12, (math.random() - 0.5) * 12, (math.random() - 0.5) * 12)
					
					tool:Destroy()
					
					local exploded = false
					local function boom()
						if exploded then return end
						exploded = true
						local pos = main.Position
						model:Destroy()
						explodeHoneypot(pos)
						playCollectSound()
						if isRoundActive() then
							awardCoin(pos, HONEYPOT_GOLD)
						end
					end
					
					local t0 = os.clock()
					for _, p in ipairs(parts) do
						p.Touched:Connect(function(hit)
							if exploded or os.clock() - t0 < 0.12 then return end
							if hit:IsDescendantOf(model) then return end
							if char and hit:IsDescendantOf(char) then return end
							if hit.Name == "HoneyCube" or not hit.CanCollide then return end
							boom()
						end)
					end
					
					task.delay(HONEYPOT_MAX_FLIGHT, boom)
				end
				
				local function findGroundPosition(rootPart, character)
					local rayParams = RaycastParams.new()
					rayParams.FilterType = Enum.RaycastFilterType.Exclude
					rayParams.IgnoreWater = true
					rayParams.FilterDescendantsInstances = {character}
					
					local overlapParams = OverlapParams.new()
					overlapParams.FilterType = Enum.RaycastFilterType.Exclude
					overlapParams.FilterDescendantsInstances = {character}
					
					local playerGroundY = rootPart.Position.Y - 3
					
					for _ = 1, 12 do
						local angle = math.random() * math.pi * 2
						local distance = math.random(15, 45)
						local origin = Vector3.new(
							rootPart.Position.X + math.cos(angle) * distance,
							rootPart.Position.Y + 3,
							rootPart.Position.Z + math.sin(angle) * distance
						)
						
						local result = Workspace:Raycast(origin, Vector3.new(0, -30, 0), rayParams)
						
						if result and result.Normal.Y > 0.85 and math.abs(result.Position.Y - playerGroundY) <= 4 then
							local blocked = false
							local nearby = Workspace:GetPartBoundsInRadius(result.Position + Vector3.new(0, 1.6, 0), 1.1, overlapParams)
							for _, p in ipairs(nearby) do
								if p.CanCollide then
									blocked = true
									break
								end
							end
							if not blocked then
								return result.Position
							end
						end
					end
					
					return nil
				end
				
				local function placeModelOnGround(obj, groundPos)
					obj:PivotTo(CFrame.new(groundPos) * COIN_ROTATION)
					local bottomY
					if obj:IsA("Model") then
						local cf, size = obj:GetBoundingBox()
						bottomY = cf.Position.Y - size.Y / 2
					else
						bottomY = obj.Position.Y - obj.Size.Y / 2
					end
					obj:PivotTo(obj:GetPivot() + Vector3.
