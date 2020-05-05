#include <sourcemod>
#include <betheclass>

#define PLUGIN_VERSION "0.0.1"

public Plugin myinfo =
{
	name = "Be The Class Hub nativetest",
	author = "TheBluekr",
	description = "Testing BeTheClass natives",
	version = PLUGIN_VERSION,
	url = "https://git.thebluekr.nl/vspr/be-the-class"
};

public void OnPluginStart() {
	RegConsoleCmd("sm_btc_test", CommandCreateMenu, "Usage: sm_btc_test");
}

public Action CommandCreateMenu(int client, int args) {
	CreateClassMenu(client);
	return Plugin_Handled;
}

public void CreateClassMenu(int client) {
	Menu classMenu = new Menu(MenuHandler_Pick);
	classMenu.SetTitle("Loaded custom classes:");
	classMenu.ExitButton = true;

	BTC_ClassMenu(classMenu);

	classMenu.Display(client, 30);
}

public int MenuHandler_Pick(Menu menu, MenuAction action, int param1, int param2) {
	if(action == MenuAction_Select) {
		char selection[16];
		menu.GetItem(param2, selection, sizeof(selection));
		PrintToChat(param1, "\x01\x070066BB[BeTheClass]\x01 Selection index %i.", StringToInt(selection));
	}
	else if(action == MenuAction_End) {
		delete menu;
	}
}