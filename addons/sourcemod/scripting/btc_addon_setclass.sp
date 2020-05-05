#include <sourcemod>
#include <betheclass>

#define PLUGIN_VERSION "0.0.1"

public Plugin myinfo =
{
	name = "Be The Class Hub set class",
	author = "TheBluekr",
	description = "Set your class to a custom one!",
	version = PLUGIN_VERSION,
	url = "https://git.thebluekr.nl/vspr/be-the-class"
};

public void OnPluginStart() {
	RegConsoleCmd("sm_class", CommandCreateClassMenu, "Usage: sm_class");
}

/// Menu handling
public Action CommandCreateClassMenu(int iClient, int args) {
	if(IsValidClient(iClient))
	{
		CreateClassMenu(iClient); // Just pass the client
	}
	return Plugin_Handled;
}

public void CreateClassMenu(int iClient) {
	Menu classMenu = new Menu(MenuHandler_PickClass);
	classMenu.SetTitle("Class selection menu: ");
	// More flexible menu selection values
	// ToDo, make this easier to work with
	char buffer[16];
	IntToString(0, buffer, sizeof(buffer));
	classMenu.AddItem(buffer, "None");
	classMenu.ExitButton = true;

	BTC_ClassMenu(classMenu);

	classMenu.Display(iClient, 30);
}

public int MenuHandler_PickClass(Menu menu, MenuAction action, int param1, int param2) {
	if(action == MenuAction_Select) {
		BTCBaseClass player = BTCBaseClass(param1); /// Param1 is always the client in this case
		char selection[16];
		menu.GetItem(param2, selection, sizeof(selection));
		player.SetPropInt("iPresetType", StringToInt(selection));
		PrintToChat(player.index, "\x01\x070066BB[BeTheClass]\x01 Selection set.");
	}
	else if(action == MenuAction_End) {
		delete menu;
	}
}

stock bool IsValidClient(int clientIdx, bool isPlayerAlive=false) {
	if (clientIdx <= 0 || clientIdx > MaxClients) return false;
	if(isPlayerAlive) return IsClientInGame(clientIdx) && IsPlayerAlive(clientIdx);
	return IsClientInGame(clientIdx);
}