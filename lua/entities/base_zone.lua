AddCSLuaFile()

ENT.Base = "base_point"
ENT.Type = "point"

ENT.Author = "TankNut"

ENT.Realm = zones.REALM_SHARED
ENT.Color = Color(255, 0, 0, 50)

function ENT:Initialize()
	self.EntityCache = {}

	if SERVER then
		self:PatchEditValue()
	end
end

function ENT:SetupDataTables()
	self:NetworkVar("Int", "Shape")
	self:NetworkVar("Bool", "Saved")
	self:NetworkVar("Entity", "Creator")

	-- Box shape
	self:NetworkVar("Vector", "Mins")
	self:NetworkVar("Vector", "Maxs")

	-- Sphere shape
	self:NetworkVar("Float", "Radius")

	-- Plane shape
	self:NetworkVar("Float", "Distance")
end

function ENT:OnEnter(ent, transition)
end

function ENT:OnExit(ent, transition, removing)
end

-- Gets checked once per entity
function ENT:StaticFilter(ent)
	return false
end

-- Gets checked every update
function ENT:DynamicFilter(ent)
	return true
end

-- Used to decide which zones overlap and which ones don't
function ENT:GetZoneID()
	return self:GetClass()
end

-- Used to switch between zones with identical ID's
function ENT:GetZonePriority()
	return self:EntIndex()
end

function ENT:GetEntities()
	return table.GetKeys(self.EntityCache)
end

function ENT:ContainsEntity(ent)
	return tobool(self.EntityCache[ent])
end

local function inRange(x, min, max)
	return x >= min and x <= max
end

function ENT:Contains(pos)
	local shape = self:GetShape()

	if shape == zones.SHAPE_BOX then
		local mins, maxs = self:GetMins(), self:GetMaxs()

		return inRange(pos.x, mins.x, maxs.x)
			and inRange(pos.y, mins.y, maxs.y)
			and inRange(pos.z, mins.z, maxs.z)
	elseif shape == zones.SHAPE_SPHERE then
		local radius = self:GetRadius()

		return self:GetPos():DistToSqr(pos) <= (radius * radius)
	elseif shape == zones.SHAPE_PLANE then
		local distance = self:GetDistance()
		local normal = self:GetAngles():Forward()

		return (normal:Dot(pos) - distance) <= 0
	end

	return false
end

if CLIENT then
	function ENT:ContainsEye()
		return self:Contains(EyePos())
	end

	function ENT:DrawZone()
	end

	function ENT:DrawShape(color)
		local shape = self:GetShape()

		if shape == zones.SHAPE_BOX then
			if self:ContainsEye() then
				render.DrawBox(vector_origin, angle_zero, self:GetMaxs(), self:GetMins(), color)
			else
				render.DrawBox(vector_origin, angle_zero, self:GetMins(), self:GetMaxs(), color)
			end
		elseif shape == zones.SHAPE_SPHERE then
			if self:ContainsEye() then
				render.DrawSphere(self:GetPos(), -self:GetRadius(), 20, 20, color)
			else
				render.DrawSphere(self:GetPos(), self:GetRadius(), 20, 20, color)
			end
		elseif shape == zones.SHAPE_PLANE then
			if self:ContainsEye() then
				render.DrawQuadEasy(self:GetPos(), -self:GetAngles():Forward(), 56756, 56756, color)
			else
				render.DrawQuadEasy(self:GetPos(), self:GetAngles():Forward(), 56756, 56756, color)
			end
		end
	end

	local wireframe = Material("debug/debugwireframe")
	local arrow = Material("widgets/arrow.png", "nocull alphatest smooth mips")

	function ENT:DrawZoneDebug()
		render.SetColorMaterial()

		self:DrawShape(self.Color)

		local shape = self:GetShape()

		if shape == zones.SHAPE_BOX then
			render.DrawWireframeBox(vector_origin, angle_zero, self:GetMins(), self:GetMaxs(), color_white, true)
		elseif shape == zones.SHAPE_SPHERE then
			render.DrawWireframeSphere(self:GetPos(), self:GetRadius(), 20, 20, color_white, true)
		elseif shape == zones.SHAPE_PLANE then
			local pos = self:GetPos()
			local normal = self:GetAngles():Forward()

			render.SetMaterial(arrow)
			render.DrawBeam(pos, pos + normal * 200, 40, 1, 0, color_white)

			if self:ContainsEye() then
				normal = -normal
			end

			render.SetMaterial(wireframe)

			render.DrawQuadEasy(pos, normal, 56756, 56756, color_white)
			render.DrawQuadEasy(pos, normal, 56756, 56756, color_white, 90)
		end
	end
else
	function ENT:UpdateTransmitState()
		return TRANSMIT_ALWAYS
	end

	function ENT:SaveCustomData()
		return {}
	end

	function ENT:LoadCustomData(data)
	end

	function ENT:PatchEditValue()
		local old = self.EditValue

		self.EditValue = function(...)
			old(...)

			if self.Loading then
				return
			end

			if self:GetSaved() then
				zones.Save()
			end
		end
	end
end
