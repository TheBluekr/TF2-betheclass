/* Disclaimer, majority of the code here is re-used code from Vee's BeTheMerc and Grenade plugin. Credits to her for providing a huge base for this rewritten version. */

// Define sounds
#define Throw_Sound 				"weapons/grenade_throw.wav"
#define Prime_Sound					"misc/timer.mp3"
#define NoThrow_Sound				"common/wpn_denyselect.wav"
#define Recharge_Sound				"player/recharged.wav"

// Define models
//#define Merc_Model					"models/player/merc_deathmatch2.mdl"
#define Merc_Model					"models/player/merc_deathmatch2-fix.mdl" // V2 with grenade animation
#define Grenade_Model				"models/custom/ivory/enh_grenade/grenade.mdl"

// Define sprites
#define Grenade_Trail_Red			"stunballtrail_red_crit"
#define Grenade_Trail_Blu			"stunballtrail_blue_crit"

methodmap CMercenary < BaseClass
{
	public CMercenary(const int ind, bool uid=false)
	{
		return view_as<CMercenary>( BaseClass(ind, uid) );
	}
	property int iGrenadeStock
	{
		public get()
		{
			int i; hPlayerFields[this.index].GetValue("iGrenadeStock", i);
			return i;
		}
		public set(const int val)
		{
			int player = this.index;
			if( !player )
				return;
			hPlayerFields[player].SetValue("iGrenadeStock", val);
		}
	}
	property float fGrenadeCooldown
	{
		public get()
		{
			float f; hPlayerFields[this.index].GetValue("fGrenadeCooldown", f);
			return f;
		}
		public set(const float val)
		{
			int player = this.index;
			if( !player )
				return;
			hPlayerFields[player].SetValue("fGrenadeCooldown", val);
		}
	}
	property float fGrenadeThrowCooldown
	{
		public get()
		{
			float f; hPlayerFields[this.index].GetValue("fGrenadeThrowCooldown", f);
			return f;
		}
		public set(const float val)
		{
			int player = this.index;
			if( !player )
				return;
			hPlayerFields[player].SetValue("fGrenadeThrowCooldown", val);
		}
	}
	public void Init()
	{
		this.iGrenadeStock = cvarBTC[MercenaryGrenade].IntValue;
		this.fGrenadeCooldown = 0.0;
		this.fGrenadeThrowCooldown = 0.0;
	}
	public void OnSpawn()
	{
		SetPawnTimer(SetupMercenary, 0.25, this);
	}
	public void OnDeath(BaseClass attacker, BaseClass victim, Event event)
	{
		SetHudTextParams(0.75, 0.85, 0.5, 255, 255, 255, 255, 2, 0.0, 0.0, 0.0);
		ShowSyncHudText(this.index, GrenadeHUD, "");
	}
	public void OnKill(BaseClass attacker, BaseClass victim, Event event)
	{
		if(event.GetInt("damagebits") == 32) {
			event.SetInt("customkill", TF_CUSTOM_TAUNT_GRENADE);
			event.SetString("weapon_logclassname", "merc_grenade");
		}
	}
	public void OnItemPickUp(BaseClass baseplayer, char item[64], Event event)
	{
		if(StrEqual(item, "ammopack_small", false))
		{
			int ammo = GetAmmo(baseplayer.index, TFWeaponSlot_Secondary);
			int maxAmmo = SDK_GetMaxAmmo(baseplayer.index, TFWeaponSlot_Secondary);
			if(ammo < maxAmmo) // Bug fix, we can go outside the maximum intended ammo pool by +1 if picking up an ammo box at max ammo
				SetAmmo(baseplayer.index, TFWeaponSlot_Secondary, ammo+1);
		}
	}

	public void OnVoiceMenu(char[] szCmd1, char[] szCmd2)
	{
	}

	public void Think()
	{
		/*
		if(GetEntPropEnt(this.index, Prop_Send, "m_hActiveWeapon") == GetPlayerWeaponSlot(this.index, TFWeaponSlot_Melee))
			SetEntPropFloat(this.index, Prop_Send, "m_flMaxspeed", 345.0); // 15% increase on melee
		else
			SetEntPropFloat(this.index, Prop_Send, "m_flMaxspeed", 300.0); // Default value according to https://forums.alliedmods.net/showthread.php?t=266584
		*/

		char sModel[128];
		GetEntPropString(this.index, Prop_Data, "m_ModelName", sModel, sizeof(sModel)); // Get the complete Modelname.
		if(StrEqual(sModel, Soldier_Model, false)) { // Bug fix, removing quads turns the player to default soldier model
			SetVariantString(Merc_Model);
			AcceptEntityInput(this.index, "SetCustomModel");
			SetEntProp(this.index, Prop_Send, "m_bUseClassAnimations", 1);
		}
		if(this.iGrenadeStock < cvarBTC[MercenaryGrenade].IntValue && this.fGrenadeCooldown <= GetEngineTime()) {
			this.iGrenadeStock++;
			if(this.iGrenadeStock < cvarBTC[MercenaryGrenade].IntValue) // In case there were none
				this.fGrenadeCooldown = GetEngineTime() + cvarBTC[MercenaryGrenadeRegen].FloatValue;
			EmitSoundToClient(this.index, Recharge_Sound);
		}
		int iWeapon = GetEntPropEnt(this.index, Prop_Send, "m_hActiveWeapon");
		int iGrapplinghook = FindGrapplingHook(this.index);
		if(!iWeapon || !IsValidEdict(iWeapon)) // Invalid weapon is equipped/active, we should stop here
			return;
		if((GetClientButtons(this.index) & IN_ATTACK2) && this.fGrenadeThrowCooldown <= GetEngineTime() && this.iGrenadeStock > 0)
		{
			SDK_PlaySpecificSequence(this.index, "grenade_throw");
			RequestFrame(GrenadeThrow, this);
			this.fGrenadeThrowCooldown = GetEngineTime() + 2.5;
		}
		if((GetClientButtons(this.index) & IN_ATTACK3) && IsValidEntity(iGrapplinghook) && iWeapon != iGrapplinghook)
		{
			FakeClientCommand(this.index, "use tf_weapon_grapplinghook");
		}
	}
	public void UpdateHUD()
	{
		char GrenadeHUDText[255]; // Display of current amount grenades
		Format(GrenadeHUDText, sizeof(GrenadeHUDText), "Grenades: %i", this.iGrenadeStock);
		if(IsClientAlive(this.index)) {
			SetHudTextParams(0.75, 0.85, 0.5, 255, 255, 255, 255, 2, 0.0, 0.0, 0.0);
			ShowSyncHudText(this.index, GrenadeHUD, GrenadeHUDText);
		}
	}
	public void OnConditionAdded(TFCond condition)
	{
	}
}

public CMercenary ToCMercenary(const BaseClass guy)
{
	return view_as<CMercenary>(guy);
}

public void SetupMercenary(CMercenary merc)
{
	char sModel[128];
	GetEntPropString(merc.index, Prop_Data, "m_ModelName", sModel, sizeof(sModel)); // Get the complete Modelname.
	if(!StrEqual(sModel, Merc_Model, false) && (merc.iTeam == FF2_GetBossTeam() || FF2_GetBossIndex(merc.index) != -1))
	{
		merc.iClassType = None;
		SetHudTextParams(0.75, 0.85, 0.5, 255, 255, 255, 255, 2, 0.0, 0.0, 0.0);
		ShowSyncHudText(merc.index, GrenadeHUD, "");
		return;
	}
	if(IsClientHere(merc.index)) { // Assuming we're using normal or quad model)
		TF2_SetPlayerClass(merc.index, TFClass_Soldier, _, false);
		//SetEntProp(merc.index, Prop_Send, "m_iClass", 10);
		SetBaseSpeed(merc.index, 300.0);
		TF2Attrib_SetByName(merc.index, "max health additive penalty", -50.0);
		SetEntityHealth(merc.index, 175); // Just in case

		merc.RemoveAllItems();

		// Grenades
		merc.iGrenadeStock = cvarBTC[MercenaryGrenade].IntValue;
		merc.fGrenadeCooldown = 0.0;

		SetVariantString(Merc_Model);
		AcceptEntityInput(merc.index, "SetCustomModel");
		SetEntProp(merc.index, Prop_Send, "m_bUseClassAnimations", 1);
		SpawnWeapon(merc.index, "tf_weapon_scattergun", 1153, 1, 0, "2030 ; 1 ; 808 ; 0 ; 1 ; 1 ; 6 ; 0.75 ; 106 ; 0.75 ; 547 ; 1");
		SpawnWeapon(merc.index, "tf_weapon_smg", 1098, 1, 0, "306 ; 0 ; 647 ; 0 ; 392 ; 0.5 ; 4 ; 1.2 ; 2 ; 1.5 ; 106 ; 0.5 ; 96 ; 3.0 ; 144 ; 1 ; 51 ; 0 ; 78 ; 6.25");
		SpawnWeapon(merc.index, "tf_weapon_shovel", 30758, 1, 0, "2030 ; 1 ; 149 ; 3 ; 851 ; 1.15 ; 1 ; 0.9 ; 851 ; 1,4375‬");
		SpawnWeapon(merc.index, "tf_weapon_grapplinghook", 1152, 1, 0, "547 ; 1 ; 199 ; 1 ; 289 ; 1");
		//SpawnWeapon(merc.index, "tf_weapon_spellbook", 1132, 1, 0, "547 ; 0 ; 199 ; 0 ; 289 ; 1 ; 643 ; 0.125 ; 280 ; 2");
		SetAmmo(merc.index, TFWeaponSlot_Primary, 20);
		SetAmmo(merc.index, TFWeaponSlot_Secondary, 200); // Bug fix, Merc spawns with 32 ammo on secondary
		PrintToChatAll("Done running setup");
	}
}

public void GrenadeThrow(CMercenary merc)
{
	if(merc.iGrenadeStock <= 0) {
		EmitSoundToClient(merc.index, NoThrow_Sound, merc.index, _, _, _, 1.0);
		return;
	}
	
	float pos[3], endPos[3], angle[3], vecs[3];
	GetClientEyePosition(merc.index, pos);
	GetClientEyeAngles(merc.index, angle);
	GetAngleVectors(angle, vecs, NULL_VECTOR, NULL_VECTOR);
	Handle trace = TR_TraceRayFilterEx(pos, angle, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);
	if(TR_DidHit(trace))
		TR_GetEndPosition(endPos, trace);
	CloseHandle(trace);
	if(GetVectorDistance(endPos, pos, false) < 45.0) {
		EmitSoundToClient(merc.index, NoThrow_Sound, merc.index, _, _, _, 1.0);
		return;
	}

	pos[0] += vecs[0]*32.0;
	pos[1] += vecs[1]*32.0;
	ScaleVector(vecs, 1000.0); // Throw speed scale

	int iGrenade;
	switch(merc.Team) {
		case TFTeam_Red:	iGrenade = SpawnGrenade(merc.index, Grenade_Model, Grenade_Trail_Red, false); // Should return -1 if unsuccesful
		case TFTeam_Blue:	iGrenade = SpawnGrenade(merc.index, Grenade_Model, Grenade_Trail_Blu, false);
	}
	if(iGrenade == -1) { // Invalid spawn
		EmitSoundToClient(merc.index, NoThrow_Sound, merc.index, _, _, _, 1.0);
		return;
	}
	DispatchSpawn(iGrenade);
	SetEntProp(iGrenade, Prop_Data, "m_takedamage", 0);
	TeleportEntity(iGrenade, pos, NULL_VECTOR, vecs);
	EmitSoundToClient(merc.index, Prime_Sound, iGrenade, _, _, _, 1.0);
	SetPawnTimer(GrenadeExplode, 3.8, EntIndexToEntRef(iGrenade));
	merc.iGrenadeStock--;
	if(merc.fGrenadeCooldown <= GetEngineTime()) // Assuming we were on 2 grenades there should be no cooldown (yet)
		merc.fGrenadeCooldown = GetEngineTime() + cvarBTC[MercenaryGrenadeRegen].FloatValue;
}

public void GrenadeExplode(int iRef)
{
	int iGrenade = EntRefToEntIndex(iRef);
	if(!IsValidEntity(iGrenade))
		return;
	int client = GetEntPropEnt(iGrenade, Prop_Data, "m_hOwnerEntity");
	if(!IsValidClient(client)) {
		AcceptEntityInput(iGrenade, "Kill");
		return;
	}
	if (GetMaxEntities() - GetEntityCount() < 200)
	{
		ThrowError("[BeTheClass] Cannot spawn initial explosion, too many entities exist. Try reloading the map.");
		AcceptEntityInput(iGrenade, "Kill");
		return;
	}
	
	float pos[3];
	GetEntPropVector(iGrenade, Prop_Data, "m_vecOrigin", pos);
	pos[2] += 32.0;
	int team = GetClientTeam(client);
	AcceptEntityInput(iGrenade, "Kill");
	if(team == 1 && !IsClientAlive(client))
		return;
	if(BaseClass(client).iClassType != Mercenary)
		return;
	
	int explosion = CreateEntityByName("env_explosion");
	if(explosion != -1)
	{
		DispatchKeyValue(explosion, "iMagnitude", "450");
		DispatchKeyValue(explosion, "iRadiusOverride", "200");
		DispatchKeyValue(explosion, "spawnflags", "0");
		DispatchKeyValue(explosion, "rendermode", "5");
		SetEntProp(explosion, Prop_Send, "m_iTeamNum", team);
		SetEntPropEnt(explosion, Prop_Data, "m_hOwnerEntity", client);
		//SetEntProp(explosion, Prop_Send, "m_bCritical", (GetURandomFloatRange(0.0, 100.0) <= 2.0) ? 1 : 0, 1)
		DispatchSpawn(explosion);
		ActivateEntity(explosion);
		TeleportEntity(explosion, pos, NULL_VECTOR, NULL_VECTOR);				
		AcceptEntityInput(explosion, "Explode");
		RequestFrame(EntityCleanup, EntIndexToEntRef(explosion));
	}
	else
		ThrowError("[BeTheClass] Failed to spawn grenade explosion");
}

public void AddMercenaryToDownload()
{
	// Precache particle systems
	PrecacheParticleSystem(Grenade_Trail_Red);
	PrecacheParticleSystem(Grenade_Trail_Blu);
	
	// Precache models
	PrecacheModel(Merc_Model, true);
	PrecacheModel(Grenade_Model, true);
	
	// Precache sounds
	PrecacheSound(Throw_Sound, true);
	PrecacheSound(NoThrow_Sound, true);
	PrecacheSound(Recharge_Sound, true);
	PrecacheSound(Prime_Sound, true);
}