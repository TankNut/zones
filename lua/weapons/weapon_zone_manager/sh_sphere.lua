AddCSLuaFile()

function SWEP:BuildSphere(tr)
	local pos = tr.HitPos
	local active = self:GetActive()

	if not active or self:GetOwner():KeyDown(IN_USE) then
		if not active then
			self:SetRadius(10)
		end

		self:SetActive(true)
		self:SetZonePos(pos)

		return
	end

	local dist = pos:Distance(self:GetZonePos())

	if dist == 0 then
		return
	end

	self:SetRadius(dist)
end

function SWEP:ValidateSphere(data)
	if not isvector(data.Pos) or not isnumber(data.Radius) then
		return false
	end

	if data.Radius < 1 then
		return false
	end

	return true
end

if CLIENT then
	local color = Color(255, 0, 0, 25)

	function SWEP:DrawSphere()
		render.SetColorMaterial()

		local pos = self:GetZonePos()
		local radius = self:GetRadius()

		if EyePos():DistToSqr(pos) <= radius * radius then
			render.DrawSphere(pos, -radius, 20, 20, color)
		else
			render.DrawSphere(pos, radius, 20, 20, color)
		end

		render.DrawWireframeSphere(pos, radius, 20, 20, color_white, true)
	end

	function SWEP:PopulateSphereMenu(props, updateFunction)
		local pos = self:GetZonePos()
		local posProp = props:CreateRow("Shape", "Position")

		posProp:Setup("Generic", {waitforenter = true})
		posProp.DataChanged = function(_, val)
			val = Vector(val)

			self:SetZonePos(val)
			updateFunction("Pos", val)
		end

		updateFunction("Pos", pos)
		posProp:SetValue(pos)

		local radius = self:GetRadius()
		local radiusProp = props:CreateRow("Shape", "Radius")

		radiusProp:Setup("Float", {min = 1, max = 56756})
		radiusProp.DataChanged = function(_, val)
			val = tonumber(val)

			self:SetRadius(val)
			updateFunction("Radius", val)
		end

		updateFunction("Radius", radius)
		radiusProp:SetValue(radius)
	end
end
