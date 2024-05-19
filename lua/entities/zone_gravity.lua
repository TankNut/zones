AddCSLuaFile()
DEFINE_BASECLASS("base_zone")

ENT.Base = "base_zone"

ENT.PrintName = "Gravity Multiplier"

ENT.Color = Color(127, 63, 111, 50)

function ENT:SetupDataTables()
	BaseClass.SetupDataTables(self)

	self:NetworkVar("Float", "Multiplier", {
		KeyName = "multiplier",
		Edit = {
			type = "Float",
			order = 1,
			min = -2,
			max = 2
		}
	})
end

function ENT:GetZoneID()
	return self:GetClass() .. self:GetMultiplier()
end

function ENT:StaticFilter(ent)
	return ent:IsPlayer()
end

function ENT:OnEnter(ent, transition)
	if not transition then
		ent:SetGravity(self:GetMultiplier())
	end
end

function ENT:OnExit(ent, transition, removing)
	if not transition then
		ent:SetGravity(0)
	end
end

if SERVER then
	function ENT:SaveCustomData()
		return {
			Multiplier = self:GetMultiplier()
		}
	end

	function ENT:LoadCustomData(data)
		self:SetMultiplier(self:GetMultiplier())
	end
end
