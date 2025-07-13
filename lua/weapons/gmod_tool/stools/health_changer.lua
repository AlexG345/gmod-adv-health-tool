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
	language.Add( t.."listname",	"Health Changer" )
	language.Add( t.."name",		"Health Changer" )
	language.Add( t.."desc",		"Change the health-related properties of an object" )
	language.Add( t.."left",		"Apply settings" )
	language.Add( t.."right",		"Copy settings" )
	language.Add( t.."reload",		"Reset entity settings" )

end


if SERVER then
--[[ DEPRECATED
	-- creates the damage filters to be used for unbreakable and fire immune entities

	local function HC_InitFilter_No()
		local filter = ents.Create( "filter_base" )
		filter:SetKeyValue( "TargetName", "hc_filter_no" )
		filter:SetKeyValue( "negated", "1" ) -- always no
		filter:Spawn()
		filter:CallOnRemove( "hc_init_filter_no", function() timer.Simple( 0, HC_InitFilter_No ) end )
	end
	
	-- DOES NOT WORk 100% OF THE TIME
	local function HC_InitFilter_BurnDmg()
		-- https://developer.valvesoftware.com/wiki/Filter_damage_type
		local filter = ents.Create( "filter_damage_type" )
		filter:SetKeyValue( "TargetName", "hc_filter_burn_dmg" )
		filter:SetKeyValue( "damagetype", tostring( DMG_BURN + DMG_DIRECT ) ) -- Tested in-game to find the damage type combination which needs to be targeted
		filter:SetKeyValue( "negated", "1" )
		filter:Spawn()
		filter:CallOnRemove( "hc_init_filter_burn_dmg", function() timer.Simple( 0, HC_InitFilter_BurnDmg ) end )
	end

	local function HC_InitFilters()
		HC_InitFilter_No()
		HC_InitFilter_BurnDmg()
	end

	hook.Add( "InitPostEntity", "hc_init_filters", HC_InitFilters )
]]

	hook.Add( "EntityTakeDamage", "hc_damage_filtering", function( target, dmginfo )
		if not target.hc_damage_filtered then return end
		if target.hc_unbreakable or ( target.hc_fire_immune and dmginfo:IsDamageType( DMG_BURN ) ) then
			dmginfo:SetDamage( 0 )
		end
	end )

	--[[
	hook.Add( "PostEntityTakeDamage", "hc_burn_remover", function( target, dmginfo )
		if target.hc_fire_immune then
			target:Extinguish()
		end
	end )
	]]

end

local function HC_ApplyHealth( ent, health )
	if not ( health and isfunction( ent.SetHealth ) ) then return false end
	if not ent.hc_origHealth then ent.hc_origHealth = ent:Health() end
	if ent.hc_origHealth == health then ent.hc_origHealth = nil end
	ent:SetHealth( health )
	return true
end

local function HC_ApplyMaxHealth( ent, maxHealth )
	if not ( maxHealth and isfunction( ent.SetMaxHealth ) ) then return false end
	if not ent.hc_origMaxHealth then ent.hc_origMaxHealth = ent:GetMaxHealth() end
	if ent.hc_origMaxHealth == maxHealth then ent.hc_origMaxHealth = nil end
	ent:SetMaxHealth( maxHealth )
	return true
end

function HC_ApplySettings( ply, ent, data )

	local health	= data.Health
	local maxHealth = data.MaxHealth
	local unbreak	= data.Unbreakable
	local fireImm	= data.FireImmune

	HC_ApplyHealth( ent, health )
	HC_ApplyMaxHealth( ent, maxHealth )

	if unbreak ~= nil then ent.hc_unbreakable = unbreak or nil end
	if fireImm ~= nil then ent.hc_fire_immune = fireImm or nil end

	ent.hc_damage_filtered = ent.hc_unbreakable or ent.hc_fire_immune or nil

	PrintTable( data )

	if SERVER then duplicator.StoreEntityModifier( ent, "health_changer", data ) end

end

if SERVER then

	duplicator.RegisterEntityModifier( "health_changer", HC_ApplySettings )

	function TOOL:Think()

		local ply = self:GetOwner()
		local ent = ply:GetEyeTrace().Entity
		if not IsValid( ent ) then return end 

		local health = isfunction( ent.Health ) and ent:Health()
		local maxHealth = isfunction( ent.GetMaxHealth ) and ent:GetMaxHealth()

		-- NW2 checks if the value has changed before sending which is great.
		if health then ent:SetNW2Int( "HC_Health", health ) end
		if maxHealth then ent:SetNW2Int( "HC_MaxHealth", maxHealth ) end
		ent:SetNW2Bool( "HC_Unbreakable", ent:GetVar( "hc_unbreakable" ) or false )
		ent:SetNW2Bool( "HC_FireImmune", ent:GetVar( "hc_fire_immune" ) or false )

	end

end


function TOOL:LeftClick(trace)
	
	local ent = trace.Entity
	
	if ent:IsWorld() or not ent:IsValid() then return false end
	
	local data = {
		MaxHealth	= self:GetClientNumber( "max_health" ),
		Unbreakable = self:GetClientBool( "unbreakable" ),
		FireImmune	= self:GetClientBool( "fire_immune" ),
	}
	data.Health = self:GetClientBool( "use_max" ) and data.MaxHealth or self:GetClientNumber( "health" )

	HC_ApplySettings( self:GetOwner(), ent, data )
	return true

end


function TOOL:RightClick(trace)
	
	local ent = trace.Entity
	
	if ent:IsWorld() or not ent:IsValid() then return false end

	if isfunction( ent.Health ) then RunConsoleCommand( mode.."_health", ent:Health() ) end
	if isfunction( ent.GetMaxHealth ) then RunConsoleCommand( mode.."_max_health", ent:GetMaxHealth() ) end
	RunConsoleCommand( mode.."_unbreakable", ent:GetVar( "hc_unbreakable" ) and 1 or 0 )
	RunConsoleCommand( mode.."_fire_immune", ent:GetVar( "hc_fire_immune" ) and 1 or 0 )

	return true

end


function TOOL:Reload( trace )

	local ent = trace.Entity

	if ent:IsWorld() or not ent:IsValid() then return false end

	duplicator.ClearEntityModifier( ent, "health_changer" )

	HC_ApplySettings( nil, ent, {
		Health		= ent.hc_origHealth,
		MaxHealth	= ent.hc_origMaxHealth,
		Unbreakable = false,
		FireImmune = false,
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
		
		local health	= ent:GetNW2Int( "HC_Health" )
		local maxHealth = ent:GetNW2Int( "HC_MaxHealth" )
		local unbreak	= ent:GetNW2Bool( "HC_Unbreakable" )
		local fireImm	= ent:GetNW2Bool( "HC_FireImmune" )
		local prop = maxHealth ~= 0 and math.Clamp( health / maxHealth, 0, 1 ) or 1

		local text1 = ("Health: %s / %s"):format( health or "N/A", maxHealth or "N/A" )
		local text2 = (" (%s%%)"):format( math.Round( 100*prop, 1 ) or "N/A" )
		local text3 = unbreak and fireImm and "Unbreakable, Fire Immune"  or unbreak and "Unbreakable" or fireImm and "Fire Immune" or nil

		local col2	= HSVToColor( 100*prop, 0.65, 0.9 )
		local bgcol = HSVToColor( 100*prop, 1, 0.1 )
		bgcol.a = 220
		local font  = "GModWorldtip"
		local rad   = 8
		
		surface.SetFont( font )
		local tw1, th1 = surface.GetTextSize( text1 )
		local tw2, th2 = surface.GetTextSize( text2 )
		local tw3, th3 = 0, 0
		if text3 then tw3, th3 = surface.GetTextSize( text3 ) end
		local tw = math.max( tw1 + tw2, tw3 )
		local th = th1 + th3
		
		y = y - th

		draw.RoundedBox( rad, x - tw/2 - 10, y - th1/2 - 2, tw + 20, th + 4, bgcol )
		draw.SimpleText( text1, font, x - tw2/2, y, color_white, 1, 1 )
		draw.SimpleText( text2, font, x + tw1/2, y, col2, 1, 1 )
		if text3 then draw.SimpleText( text3, font, x, y+th1, color_gold, 1, 1 ) end
	end

end



local cvarlist = TOOL:BuildConVarList()

function TOOL.BuildCPanel( cPanel )

	local color_blue = Color( 50, 100, 200 )
	local color_green = Color( 35, 155, 100 )
	local color_gray = Color( 240, 240, 240 )
	local color_orange = Color( 220, 120, 20 )
	local color_red = Color( 220, 40, 20 )

	local function paint( panel, w, h, hcol, bgcol )
		local topHeight = panel:GetHeaderHeight()
		local c = not panel:GetExpanded()
		draw.RoundedBoxEx( 4, 0, 0, w, topHeight, hcol, true, true, c, c )
		draw.RoundedBoxEx( 8, 0, topHeight, w, h - topHeight + 5, bgcol, false, false, true, true )
	end

	cPanel:Help( "#tool."..mode..".desc" )

	cPanel:ToolPresets( mode, cvarlist )

	local maxHealth = 2147483520
	local lowHealth = 1

	local healthForm = vgui.Create( "DForm", cPanel )
		cPanel:AddItem( healthForm )
		healthForm:SetExpanded( true )
		healthForm:SetLabel( "Health and Max Health" )
		healthForm:SetPaintBackground( false )
		healthForm:DockPadding( 0, 0, 0, 5 )
		function healthForm:Paint(w, h)
			paint( self, w, h, color_red, color_gray )
		end

		local maxHealthSlider = healthForm:NumSlider( "Max Health", mode.."_max_health", 0, maxHealth, 0 )

		local healthSlider = healthForm:NumSlider( "Base Health", mode.."_health", 0, maxHealth, 0 )

		local FR_button = vgui.Create( "DButton" )
			FR_button:Dock( TOP )
			FR_button:SetText( "Make fragile" )	
			FR_button:SetImage( "icon32/hand_property.png" )
			function FR_button:DoClick()
				maxHealthSlider:SetValue( lowHealth )
				healthSlider:SetValue( lowHealth )
			end
			FR_button:SetToolTip( ("Set Base Health and Max Health to %s."):format( lowHealth ) )

		local NU_button = vgui.Create( "DButton" )
			NU_button:Dock( TOP )
			NU_button:SetText( "Make near-unbreakable" )	
			NU_button:SetImage( "icon32/tool.png" )
			function NU_button:DoClick()
				maxHealthSlider:SetValue( maxHealth )
				healthSlider:SetValue( maxHealth )
			end
			NU_button:DockMargin( 15, 0, 0, 0 )
			NU_button:SetToolTip( ("Set Base Health and Max Health to %s."):format( maxHealth ) )
		
		healthForm:AddItem( FR_button, NU_button )

		local STMH_checkBox = healthForm:CheckBox( "Fully healed", mode.."_use_max" )
			STMH_checkBox:SetToolTip( ( "Set Base Health to the same value as Max Health" ) )
			function STMH_checkBox:OnChange( checked )
				healthSlider:SetEnabled( not checked )
				if checked then healthSlider:SetValue( maxHealthSlider:GetValue() ) end
			end

		function maxHealthSlider:OnValueChanged( value )
			if STMH_checkBox:GetChecked() then
				healthSlider:SetValue( value )
			end
		end

	local filterForm = vgui.Create( "DForm", cPanel )
		cPanel:AddItem( filterForm )
		filterForm:SetExpanded( true )
		filterForm:SetLabel( "Damage filtering" )
		filterForm:SetPaintBackground( false )
		filterForm:DockPadding( 0, 0, 0, 5 )
		function filterForm:Paint(w, h)
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
		function helpForm:Paint(w, h)
			paint( self, w, h, color_green, color_gray )
		end

		local tooltipCheckBox = helpForm:CheckBox( "Enable Tooltips", mode.."_tooltip_enabled" )
			tooltipCheckBox:SetToolTip( "Show a health tooltip when pointing something with the tool." )


end

