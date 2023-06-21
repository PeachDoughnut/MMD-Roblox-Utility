
--2023 note: quick example of code to run an animation. Does nothing else. Made for this. Ad hoc.

local preload_service = game:GetService("ContentProvider")
local tween_service = game:GetService("TweenService")
local input_service = game:GetService("UserInputService")
local run_service = game:GetService("RunService")

local players = game:GetService("Players")
local player = players.LocalPlayer

local playergui = player:WaitForChild("PlayerGui")

local orientation_limit = 0

run_service:BindToRenderStep("screen_orientation", Enum.RenderPriority.Last.Value-0, function()
	playergui.ScreenOrientation = Enum.ScreenOrientation.Sensor
	orientation_limit = orientation_limit + 1
	if orientation_limit > 600 then
		run_service:UnbindFromRenderStep("screen_orientation")
		warn("disconnected screen_orientation")
	end
end)

local loading_gui = script:WaitForChild("LoadingGui")
loading_gui.Parent = playergui

local loading_frame = loading_gui:WaitForChild("LoadingFrame")
local loading_text = loading_frame:WaitForChild("LoadingText")

local blur = game:GetService("Lighting"):WaitForChild("Blur")
blur.Size = 32
blur.Enabled = true

local miku_yyb = {
	["body"] = workspace:WaitForChild("YYB Hatsune Miku_10th"):WaitForChild("body"), 
	["hair"] = workspace:WaitForChild("YYB Hatsune Miku_10th"):WaitForChild("hair")
}

function load_asset(asset, message)
	loading_text.Text = message

	print("loading begun", message)
	
	local tries = 0
	
	function begin_loading()
		preload_service:PreloadAsync(asset, function(id, status)
			if not status == Enum.AssetFetchStatus.Success and tries < 10 then
				tries = tries + 1
				
				warn("loading failed", status, id)
				
				wait(tries*2)
				
				loading_text.Text = message.." Failed. Retrying ("..tries..")..."
				
				begin_loading()
			elseif tries >= 10 then
				warn("loading failed")
			end
		end)
	end
	
	begin_loading()

	print("loading finish")
end

load_asset({miku_yyb.body, miku_yyb.hair}, "Please wait...\nLoading YYB Miku_10th...")

local upper_body = 
	miku_yyb.body:WaitForChild("RootPart"):WaitForChild("全ての親"):WaitForChild("センター")
	:WaitForChild("グルーブ"):WaitForChild("腰"):WaitForChild("上半身"):WaitForChild("上半身2")

local head = upper_body:WaitForChild("首"):WaitForChild("頭")
local eye_L = head:WaitForChild("目.L")
local eye_R = head:WaitForChild("目.R")

local track_part = Instance.new("Part")--lazy, instead of making my own camera system
track_part.Transparency = 1
track_part.Anchored = true
track_part.CanCollide = false
track_part.CFrame = upper_body.TransformedWorldCFrame
track_part.Parent = workspace

local eye_L_part = Instance.new("Part")--lazyier
eye_L_part.Transparency = 1
eye_L_part.Anchored = true
eye_L_part.CanCollide = false
eye_L_part.CFrame = eye_L.TransformedWorldCFrame * CFrame.new(0,8,0)
eye_L_part.Parent = workspace
local light_L = script:WaitForChild("EyeLight"):Clone()
light_L.Parent = eye_L_part

local eye_R_part = Instance.new("Part")--lazyier
eye_R_part.Transparency = 1
eye_R_part.Anchored = true
eye_R_part.CanCollide = false
eye_R_part.CFrame = eye_R.TransformedWorldCFrame * CFrame.new(0,8,0)
eye_R_part.Parent = workspace
local light_R = script:WaitForChild("EyeLight"):Clone()
light_R.Parent = eye_R_part

local cam = workspace.CurrentCamera

cam.CameraType = Enum.CameraType.Track
cam.CameraSubject = track_part

local hibana_anim_ids_24fps = { --total: 1266 MB, compressed total: 413 MB
	["body"] = {
		["hibana1"] = 6797524484,--6659669200,
		["hibana2"] = 6797527635,--6659682981,
		["hibana3"] = 6797530108,--6659690990,
		["hibana4"] = 6797532926,--6659705490,
		["hibana5"] = 6797535739,--6659730604,
		["hibana6"] = 6797538282,--6659740018,
		["hibana7"] = 6797540733--6659748284,
	},
	["hair"] = {
		["hibana1"] = 6797725033,--6659757251,
		["hibana2"] = 6797727217,--6659765319,
		["hibana3"] = 6797729342,--6659774329,
		["hibana4"] = 6797731531,--6659782645,
		["hibana5"] = 6797733959,--6659789868,
		["hibana6"] = 6797736033,--6659796904,
		["hibana7"] = 6797738030--6659804385
	}
}

local hibana_anim_ids_12fps = { --total: 622 MB, compressed total: 206 MB
	["body"] = {
		["hibana1"] = 6797930876,--6793025453,
		["hibana2"] = 6797933491,--6793032196,
		["hibana3"] = 6797935829,--6793039491,
		["hibana4"] = 6797937411--6793043682
	},
	["hair"] = {
		["hibana1"] = 6798057976,--6793193991,
		["hibana2"] = 6798060056,--6793201565,
		["hibana3"] = 6798063894,--6793210085,
		["hibana4"] = 6798065937--6793215162
	}
}

local hibana_settings = {
	["Animation"] = hibana_anim_ids_24fps,
	["Amount"] = 7,
	["Speed"] = 1,
	["Cutoff"] = 639/24--seconds left at last segment (actual frames left/24fps)
}

local mobile_enabled = (input_service.AccelerometerEnabled or input_service.GyroscopeEnabled) or not input_service.KeyboardEnabled

if mobile_enabled then
	hibana_settings = {
		["Animation"] = hibana_anim_ids_12fps,
		["Amount"] = 4,
		["Speed"] = 0.5,
		["Cutoff"] = 320/24
	}
end

local hibana_anim_tracks = {}
local hibana_anims = {}

local hibana_music = script:WaitForChild("hibana")

local loading_tracker = 0

for name,mesh in pairs (miku_yyb) do
	local animation_tracks = {}
	local anims = {}
	
	for anim_name,id in pairs (hibana_settings.Animation[name]) do
		local animation = Instance.new("Animation")
		animation.AnimationId = "http://www.roblox.com/asset/?id="..id
		
		anims[anim_name] = animation
		
		loading_tracker = loading_tracker + 1
		
		load_asset({animation}, "Please wait...\nLoading Animation Data ("..loading_tracker.."/"..(hibana_settings.Amount * 2)..")...")
		
		local animator = mesh:WaitForChild("AnimationController"):WaitForChild("Animator")
		local animation_track = animator:LoadAnimation(animation)
		
		animation_tracks[anim_name] = animation_track
		
		wait()
	end
	
	hibana_anims[name] = anims
	hibana_anim_tracks[name] = animation_tracks
end

load_asset({hibana_music}, "Please wait...\nLoading Music...")

load_asset({miku_yyb.body, miku_yyb.hair}, "Please wait...\nLoading YYB Miku_10th...")

loading_text.Text = "Enjoy!!!"

local loading_begone_tween = tween_service:Create(loading_frame, TweenInfo.new(5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundTransparency = 1})
local loading_begone_tween_2 = tween_service:Create(loading_text, TweenInfo.new(2.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0.25,0,1,0)})

local blur_tween = tween_service:Create(blur, TweenInfo.new(5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = 3})

loading_begone_tween:Play()
loading_begone_tween_2:Play()
blur_tween:Play()

wait()

if mobile_enabled then
	wait(0.5)--sometimes anims dont load, give extra time...
end

local eyes = {head:WaitForChild("目.L"), head:WaitForChild("目.R")}

local eye_clamp_x = Vector2.new(-0.0325, 0.0325)--min, max
local eye_clamp_y = Vector2.new(-0.017, 0.024)

local atan2 = math.atan2
local clamp = math.clamp

for name,tracks in pairs(hibana_anim_tracks) do
	local track_count = 0
	local cur_track = nil
	
	run_service:BindToRenderStep(name.."_animation", Enum.RenderPriority.First.Value-0, function()
		track_part.CFrame = upper_body.TransformedWorldCFrame
		eye_L_part.CFrame = eye_L.TransformedWorldCFrame * CFrame.new(0,8,0)
		eye_R_part.CFrame = eye_R.TransformedWorldCFrame * CFrame.new(0,8,0)
		
		local eyes_pos = -(head.TransformedWorldCFrame:Inverse() * cam.CFrame).Position
		
		local eyes_angle_x = atan2(eyes_pos.X, eyes_pos.Z) * -0.11--really sensitive multipliers
		local eyes_angle_y = atan2(eyes_pos.Y, eyes_pos.Z) * -0.08--too high and she looks tsundere
				
		eyes_angle_x = clamp(eyes_angle_x, eye_clamp_x.X, eye_clamp_x.Y)
		eyes_angle_y = clamp(eyes_angle_y, eye_clamp_y.X, eye_clamp_y.Y)
		
		for _, eye in pairs(eyes) do
			--if eyes_angle_x > eye_angle_clamp_x.X and eyes_angle_x < eye_angle_clamp_x.Y and eyes_angle_y > eye_angle_clamp_y.X and eyes_angle_y < eye_angle_clamp_y.Y then
				--print("LOOK")
				eye.Transform = eye.Transform * CFrame.Angles(eyes_angle_x, 0, eyes_angle_y)
			--end
		end
		
		if not cur_track or not cur_track.IsPlaying or (track_count >= hibana_settings.Amount and cur_track.TimePosition > hibana_settings.Cutoff) then
			-- sadly, does not offload asset memory...
			
			--if cur_track then
			--	local cur_name = "hibana"..track_count
			--	cur_track:Destroy()
			--	hibana_anims[name][cur_name]:Destroy()
				
			--	warn('deleted: '..cur_name, name)
			--end
			
			track_count = track_count < hibana_settings.Amount and (track_count + 1) or 1
			
			if track_count == 1 then
				if cur_track then cur_track:Stop(0.2) end
				
				hibana_music.TimePosition = 0
				hibana_music:Play()
			end
			
			local track_name = "hibana"..track_count
			local track = tracks[track_name]
			
			cur_track = track

			if track then
				print("Playing: "..track_name, name)
				track:Play(0.1, 1, hibana_settings.Speed)
			end
		end
	end)
end


