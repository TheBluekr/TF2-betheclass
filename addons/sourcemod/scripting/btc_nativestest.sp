#include <sourcemod>
#include <morecolors>
#undef REQUIRE_PLUGIN
#include <betheclass>
#define REQUIRE_PLUGIN

// Edited from Assyrianic's VSH2 native tests

#pragma semicolon		1
#pragma newdecls		required

public Plugin myinfo = {
	name = "btc_natives_tester",
	author = "TheBluekr",
	description = "plugin for testing btc natives",
	version = "1.0",
	url = "http://www.sourcemod.net/"
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_testbtcnatives", CommandInfo, "clever command explanation heer.");
	RegConsoleCmd("sm_btcblock", CommandBlock, "");
}

public Action CommandInfo(int client, int args)
{	
	PrintToConsole(client, "calling natives command");
	BTCBase player = BTCBase(client);
	if (player) {
		PrintToConsole(client, "BTCBase methodmap Constructor is working");
		PrintToConsole(client, "player.index = %d | player.userid = %d", player.index, player.userid);
		int class = player.GetProperty("iClassType");
		char number[4]; GetCmdArg(1, number, sizeof(number));
		int index = StringToInt(number);
		player.Convert(index);
		int class_status = player.GetProperty("iClassType");
		PrintToConsole(client, "players class %i -> %i", class, class_status);
	}
	return Plugin_Handled;
}

public Action CommandBlock(int client, int args)
{
	PrintToConsole(client, "attempting to call block");
	BTCBase player = BTCBase(client);
	if(player) {
		bool bBlock = player.GetProperty("bIsMinion");
		char val[4]; GetCmdArg(1, val, sizeof(val));
		bool block = view_as<bool>(StringToInt(val));
		player.bIsMinion = block;
		bool bBlock2 = player.GetProperty("bIsMinion");
		PrintToConsole(client, "players block %i -> %i", bBlock, bBlock2);
	}
	return Plugin_Handled;
}