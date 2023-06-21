
--combine: InitialPoses, parts+motor6Ds, bone hierarchy (under rootpart), deleted uneeded InitialPoses

--2023 note: meant to be copy-pasted to run in command-line. that's all

local rig_name = "YYB Hatsune Miku_10th" --[[ ENTER YOUR RIG NAME HERE! ]]

local rig = workspace:WaitForChild(rig_name)

local body = rig.body
local hair = rig.hair

local rigindex = {}

rigindex.body = {Children = {}}
rigindex.hair = {Children = {}}

function indexiterator(bone, parent)
	parent.Children[bone.Name] = {Object = bone, Children = {}}
	
	for i,v in pairs(bone:GetChildren()) do
		indexiterator(v, parent.Children[bone.Name])
	end
end

indexiterator(body.RootPart["全ての親"], rigindex.body) --[[uses MMD standard root bones]]
indexiterator(hair.RootPart["全ての親"], rigindex.hair)

function compareiterator(bodybone, hairbone)
	for i,v in pairs(hairbone.Children) do
		if bodybone.Children[i] then
			compareiterator(bodybone.Children[i], v)
		else
			v.Object.Parent = bodybone.Object
		end
	end
end

compareiterator(rigindex.body, rigindex.hair)

--[[2023 note: InitialPoses and motor6D's are unneeded for skinned meshes (bones are the target). You caaannn include this if you'd like. It won't do anything.

--for i,v in pairs(hair.InitialPoses:GetChildren()) do
--	if not body.InitialPoses:FindFirstChild(v.Name) then
--		print('moved', v)
--		v.Parent = body.InitialPoses
--	end
--end

--for i,v in pairs(hair:GetChildren()) do
--	if v:IsA("BasePart") and v.Name ~= "RootPart" then
--		local motor6D = nil
--		for ii,vv in pairs(v:GetChildren()) do
--			if vv:IsA("Motor6D") then
--				motor6D = vv
--			end
--		end
		
--		local c0 = motor6D.C0
--		local c1 = motor6D.C1
		
--		v.Parent = body
		
--		motor6D.Part0 = body.RootPart
--		motor6D.Part1 = v
		
--		motor6D.C0 = c0
--		motor6D.C1 = c1
--	end
--end]]

local names = {}

for i,v in pairs(workspace["YYB Hatsune Miku_10th"]:GetChildren()) do
	if v:IsA("BasePart") then
		names[v.Name] = true
		for ii,vv in pairs(v:GetDescendants()) do
			if vv:IsA("Bone") or vv:IsA("Motor6D") then
				names[vv.Name] = true
			end
		end
	end
end

local match = string.match

for i,v in pairs(rig.InitialPoses:GetChildren()) do
	local name = match(v.Name, "(.+)_Composited") or match(v.Name, "(.+)_Initial") or match(v.Name, "(.+)_Original")
	if name then
		if not names[name] then
			v:Destroy()
		end
	end
end

return
