CreateConVar( "sv_adv_health_tool_nodmgforce", 1, bit.bor( FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED ), "Nullified damage will also lose its force.", 0, 1 )


duplicator.RegisterEntityModifier( "adv_health_tool", AHT_ApplySettings )

util.AddNetworkString( "adv_health_tool_net" )


hook.Add( "EntityTakeDamage", "aht_damage_filtering", function( target, dmginfo )

	if not target.aht_damage_filtered then return end

	if ( target.aht_immune_mask and dmginfo:IsDamageType( target.aht_immune_mask ) ) then

		dmginfo:SetDamage( 0 )

		local nodmgforce = GetConVar( "sv_adv_health_tool_nodmgforce" )
		if nodmgforce and nodmgforce:GetBool() then
			dmginfo:SetDamageType( DMG_PREVENT_PHYSICS_FORCE )
			dmginfo:SetDamageForce( vector_origin )
		end

	end
end )


local function applyNRemember( ent, newval, setter, getter, orig_key )
	if not ( newval and isfunction( setter ) ) then return false end
	local o = ent[ orig_key ] or getter( ent )
	ent[ orig_key ] = o ~= newval and o or nil
	setter( ent, newval )
	return true
end


function AHT_ApplySettings( ply, ent, data, do_undo, undo_text )

	local k1, k2, k3 = "unbreakable", "immune_mask", "m_takedamage"

	local legacyUnbreak = ent.EntityMods and ent.EntityMods.Unbreakable
	if legacyUnbreak then
		if data.getLegacy then
			data[k1] = data[k1] or legacyUnbreak and legfacyUnbreak.On
		else
			if legacyUnbreak then ent.EntityMods.Unbreakable.On = data[k1] end
		end
		data.getLegacy = nil
	end

	local oldData
	if do_undo ~= false then -- if SERVER and do_undo ~= false
		oldData = AHT_CopySettings( ent )
		do_undo = false
		for k, v in pairs( data ) do
			if v ~= oldData[k] then do_undo = true end
		end
	end

	applyNRemember( ent, data.health, ent.SetHealth, ent.Health, "aht_orig_health" )
	applyNRemember( ent, data.max_health, ent.SetMaxHealth, ent.GetMaxHealth, "aht_orig_max_health" )
	ent["aht_" .. k1] = data[k1] or nil
	ent["aht_" .. k2] = data[k2] ~= 0 and data[k2] or nil
	ent.aht_damage_filtered = data[k1] or data[k2] ~= 0 or nil
	-- m_takedamage info here: https://developer.valvesoftware.com/wiki/CBaseEntity
	local nodmgforce = GetConVar( "sv_adv_health_tool_nodmgforce" )
	local m_takedamage = data[k1] and ( nodmgforce and not nodmgforce:GetBool() and 1 or 0 ) or ent["aht_orig_" .. k3]
	applyNRemember( ent, m_takedamage, function( e, v ) e:SetSaveValue( k3, v ) end, function( e ) return e:GetInternalVariable( k3 ) end, "aht_orig_" .. k3 )

	--if SERVER then
	data.getLegacy = true -- for (one-way) compability with the other addon
	duplicator.StoreEntityModifier( ent, "adv_health_tool", data )
	if do_undo then
		undo_text = undo_text or "Set health settings"
		undo.Create( undo_text .. " ( " .. ( ent:GetModel() or "?" ) .. " )" )
			undo.AddFunction( function()
				if not IsValid( ent ) then return false end
				AHT_ApplySettings( ply, ent, oldData, false )
			end )
			undo.SetPlayer( ply )
		undo.Finish()
	end
	--end

end


function AHT_CopySettings( ent )
	return {
		health		= isfunction( ent.Health ) and ent:Health(),
		max_health	= isfunction( ent.GetMaxHealth ) and ent:GetMaxHealth(),
		unbreakable = ent:GetVar( "aht_unbreakable" ) or false,
		immune_mask = ent:GetVar( "aht_immune_mask" ) or 0,
	}
end