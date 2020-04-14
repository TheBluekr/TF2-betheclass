/*
Attempt at creating a custom class hub -Blue
*/

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <tf2attributes>
#include <tf2items>
#include <betheclass>
#undef REQUIRE_PLUGIN
#tryinclude <vsh2>
#tryinclude <freak_fortress_2>
#define REQUIRE_PLUGIN

#define int(%1)	view_as<int>(%1)

#define PLUGIN_VERSION "1.0.5"

// Python style declarations
#define or ||
#define and &&

#define Scout_Model					"models/player/scout.mdl"
#define Soldier_Model				"models/player/soldier.mdl"
#define Pyro_Model					"models/player/pyro.mdl"
#define Demo_Model					"models/player/demo.mdl"
#define Heavy_Model					"models/player/heavy.mdl"
#define Engineer_Model				"models/player/engineer.mdl"
#define Medic_Model					"models/player/medic.mdl"
#define Sniper_Model				"models/player/sniper.mdl"
#define Spy_Model					"models/player/spy.mdl"

public Plugin myinfo =
{
	name = "Be the class hub",
	author = "TheBluekr", // Add any names for who contribute
	description = "Set the player's class to any of the custom classes!",
	version = PLUGIN_VERSION,
	url = "https://steamcommunity.com/groups/VersusPonyvilleReborn"
}

enum /* CvarName */ {
	WizardLimit,
	WizardMana,
	WizardManaRegen,
	WizardManaOnHit,
	WizardFireCost,
	WizardFireCooldown,
	WizardFireCharges,
	WizardBatsCost,
	WizardBatsCooldown,
	WizardBatsCharges,
	WizardUberCost,
	WizardUberCooldown,
	WizardUberCharges,
	WizardJumpCost,
	WizardJumpCooldown,
	WizardJumpCharges,
	WizardInvisCost,
	WizardInvisCooldown,
	WizardInvisCharges,
	WizardInvisBonus,
	WizardMeteorCost,
	WizardMeteorCooldown,
	WizardMeteorCharges,
	WizardMonoCost,
	WizardMonoCooldown,
	WizardMonoCharges,
	MercenaryLimit,
	MercenaryGrenade,
	MercenaryGrenadeRegen,
	VersionNumber
};

enum /* Forwards */ {
	OnSpawn,
	OnDamageDealt,
	OnDamageTaken,
	OnWizardCast,
	OnMercenaryGrenadeThrow
}

bool g_vsh2 = false;

ConVar bEnabled = null;
ConVar cvarBTC[VersionNumber+1]; // Don't touch, add cvars in enum above

Handle forwardBTC[OnMercenaryGrenadeThrow];

// Define handles
Handle
	SpellHUD,
	CoolHUD,
	GrenadeHUD,
	StatusHUD,
	g_hSDKPlaySpecificSequence,
	g_hSDKGetMaxAmmo
;

// If you add any custom classes, update the .inc

BTCClass MaxClass = Mercenary; // Update this when new classes get added

StringMap hPlayerFields[MAXPLAYERS+1];

methodmap BaseClass
{
	public BaseClass(const int ind, bool uid=false)
	{
		int player=0;	// If you're using a userid and you know 100% it's valid, then set uid to true
		if( uid && GetClientOfUserId(ind) > 0 )
			player = (ind);
		else if( IsClientHere(ind) )
			player = GetClientUserId(ind);
		return view_as< BaseClass >( player );
	}

	// Properties
	property int userid {
		public get()
		{
			return view_as< int >(this);
		}
	}
	property int index {
		public get()
		{
			return GetClientOfUserId( view_as< int >(this) );
		}
	}
	property BTCClass iPresetType {
		public get()
		{
			if(!this.index)
				return None;
			BTCClass i; hPlayerFields[this.index].GetValue("iPresetType", i);
			return i;
		}
		public set(const BTCClass val)
		{
			int player = this.index;
			if( !player )
				return;
			hPlayerFields[player].SetValue("iPresetType", val);
		}
	}
	property BTCClass iClassType {
		public get()
		{
			if(!this.index)
				return None;
			BTCClass i; hPlayerFields[this.index].GetValue("iClassType", i);
			return i;
		}
		public set(const BTCClass val)
		{
			int player = this.index;
			if( !player )
				return;
			hPlayerFields[player].SetValue("iClassType", val);
		}
	}
	property TFTeam Team {
		public get()
		{
			return TF2_GetClientTeam(this.index);
		}
	}
	property int iTeam {
		public get()
		{
			return view_as<int>(TF2_GetClientTeam(this.index));
		}
	}
	public bool IsReady()
	{
		if(TF2_IsPlayerInCondition(this.index, TFCond_Cloaked) || TF2_IsPlayerInCondition(this.index, TFCond_Dazed) || TF2_IsPlayerInCondition(this.index, TFCond_Taunting) || TF2_IsPlayerInCondition(this.index, TFCond_Bonked) || TF2_IsPlayerInCondition(this.index, TFCond_RestrictToMelee) || TF2_IsPlayerInCondition(this.index, TFCond_MeleeOnly) || TF2_IsPlayerInCondition(this.index, TFCond_HalloweenGhostMode) || TF2_IsPlayerInCondition(this.index, TFCond_HalloweenKart))
			return false;
		return true;
	}
	public void RemoveAllItems()
	{
		TF2_RemovePlayerDisguise(this.index);
		
		int ent = -1;
		while( (ent = FindEntityByClassname(ent, "tf_wearabl*")) != -1 ) {
			if( GetOwner(ent) == this.index ) {
				TF2_RemoveWearable(this.index, ent);
				AcceptEntityInput(ent, "Kill");
			}
		}
		ent = -1;
		while( (ent = FindEntityByClassname(ent, "tf_powerup_bottle")) != -1 ) {
			if( GetOwner(ent) == this.index ) {
				TF2_RemoveWearable(this.index, ent);
				AcceptEntityInput(ent, "Kill");
			}
		}
		TF2_RemoveAllWeapons(this.index);
	}
	public void UpdateHUD(int client, Handle hHUD, const char[] text, float x, float y, float holdTime, int r, int g, int b, int a, int effect, float fxTime, float fadeIn, float fadeOut)
	{
		SetHudTextParams(x, y, holdTime, r, g, b, a, effect, fxTime, fadeIn, fadeOut);
		ShowSyncHudText(client, hHUD, text);
	}
}

// Add any external files here
#include "subclass/stocks.inc" // Always load this first
#include "subclass/wizard.sp"
#include "subclass/mercenary.sp"
#include "subclass/natives.sp"

public void OnLibraryAdded(const char[] name) {
	if( StrEqual(name, "VSH2") ) {
		g_vsh2 = true;
	}
}

public void OnLibraryRemoved(const char[] name) {
	if( StrEqual(name, "VSH2") ) {
		g_vsh2 = false;
	}
}

public void OnPluginStart()
{
	RegConsoleCmd("sm_class", CommandCreateClassMenu, "Usage: sm_class");
	RegAdminCmd("sm_forceclass", CommandForceClass, ADMFLAG_GENERIC, "Usage: sm_forceclass @target index");
	HookEvent("player_spawn", OnPlayerSpawn);
	HookEvent("player_death", OnPlayerDeath, EventHookMode_Pre);
	HookEvent("player_hurt", OnPlayerHurt, EventHookMode_Pre);
	HookEvent("player_changeclass", OnChangeClass);
	HookEvent("teamplay_round_start", OnRoundStart);
	HookEvent("teamplay_round_win", OnRoundEnd);
	HookEvent("item_pickup", OnItemPickUp, EventHookMode_Pre);
	AddCommandListener(OnJoinClass, "joinclass");
	AddCommandListener(OnJoinClass, "join_class");
	AddCommandListener(OnVoiceMenu, "voicemenu");
	//AddCommandListener(OnReload, "+reload");
	AddNormalSoundHook(HookSound);
	// Version ConVar
	bEnabled = CreateConVar("btc_enabled", "1", "Enable/disable BeTheClass plugin", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvarBTC[VersionNumber] = CreateConVar("btc_version_number", PLUGIN_VERSION, "BeTheClass Plugin Version Number. (DO NOT TOUCH)", FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_CHEAT);

	// Wizard cvars
	cvarBTC[WizardLimit] = CreateConVar("btc_wizard_limit", "2", "Limit for amount of wizards", FCVAR_NOTIFY, true, 0.0, false, 0.0);
	cvarBTC[WizardMana] = CreateConVar("btc_wizard_mana", "100.0", "Limit for total wizard mana pool", FCVAR_NOTIFY, true, 0.0, false, 0.0);
	cvarBTC[WizardManaRegen] = CreateConVar("btc_wizard_mana_regen", "1.0", "Mana regen rate per second", FCVAR_NOTIFY, true, 0.0, false, 0.0);
	cvarBTC[WizardManaOnHit] = CreateConVar("btc_wizard_mana_onhit", "10.0", "Bonus mana awarded on melee hit", FCVAR_NOTIFY, true, 0.0, false, 0.0);
	cvarBTC[WizardFireCost] = CreateConVar("btc_wizard_fire_cost", "20.0", "Mana cost for fire spell", FCVAR_NOTIFY, true, 0.0, false, 0.0);
	cvarBTC[WizardFireCooldown] = CreateConVar("btc_wizard_fire_cooldown", "4.5", "Cooldown for fire spell", FCVAR_NOTIFY, true, 0.0, false, 0.0);
	cvarBTC[WizardFireCharges] = CreateConVar("btc_wizard_fire_charges", "2", "Charges for fire spell", FCVAR_NOTIFY, true, 0.0, false, 0.0);
	cvarBTC[WizardBatsCost] = CreateConVar("btc_wizard_bats_cost", "25.0", "Mana cost for bats spell", FCVAR_NOTIFY, true, 0.0, false, 0.0);
	cvarBTC[WizardBatsCooldown] = CreateConVar("btc_wizard_bats_cooldown", "4.5", "Cooldown for bats spell", FCVAR_NOTIFY, true, 0.0, false, 0.0);
	cvarBTC[WizardBatsCharges] = CreateConVar("btc_wizard_bats_charges", "1", "Charges for bats spell", FCVAR_NOTIFY, true, 0.0, false, 0.0);
	cvarBTC[WizardUberCost] = CreateConVar("btc_wizard_uber_cost", "60.0", "Mana cost for uber spell", FCVAR_NOTIFY, true, 0.0, false, 0.0);
	cvarBTC[WizardUberCooldown] = CreateConVar("btc_wizard_uber_cooldown", "60.0", "Cooldown for uber spell", FCVAR_NOTIFY, true, 0.0, false, 0.0);
	cvarBTC[WizardUberCharges] = CreateConVar("btc_wizard_uber_charges", "1", "Charges for uber spell", FCVAR_NOTIFY, true, 0.0, false, 0.0);
	cvarBTC[WizardJumpCost] = CreateConVar("btc_wizard_jump_cost", "35.0", "Mana cost for uber spell", FCVAR_NOTIFY, true, 0.0, false, 0.0);
	cvarBTC[WizardJumpCooldown] = CreateConVar("btc_wizard_jump_cooldown", "6.0", "Cooldown for jump spell", FCVAR_NOTIFY, true, 0.0, false, 0.0);
	cvarBTC[WizardJumpCharges] = CreateConVar("btc_wizard_jump_charges", "2", "Charges for jump spell", FCVAR_NOTIFY, true, 0.0, false, 0.0);
	cvarBTC[WizardInvisCost] = CreateConVar("btc_wizard_invis_cost", "20.0", "Mana cost for invis spell", FCVAR_NOTIFY, true, 0.0, false, 0.0);
	cvarBTC[WizardInvisCooldown] = CreateConVar("btc_wizard_invis_cooldown", "20.0", "Cooldown for invis spell", FCVAR_NOTIFY, true, 0.0, false, 0.0);
	cvarBTC[WizardInvisCharges] = CreateConVar("btc_wizard_invis_charges", "1", "Charges for invis spell", FCVAR_NOTIFY, true, 0.0, false, 0.0);
	cvarBTC[WizardInvisBonus] = CreateConVar("btc_wizard_invis_bonus", "15.0", "Bonus awarded on melee hit while invisible (can be negative)", FCVAR_NOTIFY, false, 0.0, false, 0.0);
	cvarBTC[WizardMeteorCost] = CreateConVar("btc_wizard_meteor_cost", "90.0", "Mana cost for meteor spell", FCVAR_NOTIFY, true, 0.0, false, 0.0);
	cvarBTC[WizardMeteorCooldown] = CreateConVar("btc_wizard_meteor_cooldown", "40.0", "Cooldown for meteor spell", FCVAR_NOTIFY, true, 0.0, false, 0.0);
	cvarBTC[WizardMeteorCharges] = CreateConVar("btc_wizard_meteor_charges", "1", "Charges for meteor spell", FCVAR_NOTIFY, true, 0.0, false, 0.0);
	cvarBTC[WizardMonoCost] = CreateConVar("btc_wizard_mono_cost", "75.0", "Mana cost for monoculus spell", FCVAR_NOTIFY, true, 0.0, false, 0.0);
	cvarBTC[WizardMonoCooldown] = CreateConVar("btc_wizard_mono_cooldown", "40.0", "Cooldown for monoculus spell", FCVAR_NOTIFY, true, 0.0, false, 0.0);
	cvarBTC[WizardMonoCharges] = CreateConVar("btc_wizard_mono_charges", "1", "Charges for monoculus spell", FCVAR_NOTIFY, true, 0.0, false, 0.0);

	// Mercenary cvars
	cvarBTC[MercenaryLimit] = CreateConVar("btc_mercenary_limit", "3", "Limit for amount of mercenaries", FCVAR_NOTIFY, true, 0.0, false, 0.0);
	cvarBTC[MercenaryGrenade] = CreateConVar("btc_mercenary_grenade", "2", "Grenade stock limit for mercenaries", FCVAR_NOTIFY, true, 0.0, false, 0.0);
	cvarBTC[MercenaryGrenadeRegen] = CreateConVar("btc_mercenary_grenade_regen", "60.0", "Regen interval for grenades for mercenaries", FCVAR_NOTIFY, true, 0.0, false, 0.0);

	// Forwards
	forwardBTC[OnSpawn] = CreateGlobalForward("BTC_OnSpawn", ET_Event, Param_Cell, Param_CellByRef);
	//forwardBTC[OnDamageDealt] = CreateGlobalForward("BTC_OnDamage", ET_Event, Param_Cell, Param_Cell, Param_Cell);

	// Create HUD synchronizer
	SpellHUD = CreateHudSynchronizer();
	CoolHUD = CreateHudSynchronizer();
	GrenadeHUD = CreateHudSynchronizer();
	StatusHUD = CreateHudSynchronizer();

	for( int i=MaxClients ; i ; --i ) { // In case we load late
		if( !IsValidClient(i) )
			continue;
		OnClientPutInServer(i);
	}

	hPlayerFields[0] = new StringMap();

	AddWizardToDownloads();
	AddMercenaryToDownload();
}

public void OnAllPluginsLoaded()
{
	// Taking the SDK calls from STT, thanks for linking me this Ivory -Blue
	Handle hGamedata = LoadGameConfigFile("betheclass");
	if(hGamedata == INVALID_HANDLE)
	{
		LogMessage("Failed to load gamedata: betheclass.txt!");
		return;
	}

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGamedata, SDKConf_Signature, "CTFPlayer::GetMaxAmmo");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	g_hSDKGetMaxAmmo = EndPrepSDKCall();
	if(g_hSDKGetMaxAmmo == INVALID_HANDLE)
	{
		LogMessage("Failed to create call: CTFPlayer::GetMaxAmmo!");
	}

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGamedata, SDKConf_Signature, "CTFPlayer::PlaySpecificSequence");
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	g_hSDKPlaySpecificSequence = EndPrepSDKCall();
	if(g_hSDKPlaySpecificSequence == INVALID_HANDLE)
	{
		LogMessage("Failed to create call: CTFPlayer::PlaySpecificSequence!");
	}
}

public void OnClientPutInServer(int client)
{
	if(!IsValidClient(client))
		return;

	if( hPlayerFields[client] != null )
		delete hPlayerFields[client];

	hPlayerFields[client] = new StringMap();
	BaseClass baseplayer = BaseClass(client);
	// If any attributes are added, initialize them here before using them
	baseplayer.iPresetType = None;
	baseplayer.iClassType = None;

	// If any new custom classes are added, make sure to call an Init()
	ToCWizard(baseplayer).Init();
	ToCMercenary(baseplayer).Init();

	// Pickup block for wizard
	/*SDKHook(client, SDKHook_StartTouch, OnPickup);
	SDKHook(client, SDKHook_Touch, OnPickup);*/
}

public void OnClientDisconnect(int client)
{
	if(!IsValidClient(client))
		return;
	
	BaseClass baseplayer = BaseClass(client);
	hPlayerFields[client].SetValue("iPresetType", None);
	baseplayer.iClassType = None;
	// Just to prevent limit from glitching out
}

public void OnMapStart()
{
	PrecacheSound(SOUND_RECHARGE, true);
#if defined _vsh2_included
	if(g_vsh2)
		VSH2_Hook(OnRedPlayerThink, VSH2_BaseThink);
	else
		CreateTimer(0.1, BaseThink, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
#endif
#if !defined _vsh2_included
	CreateTimer(0.1, BaseThink, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
#endif
}

public void OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if(!bEnabled.BoolValue)
		return;
	BaseClass baseplayer = BaseClass(GetEventInt(event,"userid"), true);
	if(!IsValidClient(baseplayer.index)) {
		return;
	}
	float mercpos[3];
	GetClientAbsOrigin(baseplayer.index, mercpos);
	char medSound[35];
	switch(baseplayer.iClassType) {
		case None: {}
		case Wizard: {
			Format(medSound, sizeof(medSound), "vo/merasmus/round_begin0%i.mp3", GetRandomInt(1, 4));
			EmitSoundToAll(medSound, baseplayer.index, _, _, _, 0.5, _, _, mercpos, _, false);
		}
	}
}

public void OnRoundEnd(Event event, const char[] name, bool dontBroadcast)
{
}

public Action OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if(!bEnabled.BoolValue)
		return Plugin_Continue;
	
	BaseClass baseplayer = BaseClass(GetEventInt(event,"userid"), true);

	if(!IsValidClient(baseplayer.index)) {
		return Plugin_Continue;
	}

	baseplayer.iClassType = None;
	
#if defined _FF2_included
	if(FF2_GetBossIndex(baseplayer.index) != -1) // Check if our user isn't a boss
		return Plugin_Continue;
	
	// Future warning, might remove this due to the forward handling this
	if(FF2_GetRoundState() == 1) // Flipping logic around, don't set custom classes during round due to minions and class scrambling. Call BTCBase.Convert() instead mid-round.
		return Plugin_Continue;
#endif

#if defined _vsh2_included
	if(VSH2Player(baseplayer.index).GetPropInt("iBossType") > -1)
		return Plugin_Continue;
	
	// See FF2 note above
	if(VSH2GameMode_GetProperty("iRoundState") == StateRunning)
		return Plugin_Continue;
#endif
	
	BTCClass iPreset = baseplayer.iPresetType;

	Action action = Plugin_Continue;
	Call_StartForward(forwardBTC[OnSpawn]);
	Call_PushCell(baseplayer.index);
	Call_PushCellRef(view_as<int>(iPreset));
	Call_Finish(action);

	if(action > Plugin_Continue) {
		return Plugin_Continue;
	}

	TF2Attrib_RemoveAll(baseplayer.index);
	
	switch(baseplayer.iPresetType) {
		case None: {
			baseplayer.iClassType = None;
			SetVariantString("");
			AcceptEntityInput(baseplayer.index, "SetCustomModel");
		}
		case Wizard: {
			if( CalcLimit(Wizard) < cvarBTC[WizardLimit].IntValue ) {
				baseplayer.iClassType = Wizard;
				ToCWizard(baseplayer).OnSpawn();
			}
		}
		case Mercenary: {
			if( CalcLimit(Mercenary) < cvarBTC[MercenaryLimit].IntValue ) {
				baseplayer.iClassType = Mercenary;
				ToCMercenary(baseplayer).OnSpawn();
			}
		}
		default: { // In case we're going out of index
			baseplayer.iPresetType = None;
			baseplayer.iClassType = None;
			SetVariantString("");
			AcceptEntityInput(baseplayer.index, "SetCustomModel");
		}
	}
	return Plugin_Continue;
}

public Action OnPlayerDeath(Event event, const char[] eventName, bool dontBroadcast)
{
	if(!bEnabled.BoolValue)
		return Plugin_Continue;
	BaseClass victim = BaseClass(GetEventInt(event, "userid"), true);
	BaseClass attacker = BaseClass(GetEventInt(event, "attacker"), true);
	TF2Attrib_RemoveAll(victim.index); // For safety
	switch(victim.iClassType) {
		case None:		{}
		case Wizard:	ToCWizard(victim).OnDeath(attacker, victim, event);
		case Mercenary:	ToCMercenary(victim).OnDeath(attacker, victim, event);
	}
	switch(attacker.iClassType) { // For changing event values
		case None:		{}
		case Wizard:	ToCWizard(attacker).OnKill(attacker, victim, event);
		case Mercenary:	ToCMercenary(victim).OnKill(attacker, victim, event);
	}
	return Plugin_Continue;
}

public Action OnPlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	if(!bEnabled.BoolValue)
		return Plugin_Continue;
	BaseClass victim = BaseClass(event.GetInt("userid"), true);
	BaseClass attacker = BaseClass(event.GetInt("attacker"), true);
	if(IsValidClient(victim.index)) { // Fix bots playing Wizard sounds
		switch(victim.iClassType) {
			case None:	{}
			case Wizard: {
				ToCWizard(victim).OnHurt(attacker, victim, event);
			}
		}
	}
	if(IsValidClient(attacker.index)) {
		switch(attacker.iClassType) {
			case None:		{}
			case Wizard:	{
				ToCWizard(attacker).OnDamage(attacker, victim, event);
			}
		}
	}
	return Plugin_Continue;
}

public Action OnChangeClass(Event event, const char[] eventName, bool dontBroadcast)
{
	if(!bEnabled.BoolValue)
		return Plugin_Continue;
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	BaseClass baseplayer = BaseClass(client);
	if(baseplayer.iPresetType > None) {
		baseplayer.iPresetType = None;
		PrintToChat(baseplayer.index, "\x01\x070066BB[BeTheClass]\x01 Reset selection due to class change.");
	}
	return Plugin_Continue;
}

public Action OnJoinClass(int client, const char[] command, int argc)
{
	if(!bEnabled.BoolValue)
		return Plugin_Continue;
	char str_tfclass[20];
	GetCmdArg(1, str_tfclass, sizeof(str_tfclass));
	TFClassType classtype = TF2_GetClass(str_tfclass);
	SetEntProp(client, Prop_Send, "m_iDesiredPlayerClass", view_as<int>(classtype));
	BaseClass baseplayer = BaseClass(client);
	if(baseplayer.iPresetType > None) {
		baseplayer.iPresetType = None;
		PrintToChat(baseplayer.index, "\x01\x070066BB[BeTheClass]\x01 Reset selection due to class change.");
	}
	return Plugin_Continue;
}

public Action OnItemPickUp(Event event, const char[] eventName, bool dontBroadcast)
{
	if(!bEnabled.BoolValue)
		return Plugin_Continue;
	BaseClass baseplayer = BaseClass(GetEventInt(event, "userid"), true);
	char item[64];
	GetEventString(event, "item", item, sizeof(item));
	switch(baseplayer.iClassType) {
		case None:		{}
		case Mercenary:	ToCMercenary(baseplayer).OnItemPickUp(baseplayer, item, event);
	}
	return Plugin_Continue;
}

public Action BaseThink(Handle hTimer)
{
	if(!bEnabled.BoolValue)
		return Plugin_Continue;

	BaseClass baseplayer;
	for( int i=MaxClients ; i > 0 ; i-- ) { // Begin iterating over all players every 0.1s, less memory intense than calling up to 24-32 timers
		if( !IsValidClient(i) )
			continue;

		baseplayer = BaseClass(i);
		switch(baseplayer.iClassType) {
			case None:		{}
			case Wizard:	ToCWizard(baseplayer).Think();
			case Mercenary:	ToCMercenary(baseplayer).Think();
		}
	}
	return Plugin_Continue;
}

#if defined _vsh2_included
public Action VSH2_BaseThink(const VSH2Player player)
{
	if(!g_vsh2)
		return Plugin_Continue;
	
	if(!bEnabled.BoolValue)
		return Plugin_Continue;
	
	baseplayer = BaseClass(player.index)
	switch(baseplayer.iClassType) {
		case None:		{}
		case Wizard:	ToCWizard(baseplayer).Think();
		case Mercenary:	ToCMercenary(baseplayer).Think();
	}
}
#endif

public int CalcLimit(BTCClass iClass)
{
	int total;
	for( int i=MaxClients ; i > 0 ; i-- ) {
		if(BaseClass(i).iClassType == iClass && IsValidClient(i))
			total++;
	}
	return total;
}

// TF2 event handling
public void TF2_OnConditionAdded(int iClient, TFCond condition)
{
	if(!bEnabled.BoolValue)
		return;
	BaseClass baseplayer = BaseClass(iClient);
	switch(baseplayer.iClassType) {
		case None:	{}
		case Wizard:	ToCWizard(baseplayer).OnConditionAdded(condition);
		case Mercenary:	ToCMercenary(baseplayer).OnConditionAdded(condition);
	}
}
public void TF2_OnConditionRemoved(int iClient, TFCond condition)
{
	if(!bEnabled.BoolValue)
		return;
	BaseClass baseplayer = BaseClass(iClient);
	switch(baseplayer.iClassType) {
		case None:	{}
		case Wizard:	{
			if(condition == TFCond_Stealthed) {
				ToCWizard(baseplayer).fInvisBonus = 0.8;
			}
		}
	}
}

public Action OnPickup(client, entity) {
	if(!IsValidClient(client))
		return Plugin_Continue;
	char classname[32];
	GetEdictClassname(entity, classname, sizeof(classname));
	BaseClass baseplayer = BaseClass(client);
	switch(baseplayer.iClassType) {
		case None:		{}
		case Wizard:	{
			if(StrContains(classname, "item_ammopack")!=-1 || StrEqual(classname, "tf_ammo_pack"))
				return Plugin_Handled;
		}
		case Mercenary:	{}
	}
	return Plugin_Continue;
}

// Voicemenu handling
public Action OnVoiceMenu(int iClient, const char[] command, int argc)
{
	if(!bEnabled.BoolValue)
		return Plugin_Continue;
	if(!IsValidClient(iClient) || argc < 2)
		return Plugin_Handled;
	char szCmd1[8]; GetCmdArg(1, szCmd1, sizeof(szCmd1));
	char szCmd2[8]; GetCmdArg(2, szCmd2, sizeof(szCmd2));
	BaseClass baseplayer = BaseClass(iClient)
	switch(baseplayer.iClassType)
	{
		case None:		return Plugin_Continue;
		case Wizard:	ToCWizard(baseplayer).OnVoiceMenu(szCmd1, szCmd2);
		case Mercenary:	ToCMercenary(baseplayer).OnVoiceMenu(szCmd1, szCmd2);
	}
	return Plugin_Handled;
}

// Sound block
public Action HookSound(int clients[64], int& numClients, char sound[PLATFORM_MAX_PATH], int& entity, int& channel, float& volume, int& level, int& pitch, int& flags, char soundEntry[PLATFORM_MAX_PATH], int& seed)
{
	if(!bEnabled.BoolValue || !IsValidClient(entity) || channel<1)
	{
		return Plugin_Continue;
	}
	if(channel==SNDCHAN_VOICE)
	{
		switch(BaseClass(entity).iClassType)
		{
			case None:		{}
			case Wizard:	return Plugin_Stop;
			case Mercenary:	{
				if(StrEqual(sound, "vo/soldier_sf13_spell_generic04.mp3", false))
					return Plugin_Stop;
			}
		}
	}
	return Plugin_Continue;
}

// Menu handling
public Action CommandCreateClassMenu(int iClient, int args)
{
	if(!bEnabled.BoolValue)
		return Plugin_Continue;
	if(IsValidClient(iClient))
	{
		CreateClassMenu(iClient); // Just pass the client
	}
	return Plugin_Handled;
}

public Action CreateClassMenu(int iClient)
{
	Menu classMenu = new Menu(MenuHandler_PickClass);
	classMenu.SetTitle("Class selection menu: ");
	// More flexible menu selection values
	// ToDo, make this easier to work with
	char buffer[16];
	IntToString(view_as<int>(None), buffer, sizeof(buffer));
	classMenu.AddItem(buffer, "None");
	IntToString(view_as<int>(Wizard), buffer, sizeof(buffer));
	classMenu.AddItem(buffer, "Wizard");
	IntToString(view_as<int>(Mercenary), buffer, sizeof(buffer));
	classMenu.AddItem(buffer, "Mercenary");
	classMenu.ExitButton = true;
	classMenu.Display(iClient, 30);
	return Plugin_Handled;
}

public int MenuHandler_PickClass(Menu menu, MenuAction action, int param1, int param2) 
{
	if(action == MenuAction_Select) {
		BaseClass baseplayer = BaseClass(param1); // Param1 is always the client in this case
		char selection[16];
		menu.GetItem(param2, selection, sizeof(selection)); // TF2 spaghetti logic, selection has to be converted to a string first
		baseplayer.iPresetType = view_as<BTCClass>(StringToInt(selection));
		PrintToChat(baseplayer.index, "\x01\x070066BB[BeTheClass]\x01 Selection set.");
	}
	else if(action == MenuAction_End) {
		delete menu; // Just in case for other menus so we don't conflict
	}
}

public Action CommandForceClass(int iClient, int args)
{
	char arg1[32];
	if(args < 1)
	{
		arg1 = "@me";
	}
	else GetCmdArg(1, arg1, sizeof(arg1));
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;

	if ((target_count = ProcessTargetString(
					arg1,
					iClient,
					target_list,
					MaxClients,
					COMMAND_FILTER_ALIVE,
					target_name,
					sizeof(target_name),
					tn_is_ml)) <= 0)
	{
		ReplyToTargetError(iClient, target_count);
		return Plugin_Handled;
	}

	char arg2[32];
	if(args < 2)
	{
		ReplyToCommand(iClient, "[BTC] Usage: sm_forceclass @target index");
		return Plugin_Handled;
	}
	else GetCmdArg(2, arg2, sizeof(arg2));
	int type = StringToInt(arg2);
	for (int i = 0; i < target_count; i++)
	{
		BaseClass baseplayer = BaseClass(target_list[i]);
		TF2Attrib_RemoveAll(baseplayer.index);
		SetVariantString("");
		AcceptEntityInput(baseplayer.index, "SetCustomModel");
		switch(type) {
			case None: {
				baseplayer.iClassType = None;
			}
			case Undefined: {
				baseplayer.iClassType = Undefined;
			}
			case Wizard: {
				baseplayer.iClassType = Wizard;
				ToCWizard(baseplayer).OnSpawn();
			}
			case Mercenary: {
				baseplayer.iClassType = Mercenary;
				ToCMercenary(baseplayer).OnSpawn();
			}
			default: {
				ReplyToCommand(iClient, "[BTC] Invalid class index %i given", type);
			}
		}
		LogAction(iClient, target_list[i], "\"%L\" set \"%L\"'s class to index %i!", iClient, target_list[i], type);
	}
	return Plugin_Handled;
}

public bool TraceEntityFilterPlayer(entity, contentsMask)
{
	return entity > MaxClients || !entity;
}

// SDK calls
void SDK_PlaySpecificSequence(int client, const char[] strSequence)
{
	if(g_hSDKPlaySpecificSequence != INVALID_HANDLE)
	{
		SDKCall(g_hSDKPlaySpecificSequence, client, strSequence);
	}
}

int SDK_GetMaxAmmo(int client, int iSlot)
{
	int iWeapon = GetPlayerWeaponSlot(client, iSlot);
	int iAmmoType = GetEntProp(iWeapon, Prop_Send, "m_iPrimaryAmmoType");
	if(g_hSDKGetMaxAmmo != INVALID_HANDLE && iAmmoType > -1)
		return SDKCall(g_hSDKGetMaxAmmo, client, iAmmoType, -1);
	
	return -1;
}