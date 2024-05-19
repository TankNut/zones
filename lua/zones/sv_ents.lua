function zones.Create(class, shape, ...)
	assert(zones.IsZone(class))

	if shape == zones.SHAPE_BOX then
		return zones.CreateBox(class, ...)
	elseif shape == zones.SHAPE_SPHERE then
		return zones.CreateSphere(class, ...)
	elseif shape == zones.SHAPE_PLANE then
		return zones.CreatePlane(class, ...)
	else
		error("Unknown zone shape")
	end
end

function zones.CreateBox(class, mins, maxs)
	local center = LerpVector(0.5, mins, maxs)
	local ent = ents.Create(class)

	ent:SetPos(center)
	ent:SetAngles(angle_zero)

	ent:SetShape(zones.SHAPE_BOX)
	ent:SetMins(mins)
	ent:SetMaxs(maxs)

	ent:Spawn()
	ent:Activate()

	return ent
end

function zones.CreateSphere(class, pos, radius)
	local ent = ents.Create(class)

	ent:SetPos(pos)
	ent:SetAngles(angle_zero)

	ent:SetShape(zones.SHAPE_SPHERE)
	ent:SetRadius(radius)

	ent:Spawn()
	ent:Activate()

	return ent
end

function zones.CreatePlane(class, pos, normal)
	local distance = pos:Dot(normal)
	local ent = ents.Create(class)

	ent:SetPos(pos)
	ent:SetAngles(normal:Angle())

	ent:SetShape(zones.SHAPE_PLANE)
	ent:SetDistance(distance)

	ent:Spawn()
	ent:Activate()

	return ent
end
