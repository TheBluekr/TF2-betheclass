/**
 * This one is for you Athena
 * I am not going to integrate certain things into set of plugins as other communities might use it as a vanilla version
 */

#include <sourcemod>
#include <betheclass>
#include <tf2>

#define PLUGIN_VERSION "0.0.1"

public Plugin myinfo =
{
	name = "Be The Class Hub shop integration",
	author = "TheBluekr",
	description = "VSPR Shop integration",
	version = PLUGIN_VERSION,
	url = "https://git.thebluekr.nl/vspr/be-the-class"
};

public void OnPluginStart() {
	RegConsoleCmd("sm_merc", CommandMerc, "Usage: sm_merc");
	RegConsoleCmd("sm_wizard", CommandWizard, "Usage: sm_wizard");
}

public Action CommandMerc(int iClient, int args) {
	char arg1[32];
	GetCmdArg(1, arg1, sizeof(arg1));
	int target = FindTarget(client, arg1);
	if(target == -1)
		return Plugin_Handled;
	StringMap map = BTC_GetClassIDs();
	int mercID;
	if(!map.GetValue("mercenary", mercID)) /// First limitation of command, can't respond with error codes to another plugin invoking said command as with natives
		delete map;
		return Plugin_Handled;
	delete map;
	BTCBaseClass player = BTCBaseClass(iClient);
	SetClassPreset(player, mercID);
	return Plugin_Handled;
}

public Action CommandWizard(int iClient, int args) {
	char arg1[32];
	GetCmdArg(1, arg1, sizeof(arg1));
	int target = FindTarget(client, arg1);
	if(target == -1)
		return Plugin_Handled;
	StringMap map = BTC_GetClassIDs();
	int wizardID;
	if(!map.GetValue("wizard", wizardID)) /// First limitation of command, can't respond with error codes to another plugin invoking said command as with natives
		delete map;
		return Plugin_Handled;
	delete map;
	BTCBaseClass player = BTCBaseClass(iClient);
	SetClassPreset(player, wizardID);
	return Plugin_Handled;
}

public void SetClassPreset(BTCBaseClass player, int index) {
	player.SetPropInt("iPresetType", index);
	TF2_RespawnPlayer(player.index);
	SetPawnTimer(ResetClassPreset, 0.2, player);
}

public void ResetClassPreset(BTCBaseClass player) {
	player.SetPropInt("iPresetType", 0);
}

stock bool IsValidClient(int clientIdx, bool isPlayerAlive=false) {
	if (clientIdx <= 0 || clientIdx > MaxClients) return false;
	if(isPlayerAlive) return IsClientInGame(clientIdx) && IsPlayerAlive(clientIdx);
	return IsClientInGame(clientIdx);
}

stock void SetPawnTimer(Function func, float thinktime = 0.1, any param1 = -999, any param2 = -999)
{
	DataPack thinkpack = new DataPack();
	thinkpack.WriteFunction(func);
	thinkpack.WriteCell(param1);
	thinkpack.WriteCell(param2);

	CreateTimer(thinktime, DoThink, thinkpack, TIMER_DATA_HNDL_CLOSE);
}

public Action DoThink(Handle hTimer, DataPack hndl)
{
	hndl.Reset();

	Function pFunc = hndl.ReadFunction();
	Call_StartFunction( null, pFunc );

	any param1 = hndl.ReadCell();
	if ( param1 != -999 )
		Call_PushCell(param1);

	any param2 = hndl.ReadCell();
	if ( param2 != -999 )
		Call_PushCell(param2);

	Call_Finish();
	return Plugin_Continue;
}