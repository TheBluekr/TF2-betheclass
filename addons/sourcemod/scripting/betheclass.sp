#include <sourcemod>
#include <betheclass>
#include <tf2items>
#include <clientprefs>
#include <vsh2>

#define PLYR           35
#define PLUGIN_VERSION "0.0.1"

public Plugin myinfo =
{
	name = "VSH2 Be The Class Hub addon",
	author = "TheBluekr",
	description = "Set the player's class to any of the custom classes!",
	version = PLUGIN_VERSION,
	url = "https://git.thebluekr.nl/vspr/be-the-class"
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
			if(!this.index)
				return -1;
			int i; g_btc.m_hPlayerFields[this.index].GetValue("iPresetType", i);
			return i;
		}
		public set(const int val)
		{
			int player = this.index;
			if( !player )
				return;
			g_btc.m_hPlayerFields[player].SetValue("iPresetType", val);
		}
	}
	property int iClassType {
		public get()
		{
			if(!this.index)
				return -1;
			int i; g_btc.m_hPlayerFields[this.index].GetValue("iClassType", i);
			return i;
		}
		public set(const int val)
		{
			int player = this.index;
			if( !player )
				return;
			g_btc.m_hPlayerFields[player].SetValue("iClassType", val);
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
}

public void OnPluginStart() {
	g_btc.m_hForwards[OnCallDownload] = new PrivateForward( ET_Event );
	g_btc.m_hForwards[OnPlayerThink] = new PrivateForward( ET_Event, Param_Cell );

	g_btc.m_hPlayerFields[0] = new StringMap();
	g_btc.m_hClassesRegistered = new ArrayList(sizeof(ClassModule));
}

public void OnLibraryAdded(const char[] name) {
	if( StrEqual(name, "VSH2") ) {
		RegConsoleCmd("sm_class", CommandCreateClassMenu, "Usage: sm_class");
		//RegAdminCmd("sm_forceclass", CommandForceClass, ADMFLAG_GENERIC, "Usage: sm_forceclass @target index");
	}
}

public void OnClientPutInServer(int client)
{
	BaseClass baseplayer = BaseClass(client);
	baseplayer.iPresetType = 0;
}

public void OnClientDisconnect(int client)
{
	BaseClass baseplayer = BaseClass(client);
	baseplayer.iPresetType = 0;
	baseplayer.iClassType = 0;
	/// Just to prevent limit from glitching out
}

public void OnMapStart()
{
	Action act;
	Call_StartForward(g_btc.m_hForwards[OnCallDownloads]);
	Call_Finish(act);
	
	CreateTimer(0.1, Timer_PlayerThink, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_PlayerThink(Handle hTimer)
{
	// if(VSH2GameMode_GetPropInt("iRoundState") == StateRunning
	if(GameRules_GetRoundState() != RoundState_RoundRunning)
		return Plugin_Continue;
	
	BaseClass player;
	for(int i=MaxClients; i; --i) {
		if(!IsValidClient(i, false))
			continue;
		
		player = BaseClass(i);

		Action act;
		Call_StartForward(g_btc.m_hForwards[OnPlayerThink]);
		Call_PushCell(player);
		Call_Finish(act);
	}
	
	return Plugin_Continue;
}

/// Menu handling
public Action CommandCreateClassMenu(int iClient, int args)
{
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
	IntToString(0, buffer, sizeof(buffer));
	classMenu.AddItem(buffer, "None");
	classMenu.ExitButton = true;

	Call_StartForward(g_btc.m_hForwards[OnClassMenu]);
	Call_PushCellRef(classMenu);
	Call_Finish();

	classMenu.Display(iClient, 30);
	return Plugin_Handled;
}

public int MenuHandler_PickClass(Menu menu, MenuAction action, int param1, int param2) 
{
	if(action == MenuAction_Select) {
		BaseClass baseplayer = BaseClass(param1); /// Param1 is always the client in this case
		char selection[16];
		menu.GetItem(param2, selection, sizeof(selection));
		baseplayer.iPresetType = StringToInt(selection);
		PrintToChat(baseplayer.index, "\x01\x070066BB[BeTheClass]\x01 Selection set.");
	}
	else if(action == MenuAction_End) {
		delete menu;
	}
}

/// Shamelessly using this from VSH2, nice code Assyrianic
public int RegisterClass(Handle plugin, const char modulename[MAX_CLASS_NAME_SIZE])
{
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
			return i + 1;
		}
	}
	
	/// Couldn't find boss of the name at all, assume it's a brand new boss being reg'd.
	ClassModule module;
	module.name = modulename;
	module.plugin = plugin;
	g_btc.m_hClassesRegistered.PushArray(module, sizeof(module));
	return g_btc.m_hClassesRegistered.Length + 1;
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("BTC_RegisterPlugin", Native_RegisterClass);

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

	RegPluginLibrary("BTC");
	return APLRes_Success;
}

public int Native_RegisterClass(Handle plugin, int numParams)
{
	char module_name[MAX_CLASS_NAME_SIZE]; GetNativeString(1, module_name, sizeof(module_name));
	/// ALL PROPS TO COOKIES.NET AKA COOKIES.IO
	return RegisterClass(plugin, module_name);
}

public any Native_BTC_Instance(Handle plugin, int numParams)
{
	BaseClass player = BaseClass(GetNativeCell(1), GetNativeCell(2));
	return player;
}

public int Native_BTC_GetUserid(Handle plugin, int numParams)
{
	BaseClass player = GetNativeCell(1);
	return player.userid;
}
public int Native_BTC_GetIndex(Handle plugin, int numParams)
{
	BaseClass player = GetNativeCell(1);
	return player.index;
}

public int Native_BTC_getPropInt(Handle plugin, int numParams)
{
	BaseClass player = GetNativeCell(1);
	char prop_name[64]; GetNativeString(2, prop_name, 64);
	int item;
	if( g_btc.m_hPlayerFields[player.index].GetValue(prop_name, item) )
		return item;
	return 0;
}
public int Native_BTC_setPropInt(Handle plugin, int numParams)
{
	BaseClass player = GetNativeCell(1);
	char prop_name[64]; GetNativeString(2, prop_name, 64);
	int item = GetNativeCell(3);
	return g_btc.m_hPlayerFields[player.index].SetValue(prop_name, item);
}

public any Native_BTC_getPropFloat(Handle plugin, int numParams)
{
	BaseClass player = GetNativeCell(1);
	char prop_name[64]; GetNativeString(2, prop_name, 64);
	float item;
	if( g_btc.m_hPlayerFields[player.index].GetValue(prop_name, item) )
		return item;
	return 0;
}
public int Native_BTC_setPropFloat(Handle plugin, int numParams)
{
	BaseClass player = GetNativeCell(1);
	char prop_name[64]; GetNativeString(2, prop_name, 64);
	float item = GetNativeCell(3);
	return g_btc.m_hPlayerFields[player.index].SetValue(prop_name, item);
}

public int Native_BTC_getProperty(Handle plugin, int numParams)
{
	BaseClass player = GetNativeCell(1);
	char prop_name[64]; GetNativeString(2, prop_name, 64);
	any item;
	if( g_btc.m_hPlayerFields[player.index].GetValue(prop_name, item) )
		return item;
	return 0;
}
public int Native_BTC_setProperty(Handle plugin, int numParams)
{
	BaseClass player = GetNativeCell(1);
	char prop_name[64]; GetNativeString(2, prop_name, 64);
	any item = GetNativeCell(3);
	return g_btc.m_hPlayerFields[player.index].SetValue(prop_name, item);
}

public int Native_Hook(Handle plugin, int numParams)
{
	int btcHook = GetNativeCell(1);
	Function Func = GetNativeFunction(2);
	if( g_btc.m_hForwards[btcHook] != null )
		g_btc.m_hForwards[btcHook].AddFunction(plugin, Func);
}
public int Native_HookEx(Handle plugin, int numParams)
{
	int btcHook = GetNativeCell(1);
	Function Func = GetNativeFunction(2);
	if( g_btc.m_hForwards[btcHook] != null )
		return g_btc.m_hForwards[btcHook].AddFunction(plugin, Func);
	return 0;
}

public int Native_Unhook(Handle plugin, int numParams)
{
	int btcHook = GetNativeCell(1);
	if( g_btc.m_hForwards[btcHook] != null )
		g_btc.m_hForwards[btcHook].RemoveFunction(plugin, GetNativeFunction(2));
}
public int Native_UnhookEx(Handle plugin, int numParams)
{
	int btcHook = GetNativeCell(1);
	if( g_btc.m_hForwards[btcHook] != null )
		return g_btc.m_hForwards[btcHook].RemoveFunction(plugin, GetNativeFunction(2));
	return 0;
}

public int Native_BTC_SpawnWep(Handle plugin, int numParams)
{
	BaseClass player = GetNativeCell(1);
	char classname[64]; GetNativeString(2, classname, 64);
	int itemindex = GetNativeCell(3);
	int level = GetNativeCell(4);
	int quality = GetNativeCell(5);
	char attributes[128]; GetNativeString(6, attributes, 128);
	return player.SpawnWeapon(classname, itemindex, level, quality, attributes);
}

public int Native_BTC_RemoveAllItems(Handle plugin, int numParams)
{
	BaseClass player = GetNativeCell(1);
	bool weps = numParams <= 1 ? true : GetNativeCell(2);
	player.RemoveAllItems(weps);
}

stock bool ValidateName(const char[] name)
{
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

stock bool IsValidClient(int clientIdx, bool isPlayerAlive=false)
{
	if (clientIdx <= 0 || clientIdx > MaxClients) return false;
	if(isPlayerAlive) return IsClientInGame(clientIdx) && IsPlayerAlive(clientIdx);
	return IsClientInGame(clientIdx);
}

stock int GetOwner(const int ent)
{
	return( IsValidEntity(ent) ) ? GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity") : -1;
}