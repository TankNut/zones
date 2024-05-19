AddCSLuaFile()
DEFINE_BASECLASS("base_zone")

ENT.Base = "base_zone"

ENT.PrintName = "Invulnerability"

ENT.Color = Color(0, 161, 255, 50)
ENT.HaloColor = Color(0, 161, 255)

function ENT:Initialize()
	BaseClass.Initialize(self)

	if CLIENT then
		hook.Add("PreDrawHalos", self, function(zone)
			zone:SetupHalos()
		end)
	else
		hook.Add("EntityTakeDamage", self, function(zone, ent, dmg)
			return zone:EntityTakeDamage(ent, dmg)
		end)
	end
end

function ENT:StaticFilter(ent)
	return ent:IsPlayer()
end

if CLIENT then
	function ENT:SetupHalos()
		local entities = self:GetEntities()
		local activeWeapons = {}

		for _, ply in pairs(entities) do
			local weapon = ply:GetActiveWeapon()

			if IsValid(weapon) then
				table.insert(activeWeapons, weapon)
			end
		end

		table.Add(entities, activeWeapons)
		halo.Add(entities, self.HaloColor, 2, 2, 2, true)
	end
else
	function ENT:EntityTakeDamage(ent, dmg)
		return self:ContainsEntity(ent) or self:ContainsEntity(dmg:GetAttacker())
	end
end
