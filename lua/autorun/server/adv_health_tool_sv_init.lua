CreateConVar( "sv_adv_health_tool_nodmgforce", 1, bit.bor( FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED ), "(Advanced Health Tool): If true, any damage nullified by a filter won't apply force on the victim.", 0, 1 )
CreateConVar( "sv_adv_health_tool_enableundo", 0, FCVAR_ARCHIVE, "(Advanced Health Tool): If false, undo entries won't be created by the addon.", 0, 1 )


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
	local o = ent[orig_key] or getter( ent )
	ent[orig_key] = o ~= newval and o or nil
	setter( ent, newval )
	return true
end


function AHT_ApplySettings( ply, ent, data, do_undo, undo_text )

	local ubKey, imKey, tdKey = "unbreakable", "immune_mask", "m_takedamage"

	-------
	-- Backwards compability with Unbreakable Tool (https://steamcommunity.com/sharedfiles/filedetails/?id=111158387)
	-------

	local legacyUnbreak = ent.EntityMods and ent.EntityMods.Unbreakable
	if legacyUnbreak then
		if data.getLegacy then
			data[ubKey] = data[ubKey] or legacyUnbreak.On
		else
			legacyUnbreak.On = data[ubKey]
		end
		data.getLegacy = nil
	end

	-------
	-- Preserve current entity data if an undo entry is required
	-------

	local oldData
	if do_undo ~= false then
		oldData = AHT_CopySettings( ent )

		-- Don't uselessly create an undo entry
		do_undo = false
		for k, v in pairs( data ) do
			if v ~= oldData[k] then
				do_undo = true
				break
			end
		end
	end

	-------
	-- Save stuff that does NOT have a default value to reset to.
	-- Those are things added by AHT
	-------

	local unbreakable		= data[ubKey] or nil
	ent["aht_" .. ubKey]	= unbreakable

	local immune_mask = data[imKey]
	if immune_mask ~= nil then
		ent["aht_" .. imKey] = immune_mask ~= 0 and immune_mask or nil
	end
	immune_mask	= ent["aht_" .. imKey]

	local has_mask = ( immune_mask ~= 0 ) and ( immune_mask ~= nil )

	ent.aht_damage_filtered = unbreakable or has_mask or nil

	-------
	-- Save stuff that has a default value to reset to.
	-- Those are things already present in gmod (but normally unchangeable without lua)
	-------

	-- m_takedamage info can be found here: https://developer.valvesoftware.com/wiki/CBaseEntity
	local nodmgforce	= GetConVar( "sv_adv_health_tool_nodmgforce" )
	local m_takedamage	= unbreakable and ( nodmgforce and nodmgforce:GetBool() and 0 or 1 ) or ent["aht_orig_" .. tdKey]
	applyNRemember( ent, m_takedamage, function( e, v ) e:SetSaveValue( tdKey, v ) end, function( e ) return e:GetInternalVariable( tdKey ) end, "aht_orig_" .. tdKey )
	applyNRemember( ent, data.health,		ent.SetHealth,		ent.Health,			"aht_orig_health" )
	applyNRemember( ent, data.max_health,	ent.SetMaxHealth,	ent.GetMaxHealth,	"aht_orig_max_health" )

	-------
	-- Update duplicator
	-------

	data.getLegacy = true -- for (one-way) compability with the other addon
	duplicator.StoreEntityModifier( ent, "adv_health_tool", data )

	-------
	-- Add undo entry
	-------

	if not ( ply and do_undo ) then return end

	enableundo	= GetConVar( "sv_adv_health_tool_enableundo" )
	if not ( enableundo and enableundo:GetBool() ) then return end

	undo.Create( ( undo_text or "Set health settings" ) .. " ( " .. ( ent:GetModel() or "?" ) .. " )" )
		undo.AddFunction( function()
			if not IsValid( ent ) then return false end
			AHT_ApplySettings( ply, ent, oldData, false )
		end )
		undo.SetPlayer( ply )
	undo.Finish()


end

duplicator.RegisterEntityModifier( "adv_health_tool", AHT_ApplySettings )


function AHT_CopySettings( ent )
	return {
		health		= isfunction( ent.Health ) and ent:Health(),
		max_health	= isfunction( ent.GetMaxHealth ) and ent:GetMaxHealth(),
		unbreakable = ent:GetVar( "aht_unbreakable" ) or false,
		immune_mask = ent:GetVar( "aht_immune_mask" ) or 0,
	}
end