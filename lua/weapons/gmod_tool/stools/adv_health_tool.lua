local mode = TOOL.Mode -- Class name of the tool. (name of the .lua file) 

TOOL.Category		= "Construction"
TOOL.Name			= "#Tool."..mode..".listname"
TOOL.ConfigName		= ""
TOOL.ClientConVar[ "max_health" ] = "100"
TOOL.ClientConVar[ "health" ] = "100"
TOOL.ClientConVar[ "use_max" ] = "0"
TOOL.ClientConVar[ "unbreakable" ] = "0"
TOOL.ClientConVar[ "fire_immune" ] = "0"
TOOL.ClientConVar[ "tooltip_enabled" ] = "1"
TOOL.Information = {
	{ name = "left" },
	{ name = "right" },
	{ name = "reload" },
}


if CLIENT then

	local t = "tool."..mode.."."
	language.Add( t.."listname",	"Advanced Health" )
	language.Add( t.."name",		"Advanced Health Tool" )
	language.Add( t.."desc",		"Change the health-related properties of entities." )
	language.Add( t.."left",		"Apply settings" )
	language.Add( t.."right",		"Copy settings" )
	language.Add( t.."reload",		"Reset entity settings" )

end


if SERVER then

	hook.Add( "EntityTakeDamage", "aht_damage_filtering", function( target, dmginfo )
		if not target.aht_damage_filtered then return end
		if target.aht_unbreakable or ( target.aht_fire_immune and dmginfo:IsDamageType( DMG_BURN ) ) then
			dmginfo:SetDamage( 0 )
		end
	end )

end

local function AHT_CopySettings( ent )
	return {
		health		= isfunction( ent.Health ) and ent:Health(),
		max_health	= isfunction( ent.GetMaxHealth ) and ent:GetMaxHealth(),
		unbreakable = ent:GetVar( "aht_unbreakable" ) or false,
		fire_immune	= ent:GetVar( "aht_fire_immune" ) or false,
	}
end


local function AHT_ApplyNRemember( ent, newval, setter, getter, orig_key )
	if not ( newval and isfunction( setter ) ) then return false end
	local o = ent[ orig_key ] or getter( ent )
	ent[ orig_key ] = o ~= newval and o or nil
	setter( ent, newval )
	return true
end

function AHT_ApplySettings( ply, ent, data, do_undo )

	local oldData
	if SERVER and do_undo ~= false then
		oldData = AHT_CopySettings( ent )
		do_undo = false
		for k, v in pairs( data ) do
			if v ~= oldData[k] then
				do_undo = true
			end
		end
	end

	AHT_ApplyNRemember( ent, data.health, ent.SetHealth, ent.Health, "aht_orig_health" )
	AHT_ApplyNRemember( ent, data.max_health, ent.SetMaxHealth, ent.GetMaxHealth, "aht_orig_max_health" )
	local k1, k2 = "unbreakable", "fire_immune"
	ent["aht_"..k1] = data[k1] or nil
	ent["aht_"..k2] = data[k2] or nil
	ent.aht_damage_filtered = data[k1] or data[k2] or nil

	if SERVER then
		duplicator.StoreEntityModifier( ent, "adv_health_tool", data )
		if do_undo then
			undo.Create( "Health Settings Change ("..(ent:GetModel() or "?")..")" )
				undo.AddFunction( function( undo )
					if not IsValid( ent ) then return false end
					AHT_ApplySettings( ply, ent, oldData, false )
				end )
				undo.SetPlayer( ply )
			undo.Finish()
		end
	end
end



if SERVER then

	duplicator.RegisterEntityModifier( "adv_health_tool", AHT_ApplySettings )

	function TOOL:Think()

		if not self:GetClientBool( "tooltip_enabled" ) then return end

		local ent = self:GetOwner():GetEyeTrace().Entity
		if not IsValid( ent ) then return end 

		for k, v in pairs( AHT_CopySettings( ent ) ) do
			local funcKey = isbool( v ) and "SetNW2Bool" or "SetNW2Int"
			ent[ funcKey ]( ent, "aht_"..k, v )
		end

	end

end


function TOOL:LeftClick( trace )
	
	local ent = trace.Entity
	if ent:IsWorld() or not ent:IsValid() then return false end
	
	local data = {
		max_health	= self:GetClientNumber( "max_health" ),
		unbreakable = self:GetClientBool( "unbreakable" ),
		fire_immune	= self:GetClientBool( "fire_immune" ),
	}
	data.health = self:GetClientBool( "use_max" ) and data.max_health or self:GetClientNumber( "health" )

	AHT_ApplySettings( self:GetOwner(), ent, data )
	return true

end


function TOOL:RightClick( trace )
	
	local ent = trace.Entity
	if ent:IsWorld() or not ent:IsValid() then return false end

	for k, v in pairs( AHT_CopySettings( ent ) ) do
		if isbool( v ) then v = v and 1 or 0 end
		RunConsoleCommand( mode.."_"..k, v )
	end
	return true
end


function TOOL:Reload( trace )

	local ent = trace.Entity

	if ent:IsWorld() or not ent:IsValid() then return false end

	if SERVER then duplicator.ClearEntityModifier( ent, "adv_health_tool" ) end

	AHT_ApplySettings( nil, ent, {
		health		= ent.aht_orig_health,
		max_health	= ent.aht_orig_max_health,
		unbreakable = false,
		fire_immune = false,
	} )
	return true

end


if CLIENT then

	local color_gold = Color( 240, 150, 40 )

	function TOOL:DrawHUD()

		if not self:GetClientBool("tooltip_enabled") then return end

		local ply = self:GetOwner()

		local ent = ply:GetEyeTrace().Entity

		if not IsValid( ent ) then return end

		local vecmin, vecmax = ent:WorldSpaceAABB()
		local pos = ent:WorldSpaceCenter()
		pos.z = vecmax.z
		local pos = pos:ToScreen()
		local x, y = pos.x, pos.y
		
		local health	= ent:GetNW2Int( "aht_health" )
		local max_health = ent:GetNW2Int( "aht_max_health" )
		local unbreak	= ent:GetNW2Bool( "aht_unbreakable" )
		local fireImm	= ent:GetNW2Bool( "aht_fire_immune" )
		local prop = health / max_health or 1 -- lua can handle division by 0


		local text1 = ("Health: %s / %s"):format( health or "N/A", max_health or "N/A" )
		local text2 = max_health ~= 0 and (" (%s%%)"):format( math.Round( prop*100, 2 ) ) or "" -- better to hide -inf, nan and inf than show it to players i guess
		-- this is bad
		local text3 = unbreak and fireImm and "Unbreakable, Fire Immune"  or unbreak and "Unbreakable" or fireImm and "Fire Immune" or ""
		local font = "GModWorldtip"

		prop = math.Clamp( prop, 0, 3 )
		local txcol	= HSVToColor( 100*prop, 0.65, 0.9 )
		local bgcol = HSVToColor( 100*prop, 1, 0.1 )
			bgcol.a = 220
		local rad   = 8

		surface.SetFont( font )
		local tw1, th1 = surface.GetTextSize( text1 )
		local tw2, th2 = surface.GetTextSize( text2 )
		local tw3, th3 = surface.GetTextSize( text3 )
		if tw3 == 0 then th3 = 0 end
		local tw, th = math.max( tw1 + tw2, tw3 ), th1 + th3

		y = y - th

		draw.RoundedBox( rad, x - tw/2 - 10, y - th1/2 - 2, tw + 20, th + 4, bgcol )
		draw.SimpleText( text1, font, x - tw2/2, y, color_white, 1, 1 )
		draw.SimpleText( text2, font, x + tw1/2, y, txcol, 1, 1 )
		if text3 ~= "" then draw.SimpleText( text3, font, x, y+th1, color_gold, 1, 1 ) end
	end

end



local cvarlist = TOOL:BuildConVarList()

function TOOL.BuildCPanel( cPanel )

	local color_gray	= Color( 240, 240, 240 )
	local color_red		= Color( 220, 40, 20 )
	local color_orange	= Color( 220, 120, 20 )
	local color_green	= Color( 35, 155, 100 )

	local function paint( panel, w, h, hcol, bgcol )
		local topHeight = panel:GetHeaderHeight()
		local c = not panel:GetExpanded()
		draw.RoundedBoxEx( 4, 0, 0, w, topHeight, hcol, true, true, c, c )
		draw.RoundedBoxEx( 8, 0, topHeight, w, h - topHeight + 5, bgcol, false, false, true, true )
	end

	cPanel:Help( "#tool."..mode..".desc" )

	cPanel:ToolPresets( mode, cvarlist )

	local limitHealth	= 2147483520
	local lowHealth		= 1

	local healthForm = vgui.Create( "DForm", cPanel )
		cPanel:AddItem( healthForm )
		healthForm:SetExpanded( true )
		healthForm:SetLabel( "Health and Max Health" )
		healthForm:SetPaintBackground( false )
		healthForm:DockPadding( 0, 0, 0, 5 )
		function healthForm:Paint( w, h )
			paint( self, w, h, color_red, color_gray )
		end

		local maxHealthSlider = healthForm:NumSlider( "Max Health", mode.."_max_health", 0, 5000, 0 )
			maxHealthSlider:SetToolTip("Sets the entity's maximum health. NPCs can heal up to this amount.")
			healthForm:ControlHelp( "I recommend using a value greather than that of Base Health to prevent weird behavior for NPCs." )

		local healthSlider = healthForm:NumSlider( "Base Health", mode.."_health", 0, maxHealthSlider:GetMax(), 0 )
			healthSlider:SetToolTip("Sets the current and duped health of the entity.")

		healthForm:ControlHelp( ("You can set these higher than %s if you want."):format( maxHealthSlider:GetMax() ) )

		local FR_button = vgui.Create( "DButton" )
			FR_button:Dock( TOP )
			FR_button:SetText( "Make fragile" )	
			FR_button:SetImage( "icon32/hand_property.png" )
			function FR_button:DoClick()
				maxHealthSlider.Scratch:SetValue( lowHealth )
				healthSlider.Scratch:SetValue( lowHealth )
			end
			FR_button:SetToolTip( ("Set Base Health and Max Health to %s."):format( lowHealth ) )

		local NU_button = vgui.Create( "DButton" )
			NU_button:Dock( TOP )
			NU_button:SetText( "Make near-unbreakable" )	
			NU_button:SetImage( "icon32/tool.png" )
			function NU_button:DoClick()
				maxHealthSlider.Scratch:SetValue( limitHealth )
				healthSlider.Scratch:SetValue( limitHealth )
			end
			NU_button:DockMargin( 15, 0, 0, 0 )
			NU_button:SetToolTip( ("Set Base Health and Max Health to %s."):format( limitHealth ) )
		
		healthForm:AddItem( FR_button, NU_button )

		local STMH_checkBox = healthForm:CheckBox( "Heal", mode.."_use_max" )
			STMH_checkBox:SetToolTip( ( "Set Base Health to the same value as Max Health" ) )
			function STMH_checkBox:OnChange( checked )
				healthSlider:SetEnabled( not checked )
				if checked then healthSlider.Scratch:SetValue( maxHealthSlider.Scratch:GetFloatValue() ) end
			end

		function maxHealthSlider:OnValueChanged( value )
			if STMH_checkBox:GetChecked() then
				healthSlider.Scratch:SetValue( maxHealthSlider.Scratch:GetFloatValue() )
			end
		end

	local filterForm = vgui.Create( "DForm", cPanel )
		cPanel:AddItem( filterForm )
		filterForm:SetExpanded( true )
		filterForm:SetLabel( "Damage filtering" )
		filterForm:SetPaintBackground( false )
		filterForm:DockPadding( 0, 0, 0, 5 )
		function filterForm:Paint( w, h )
			paint( self, w, h, color_orange, color_gray )
		end

		local ubCheckBox = filterForm:CheckBox( "Unbreakable", mode.."_unbreakable" )
			ubCheckBox:SetToolTip( "Make the entity unable to take damage of any kind." )

		local fiCheckBox = filterForm:CheckBox( "Fire Immune", mode.."_fire_immune" )
			fiCheckBox:SetToolTip( "Make the entity unable to take burn damage." )

	local helpForm = vgui.Create( "DForm", cPanel )
		cPanel:AddItem( helpForm )
		helpForm:SetExpanded( true )
		helpForm:SetLabel( "Help" )
		helpForm:SetPaintBackground( false )
		helpForm:DockPadding( 0, 0, 0, 5 )
		function helpForm:Paint( w, h )
			paint( self, w, h, color_green, color_gray )
		end

		local tooltipCheckBox = helpForm:CheckBox( "Enable Tooltips", mode.."_tooltip_enabled" )
			tooltipCheckBox:SetToolTip( "Show a health tooltip when looking at something with this tool." )


end

