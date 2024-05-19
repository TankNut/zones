AddCSLuaFile()

local cardinals = {
	Vector(-1, 0, 0),
	Vector(1, 0, 0),
	Vector(0, -1, 0),
	Vector(0, 1, 0),
	Vector(0, 0, -1),
	Vector(0, 0, 1)
}

function SWEP:BuildPlane(tr)
	local ply = self:GetOwner()
	local normal = ply:GetAimVector()

	if ply:KeyDown(IN_USE) then
		local index, winner = 0, 0

		for k, direction in pairs(cardinals) do
			local value = normal:Dot(direction)

			if value > winner then
				index = k
				winner = value
			end
		end

		normal = cardinals[index]
	end

	self:SetActive(true)
	self:SetZonePos(ply:EyePos())
	self:SetNormal(normal)
end

function SWEP:ValidatePlane(data)
	if not isvector(data.Pos) or not isangle(data.Angle) then
		return false
	end

	return true
end

if CLIENT then
	local color = Color(255, 0, 0, 25)

	local arrow = Material("widgets/arrow.png", "nocull alphatest smooth mips")
	local wireframe = Material("debug/debugwireframe")

	function SWEP:DrawPlane()
		local pos = self:GetZonePos()
		local normal = self:GetNormal()

		render.SetMaterial(arrow)
		render.DrawBeam(pos, pos + normal * 100, 20, 1, 0, color_white)

		render.SetMaterial(wireframe)
		render.DrawQuadEasy(pos, normal, 100, 100, color_white)
		render.DrawQuadEasy(pos, -normal, 100, 100, color_white)

		render.SetColorMaterial()

		render.DrawQuadEasy(pos, normal, 56756, 56756, color)
		render.DrawQuadEasy(pos, -normal, 56756, 56756, color)
	end

	function SWEP:PopulatePlaneMenu(props, updateFunction)
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

		local angle = self:GetNormal():Angle()
		local angleProp = props:CreateRow("Shape", "Angle")

		angleProp:Setup("Generic", {waitforenter = true})
		angleProp.DataChanged = function(_, val)
			val = Angle(val)

			self:SetNormal(val:Forward())
			updateFunction("Angle", val)
		end

		updateFunction("Angle", angle)
		angleProp:SetValue(angle)
	end
end
