#include <sourcemod>
#include <betheclass>
#include <tf2items>
#include <tf2attributes>
#include <clientprefs>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>

#define PLYR           35
#define PLUGIN_VERSION "0.0.1"

public Plugin myinfo =
{
	name = "Be The Class Hub core",
	author = "TheBluekr",
	description = "Set the player's class to any of the custom classes!",
	version = PLUGIN_VERSION,
	url = "https://github.com/TheBluekr/TF2-betheclass"
};

enum {
	ClassPreset,
	MaxBTCCookies
};

enum struct ClassModule {
	char name[MAX_CLASS_NAME_SIZE];
	Handle plugin;
}

enum struct BTCGlobals {
	ArrayList m_hClassesRegistered;
	Cookie m_hCookies[MaxBTCCookies];
	PrivateForward m_hForwards[MaxBTCForwards];
	StringMap m_hPlayerFields[PLYR];
}

BTCGlobals g_btc;

methodmap BaseClass
{
	public BaseClass(const int ind, bool uid=false)
	{
		int player=0;	// If you're using a userid and you know 100% it's valid, then set uid to true
		if( uid && GetClientOfUserId(ind) > 0 )
			player = (ind);
		else if( IsValidClient(ind) )
			player = GetClientUserId(ind);
		return view_as< BaseClass >( player );
	}

	property int userid {
		public get() { return view_as< int >(this); }
	}
	property int index {
		public get() { return GetClientOfUserId( view_as< int >(this) ); }
	}

	property int iPresetType {
		public get()
		{
			int i; g_btc.m_hPlayerFields[this.index].GetValue("iPresetType", i);
			return i;
		}
		public set(const int val)
		{
			g_btc.m_hPlayerFields[this.index].SetValue("iPresetType", val);
		}
	}
	property int iClassType {
		public get()
		{
			int i; g_btc.m_hPlayerFields[this.index].GetValue("iClassType", i);
			return i;
		}
		public set(const int val)
		{
			g_btc.m_hPlayerFields[this.index].SetValue("iClassType", val);
		}
	}
	property bool bPreventSpawn {
		public get()
		{
			bool b; g_btc.m_hPlayerFields[this.index].GetValue("bPreventSpawn", b);
			return b;
		}
		public set(const bool val) {
			g_btc.m_hPlayerFields[this.index].SetValue("bPreventSpawn", b);
		}
	}

	public int SpawnWeapon(char[] name, const int index, const int level, const int qual, char[] att)
	{
		TF2Item hWep = new TF2Item(OVERRIDE_ALL|FORCE_GENERATION);
		if( !hWep )
			return -1;
		
		hWep.SetClassname(name);
		hWep.iItemIndex = index;
		hWep.iLevel = level;
		hWep.iQuality = qual;
		char atts[32][32];
		int count = ExplodeString(att, "; ", atts, 32, 32);
		
		/// odd numbered attributes result in an error, remove the 1st bit so count will always be even.
		count &= ~1;
		if( count > 0 ) {
			hWep.iNumAttribs = count / 2;
			int i2=0;
			for( int i=0; i<count; i+=2 ) {
				hWep.SetAttribute( i2, StringToInt(atts[i]), StringToFloat(atts[i+1]) );
				i2++;
			}
		}
		else hWep.iNumAttribs = 0;
		
		int entity = hWep.GiveNamedItem(this.index);
		delete hWep;
		EquipPlayerWeapon(this.index, entity);
		return entity;
	}

	public void RemoveAllItems(bool weps = true) {
		int client = this.index;
		TF2_RemovePlayerDisguise(client);
		
		int ent = -1;
		while( (ent = FindEntityByClassname(ent, "tf_wearabl*")) != -1 ) {
			if( GetOwner(ent) == client ) {
				TF2_RemoveWearable(client, ent);
				AcceptEntityInput(ent, "Kill");
			}
		}
		ent = -1;
		while( (ent = FindEntityByClassname(ent, "tf_powerup_bottle")) != -1 ) {
			if( GetOwner(ent) == client ) {
				TF2_RemoveWearable(client, ent);
				AcceptEntityInput(ent, "Kill");
			}
		}
		if( weps )
			TF2_RemoveAllWeapons(client);
	}

	public void SetOverlay(const char[] strOverlay) {
		int iFlags = GetCommandFlags("r_screenoverlay") & (~FCVAR_CHEAT);
		SetCommandFlags("r_screenoverlay", iFlags);
		ClientCommand(this.index, "r_screenoverlay \"%s\"", strOverlay);
	}
}

public void OnPluginStart() {
	HookEvent("player_spawn", OnSpawn);
	HookEvent("player_death", OnPlayerDeath, EventHookMode_Pre);
	HookEvent("player_hurt", OnPlayerHurt, EventHookMode_Pre);
	HookEvent("post_inventory_application", OnResupply, EventHookMode_Pre);
	HookEvent("teamplay_round_start", RoundStart);
	HookEvent("teamplay_round_win", RoundEnd);

	AddCommandListener(OnJoinClass, "joinclass");
	AddCommandListener(OnJoinClass, "join_class");

	g_btc.m_hForwards[OnCallDownload] = new PrivateForward(ET_Event);
	g_btc.m_hForwards[OnClassThink] = new PrivateForward(ET_Event, Param_Cell);
	g_btc.m_hForwards[OnClassSpawn] = new PrivateForward(ET_Event, Param_Cell, Param_Cell);
	g_btc.m_hForwards[OnClassDeath] = new PrivateForward(ET_Event, Param_Cell, Param_Cell, Param_Cell);
	g_btc.m_hForwards[OnClassHurt] = new PrivateForward(ET_Event, Param_Cell, Param_Cell, Param_Cell);
	g_btc.m_hForwards[OnClassResupply] = new PrivateForward(ET_Event, Param_Cell, Param_Cell);
	g_btc.m_hForwards[OnClassMenu] = new PrivateForward(ET_Event, Param_CellByRef);

	g_btc.m_hPlayerFields[0] = new StringMap();
	g_btc.m_hClassesRegistered = new ArrayList(sizeof(ClassModule));

	LoadTranslations("common.phrases");
	LoadTranslations("btc.phrases");
}

public Action OnSpawn(Event event, const char[] name, bool dontBroadcast) {
	BaseClass player = BaseClass(event.GetInt("userid"), true);
	player.iClassType = 0;
	if(player && IsClientInGame(player.index) && !FF2_GetBossIndex(player.index) && !player.bPreventSpawn) {
		SetVariantString(""); AcceptEntityInput(player.index, "SetCustomModel");
		player.SetOverlay("0");
		
		Action act;
		Call_StartForward(g_btc.m_hForwards[OnClassSpawn]);
		Call_PushCell(player);
		Call_PushCell(event);
		Call_Finish(act);

		if(act > Plugin_Changed)
			return Plugin_Continue;

		TF2Attrib_RemoveAll(player.index);
		TF2_RegeneratePlayer(player.index);
		SetEntityHealth(player.index, GetEntProp(player.index, Prop_Data, "m_iMaxHealth"));
	}
	return Plugin_Continue;
}

public Action OnPlayerDeath(Event event, const char[] name, bool dontBroadcast) {
	BaseClass victim = BaseClass( event.GetInt("userid"), true );
	BaseClass fighter = BaseClass( event.GetInt("attacker"), true );

	Action act;
	Call_StartForward(g_btc.m_hForwards[OnClassDeath]);
	Call_PushCell(fighter);
	Call_PushCell(victim);
	Call_PushCell(event);
	Call_Finish(act);
	if(act > Plugin_Changed) {
		return Plugin_Continue;
	}
	
	return Plugin_Continue;
}

public Action OnPlayerHurt(Event event, const char[] name, bool dontBroadcast) {
	BaseClass victim = BaseClass(event.GetInt("userid"), true);
	BaseClass fighter = BaseClass(event.GetInt("attacker"));

	Action act;
	Call_StartForward(g_btc.m_hForwards[OnClassHurt]);
	Call_PushCell(fighter);
	Call_PushCell(victim);
	Call_PushCell(event);
	Call_Finish(act);
	if(act > Plugin_Changed) {
		return Plugin_Continue;
	}
	return Plugin_Continue;
}

public Action OnResupply(Event event, const char[] name, bool dontBroadcast) {
	BaseClass player = BaseClass(event.GetInt("userid"), true);
	if(!IsValidClient(player.index, true))
		return Plugin_Continue;
	
	Action act;
	Call_StartForward(g_btc.m_hForwards[OnClassResupply]);
	Call_PushCell(player);
	Call_PushCell(event);
	Call_Finish(act);
	if(act > Plugin_Continue) {
		return act;
	}
	return Plugin_Continue;
}

public void OnClientPutInServer(int client) {
	if(g_btc.m_hPlayerFields[client] != null)
		delete g_btc.m_hPlayerFields[client];
	g_btc.m_hPlayerFields[client] = new StringMap();
	g_btc.m_hPlayerFields[client].SetValue("iPresetType", 0);
	g_btc.m_hPlayerFields[client].SetValue("iClassType", 0);
	g_btc.m_hPlayerFields[client].SetValue("bPreventSpawn", false);
}

public void OnClientDisconnect(int client) {
	//BaseClass baseplayer = BaseClass(client);
	g_btc.m_hPlayerFields[client].SetValue("iPresetType", 0);
	g_btc.m_hPlayerFields[client].SetValue("iClassType", 0);
	g_btc.m_hPlayerFields[client].SetValue("bPreventSpawn", false);
}

public void OnMapStart() {
	Call_StartForward(g_btc.m_hForwards[OnCallDownload]);
	Call_Finish();
	
	CreateTimer(0.1, Timer_PlayerThink, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action RoundStart(Event event, const char[] name, bool dontBroadcast) {
}

public Action RoundEnd(Event event, const char[] name, bool dontBroadcast) {
	BaseClass player;
	for(int i=MaxClients; i; i--) {
		if(!IsValidClient(i, false))
			continue;

		player = BaseClass(i);
		player.bPreventSpawn = false;
	}
}

public Action Timer_PlayerThink(Handle hTimer) {
	BaseClass player;
	for(int i=MaxClients; i; i--) {
		if(!IsValidClient(i, false))
			continue;
		
		player = BaseClass(i);

		// Guess player got converted to boss, make sure to correct the type for handling
		if(FF2_GetBossIndex(player.index) && player.iClassType > 0) {
			player.iClassType = 0;
			continue;
		}

		Call_StartForward(g_btc.m_hForwards[OnClassThink]);
		Call_PushCell(player);
		Call_Finish();
	}
	
	return Plugin_Continue;
}

public Action OnJoinClass(int client, const char[] command, int argc) {
	BaseClass player = BaseClass(client);
	if(player.iPresetType > 0) {
		player.iPresetType = 0;
		PrintToChat(player.index, "\x01\x070066BB[BeTheClass]\x01 %T", player.index, "Core_Reset_Class_Change");
	}
	return Plugin_Continue;
}

/// Shamelessly using this from VSH2, nice code Assyrianic
public int RegisterClass(Handle plugin, const char modulename[MAX_CLASS_NAME_SIZE]) {
	if( !ValidateName(modulename) ) {
		LogError("BTC :: Class Registrar: **** Invalid Name For Class Module: '%s' ****", modulename);
		return -1;
	}
	
	for(int i; i < g_btc.m_hClassesRegistered.Length; i++) {
		ClassModule module;
		g_btc.m_hClassesRegistered.GetArray(i, module, sizeof(module));
		/// if we already have a module of the name, let's check if its plugin is valid.
		if( !strcmp(module.name, modulename) ) {
			/// iterate through all plugins and see if it actually exists.
			for( Handle iter=GetPluginIterator(), p=ReadPlugin(iter); MorePlugins(iter); p = ReadPlugin(iter) ) {
				if( p==module.plugin ) {
					LogError("BTC :: Class Registrar: **** Module '%s' Already Registered ****", modulename);
					return -1;
				}
			}
			/// the boss being registered has the same name but it's of a different handle ID?
			/// override its plugin ID then, it was probably reloaded.
			module.plugin = plugin;
			g_btc.m_hClassesRegistered.SetArray(i, module, sizeof(module));
			return i;
		}
	}
	
	/// Couldn't find boss of the name at all, assume it's a brand new boss being reg'd.
	ClassModule module;
	module.name = modulename;
	module.plugin = plugin;
	g_btc.m_hClassesRegistered.PushArray(module, sizeof(module));
	return g_btc.m_hClassesRegistered.Length;
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	CreateNative("BTC_RegisterPlugin", Native_RegisterClass);

	CreateNative("BTC_ClassMenu", Native_ClassMenu);
	CreateNative("BTC_GetClassIDs", Native_GetClassIDs);

	CreateNative("BTC_Hook", Native_Hook);
	CreateNative("BTC_HookEx", Native_HookEx);
	
	CreateNative("BTC_Unhook", Native_Unhook);
	CreateNative("BTC_UnhookEx", Native_UnhookEx);
	
	CreateNative("BTCBaseClass.BTCBaseClass", Native_BTC_Instance);
	CreateNative("BTCBaseClass.userid.get", Native_BTC_GetUserid);
	CreateNative("BTCBaseClass.index.get", Native_BTC_GetIndex);

	CreateNative("BTCBaseClass.GetPropInt", Native_BTC_getPropInt);
	CreateNative("BTCBaseClass.GetPropFloat", Native_BTC_getPropFloat);
	CreateNative("BTCBaseClass.GetPropAny", Native_BTC_getProperty);

	CreateNative("BTCBaseClass.SetPropInt", Native_BTC_setPropInt);
	CreateNative("BTCBaseClass.SetPropFloat", Native_BTC_setPropFloat);
	CreateNative("BTCBaseClass.SetPropAny", Native_BTC_setProperty);

	CreateNative("BTCBaseClass.SpawnWeapon", Native_BTC_SpawnWep);
	CreateNative("BTCBaseClass.RemoveAllItems", Native_BTC_RemoveAllItems);

	RegPluginLibrary("BeTheClass");
	return APLRes_Success;
}

public int Native_RegisterClass(Handle plugin, int numParams) {
	char module_name[MAX_CLASS_NAME_SIZE]; GetNativeString(1, module_name, sizeof(module_name));
	/// ALL PROPS TO COOKIES.NET AKA COOKIES.IO
	return RegisterClass(plugin, module_name);
}

public int Native_ClassMenu(Handle plugin, int numParams) {
	Menu menu = GetNativeCell(1);
	Call_StartForward(g_btc.m_hForwards[OnClassMenu]);
	Call_PushCellRef(menu);
	Call_Finish();
}

public any Native_GetClassIDs(Handle plugin, int numParams) {
	StringMap class_map = new StringMap();
	for(int i; i < g_btc.m_hClassesRegistered.Length; i++) {
		ClassModule class_plugin;
		g_btc.m_hClassesRegistered.GetArray(i, class_plugin, sizeof(class_plugin));
		class_map.SetValue(class_plugin.name, i);
	}
	if(!class_map.Size)
		delete class_map;
	return class_map;
}

public any Native_BTC_Instance(Handle plugin, int numParams) {
	BaseClass player = BaseClass(GetNativeCell(1), GetNativeCell(2));
	return player;
}

public int Native_BTC_GetUserid(Handle plugin, int numParams) {
	BaseClass player = GetNativeCell(1);
	return player.userid;
}
public int Native_BTC_GetIndex(Handle plugin, int numParams) {
	BaseClass player = GetNativeCell(1);
	return player.index;
}

public int Native_BTC_getPropInt(Handle plugin, int numParams) {
	BaseClass player = GetNativeCell(1);
	char prop_name[64]; GetNativeString(2, prop_name, 64);
	int item;
	if( g_btc.m_hPlayerFields[player.index].GetValue(prop_name, item) )
		return item;
	return 0;
}
public int Native_BTC_setPropInt(Handle plugin, int numParams) {
	BaseClass player = GetNativeCell(1);
	char prop_name[64]; GetNativeString(2, prop_name, 64);
	int item = GetNativeCell(3);
	return g_btc.m_hPlayerFields[player.index].SetValue(prop_name, item);
}

public any Native_BTC_getPropFloat(Handle plugin, int numParams) {
	BaseClass player = GetNativeCell(1);
	char prop_name[64]; GetNativeString(2, prop_name, 64);
	float item;
	if( g_btc.m_hPlayerFields[player.index].GetValue(prop_name, item) )
		return item;
	return 0;
}
public int Native_BTC_setPropFloat(Handle plugin, int numParams) {
	BaseClass player = GetNativeCell(1);
	char prop_name[64]; GetNativeString(2, prop_name, 64);
	float item = GetNativeCell(3);
	return g_btc.m_hPlayerFields[player.index].SetValue(prop_name, item);
}

public int Native_BTC_getProperty(Handle plugin, int numParams) {
	BaseClass player = GetNativeCell(1);
	char prop_name[64]; GetNativeString(2, prop_name, 64);
	any item;
	if( g_btc.m_hPlayerFields[player.index].GetValue(prop_name, item) )
		return item;
	return 0;
}
public int Native_BTC_setProperty(Handle plugin, int numParams) {
	BaseClass player = GetNativeCell(1);
	char prop_name[64]; GetNativeString(2, prop_name, 64);
	any item = GetNativeCell(3);
	return g_btc.m_hPlayerFields[player.index].SetValue(prop_name, item);
}

public int Native_Hook(Handle plugin, int numParams) {
	int btcHook = GetNativeCell(1);
	Function Func = GetNativeFunction(2);
	if( g_btc.m_hForwards[btcHook] != null )
		g_btc.m_hForwards[btcHook].AddFunction(plugin, Func);
}
public int Native_HookEx(Handle plugin, int numParams) {
	int btcHook = GetNativeCell(1);
	Function Func = GetNativeFunction(2);
	if( g_btc.m_hForwards[btcHook] != null )
		return g_btc.m_hForwards[btcHook].AddFunction(plugin, Func);
	return 0;
}

public int Native_Unhook(Handle plugin, int numParams) {
	int btcHook = GetNativeCell(1);
	if( g_btc.m_hForwards[btcHook] != null )
		g_btc.m_hForwards[btcHook].RemoveFunction(plugin, GetNativeFunction(2));
}
public int Native_UnhookEx(Handle plugin, int numParams) {
	int btcHook = GetNativeCell(1);
	if( g_btc.m_hForwards[btcHook] != null )
		return g_btc.m_hForwards[btcHook].RemoveFunction(plugin, GetNativeFunction(2));
	return 0;
}

public int Native_BTC_SpawnWep(Handle plugin, int numParams) {
	BaseClass player = GetNativeCell(1);
	char classname[64]; GetNativeString(2, classname, 64);
	int itemindex = GetNativeCell(3);
	int level = GetNativeCell(4);
	int quality = GetNativeCell(5);
	char attributes[128]; GetNativeString(6, attributes, 128);
	return player.SpawnWeapon(classname, itemindex, level, quality, attributes);
}

public int Native_BTC_RemoveAllItems(Handle plugin, int numParams) {
	BaseClass player = GetNativeCell(1);
	bool weps = numParams <= 1 ? true : GetNativeCell(2);
	player.RemoveAllItems(weps);
}

stock bool ValidateName(const char[] name) {
	int length = strlen(name);
	for( int i; i<length; ++i ) {
		int holder = name[i];
		/// Invalid name, names may only contains numbers, underscores, and normal letters.
		if( !(IsCharAlpha(holder) || IsCharNumeric(holder) || holder=='_') )
			return false;
	}
	/// A name is, of course, only valid if it's 1 or more chars long, though longer is recommended
	return (length > 0);
}

stock bool IsValidClient(int clientIdx, bool isPlayerAlive=false) {
	if (clientIdx <= 0 || clientIdx > MaxClients) return false;
	if(isPlayerAlive) return IsClientInGame(clientIdx) && IsPlayerAlive(clientIdx);
	return IsClientInGame(clientIdx);
}

stock int GetOwner(const int ent) {
	return( IsValidEntity(ent) ) ? GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity") : -1;
}