
--TODO:
--(Y) cutoff keyframes
--(Y) split keyframes to 30 sec
--(Y) remove unneeded poses (anything that is not RootPart)
--(Y) transformation rescaling (reduce reliance on external plugins)
--(N) remove poses with little to no movement between keyframes							(2023 note: difficult to determine whether an empty pose for the purposes of a finger, say...are needed)
--(N) match non-linear pose interpolation methods with removed movement for extreme optimization quality	(2023 note: over-optimization)

--[[ command line:
--(REMINDER: module returns in-studio are cached, restart after changing variables!)

local fps24 = 4959
local fps12 = 2480
local fps6 = 1241

local rig = workspace["YYB Hatsune Miku_10th"].body	--[[select your rig here, before running in command-line]]
local animation = rig.AnimSaves["Test"]			--[[select your animation (KeyframeSequence) to compress]]
local cutoff = fps24					--[[set this to the total number of frames in your anmiaton...in this case, I have 3 variables for my own ease of use working with a couple animations. Just enter the number.]]

require(game.ServerStorage.KeyframeSequence_Compressor)(animation, cutoff, rig)

]]--GitHub does not parse Lua correctly, apparently. This is the end of the comment beginning on line 10. Does work this way... Disappointing. Lines 17-19 should stay in their own comment scopes.

function split_keyframes(keyframe_seq, frame_cutoff, rig)
	warn('version 1.0.5C')
	
	local ceil = math.ceil
	local floor = math.floor
	
	local function round(n)
		local nfloor = floor(n)
		if (n - nfloor) < 0.5 then
			return nfloor
		else
			return ceil(n)
		end
	end
	
	local tracker_pause = 100 --wait every amount of frames so it doesnt hang
	local tracker_count = 0
	
	local function track_frame(i, max)
		tracker_count = tracker_count + 1

		if tracker_count > tracker_pause then
			tracker_count = 0
			wait()
			print(i.."/"..max.." frames completed")
		end
	end
	
	
	local frame_amount = 6199 --all uploads have this total amount, for some reason..

	local frame_rate = 24 --all uploads have this, lower fps versions are just slowed down
	local frame_max = 600*frame_rate--30*frame_rate --30 second limit (larger anims still give an HTTP 413 error)
	
	local transformation_scale = rig.PrimaryPart and rig.PrimaryPart.Size.Z or 1
	
	local indexed_keyframes = {}
	
	for i, keyframe in pairs(keyframe_seq:GetChildren()) do
		track_frame(i, frame_amount)
		
		local frame = round(keyframe.Time*frame_rate)
		
		if frame <= frame_cutoff then
			--clean up unneeded poses first for performance
			for _, pose in pairs(keyframe:GetChildren()) do
				if pose.Name ~= "RootPart" then
					pose:Destroy()
				end
			end
			local rootpart = keyframe:WaitForChild("RootPart")
			if rootpart then
				for _, subpose in pairs(rootpart:GetChildren()) do
					if subpose.Name ~= "全ての親" then
						subpose:Destroy()
					end
				end
				for _, subpose in pairs(rootpart:GetDescendants()) do
					local x, y, z, 
						m11, m12, m13, 
						m21, m22, m23, 
						m31, m32, m33 = subpose.CFrame:components()
					
					x, y, z = x * transformation_scale, y * transformation_scale, z * transformation_scale
					
					subpose.CFrame = CFrame.new(
						x, y, z,
						m11, m12, m13,
						m21, m22, m23,
						m31, m32, m33
					)
				end
			end
			indexed_keyframes[frame] = keyframe
		end
	end
	
	warn("indexing "..(#indexed_keyframes).." keyframes complete")
	
	local splits = ceil((frame_cutoff + 1)/frame_max) -- +1 for frame 0
	
	for i=1, splits, 1 do
		local new_sequence = Instance.new("KeyframeSequence")
		new_sequence.Name = keyframe_seq.Name.."_"..i
		new_sequence.Loop = false
		new_sequence.Priority = Enum.AnimationPriority.Action
		
		warn("generating keyframe sequence "..i)
		
		for frame=0, frame_max, 1 do
			track_frame(frame, frame_max)
			
			local offset = (i-1) * frame_max
			
			local keyframe = indexed_keyframes[frame + offset]
			if keyframe then
				local newkeyframe = keyframe:Clone()
				newkeyframe.Time = newkeyframe.Time - offset/frame_rate
				newkeyframe.Parent = new_sequence
			end
		end
		
		new_sequence.Parent = keyframe_seq.Parent
	end
	
	wait()
	
	keyframe_seq:Destroy()
	
	warn("complete")
end

return split_keyframes
