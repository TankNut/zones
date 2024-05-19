AddCSLuaFile()

local cardinals = {
	Vector(1, 0, 0),
	Vector(0, 1, 0),
	Vector(0, 0, 1)
}

function SWEP:BuildBox(tr)
	local pos = tr.HitPos

	if not self:GetActive() then
		self:SetActive(true)

		self:SetMins(pos)
		self:SetMaxs(pos)

		return
	end

	local mins = self:GetMins()
	local maxs = self:GetMaxs()
	local ply = self:GetOwner()

	if ply:KeyDown(IN_USE) then
		local normal = tr.HitNormal
		local index, winner = 0, 0

		for k, direction in pairs(cardinals) do
			local value = math.abs(normal:Dot(direction))

			if value > winner then
				index = k
				winner = value
			end
		end

		local direction = cardinals[index]
		local center = LerpVector(0.5, mins, maxs)
		local diff = (pos - center) * direction

		pos = center + diff
	end

	mins.x = math.min(mins.x, pos.x)
	mins.y = math.min(mins.y, pos.y)
	mins.z = math.min(mins.z, pos.z)

	maxs.x = math.max(maxs.x, pos.x)
	maxs.y = math.max(maxs.y, pos.y)
	maxs.z = math.max(maxs.z, pos.z)

	self:SetMins(mins)
	self:SetMaxs(maxs)
end

function SWEP:ValidateBox(data)
	if not isvector(data.Mins) or not isvector(data.Maxs) then
		return false
	end

	return true
end

if CLIENT then
	local color = Color(255, 0, 0, 25)

	function SWEP:DrawBox()
		render.SetColorMaterial()

		local mins, maxs = self:GetMins(), self:GetMaxs()

		if EyePos():WithinAABox(mins, maxs) then
			render.DrawBox(vector_origin, angle_zero, maxs, mins, color)
		else
			render.DrawBox(vector_origin, angle_zero, mins, maxs, color)
		end

		render.DrawWireframeBox(vector_origin, angle_zero, mins, maxs, color_white, true)
	end

	function SWEP:PopulateBoxMenu(props, updateFunction)
		local mins = self:GetMins()
		local minsProp = props:CreateRow("Shape", "Mins")

		minsProp:Setup("Generic", {waitforenter = true})
		minsProp.DataChanged = function(_, val)
			val = Vector(val)

			self:SetMins(val)
			updateFunction("Mins", val)
		end

		updateFunction("Mins", mins)
		minsProp:SetValue(mins)

		local maxs = self:GetMaxs()
		local maxsProp = props:CreateRow("Shape", "Maxs")

		maxsProp:Setup("Generic", {waitforenter = true})
		maxsProp.DataChanged = function(_, val)
			val = Vector(val)

			self:SetMaxs(val)
			updateFunction("Maxs", val)
		end

		updateFunction("Maxs", maxs)
		maxsProp:SetValue(maxs)
	end
end
