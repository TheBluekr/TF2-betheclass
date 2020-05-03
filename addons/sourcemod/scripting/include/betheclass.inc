#if defined _betheclass_included
	#endinput
#endif
#define _betheclass_included

#include <tf2>
#include <tf2_stocks>
#include <tf2items_stocks>

#define MAX_CLASS_NAME_SIZE    64

methodmap BTCBaseClass {
	public native BTCBaseClass(const int ind, bool uid = false);

	property int userid {
		public native get();
	}
	property int index {
		public native get();
	}

	public native int GetPropInt(const char prop_name[64]);
	public native float GetPropFloat(const char prop_name[64]);
	public native any GetPropAny(const char prop_name[64]);
	
	public native bool SetPropInt(const char prop_name[64], int value);
	public native bool SetPropFloat(const char prop_name[64], float value);
	public native bool SetPropAny(const char prop_name[64], any value);

	public native void RemoveAllItems();
	public native int SpawnWeapon(char[] name, const int index, const int level, const int qual, char[] att);

	property int iPresetType {
		public get() {
			return this.GetPropInt("iPresetType");
		}
		public set(int val) {
			this.SetPropInt("iPresetType", val);
		}
	}
	property int iClassType {
		public get() {
			return this.GetPropInt("iClassType");
		}
		public set(int val) {
			this.SetPropInt("iClassType", val);
		}
	}
	property int iTeam {
		public get() {
			return view_as<int>(TF2_GetClientTeam(this.index));
		}
	}
	property TFTeam Team {
		public get() {
			return TF2_GetClientTeam(this.index);
		}
	}
};

/**
 * Registers a class subplugin.
 * 
 * @param     plugin_name -> module name you want your calling plugin to be identified under
 * @return    integer of the plugin array index, -1 if error.
 */
native int BTC_RegisterPlugin(const char plugin_name[64]);

enum { /// Hook types
	OnCallDownload=0,
	OnPlayerThink,
	OnClassMenu,
	MaxBTCForwards
};

typeset BTCHookCB {
	/// OnCallDownloads
	function Action ();
	function void ();

	/// OnPlayerThink
	function Action (const BTCBaseClass player);
	function void (const BTCBaseClass player);

	/// OnClassMenu
	function void (Menu& menu);
};

/// Use hooktype enum on these.
native void BTC_Hook(const int callbacktype, BTCHookCB callback);
native bool BTC_HookEx(const int callbacktype, BTCHookCB callback);

native void BTC_Unhook(const int callbacktype, BTCHookCB callback);
native bool BTC_UnhookEx(const int callbacktype, BTCHookCB callback);

public SharedPlugin __pl_betheclass = 
{
	name = "BeTheClass",
	file = "betheclass.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public __pl_betheclass_SetNTVOptional()
{
	MarkNativeAsOptional("BTC_RegisterPlugin");
	MarkNativeAsOptional("BTCBaseClass.BTCBaseClass");
	MarkNativeAsOptional("BTCBaseClass.userid.get");
	MarkNativeAsOptional("BTCBaseClass.index.get");

	MarkNativeAsOptional("BTCBaseClass.iPresetType.get");
	MarkNativeAsOptional("BTCBaseClass.iPresetType.set");

	MarkNativeAsOptional("BTCBaseClass.iClassType.get");
	MarkNativeAsOptional("BTCBaseClass.iClassType.set");

	MarkNativeAsOptional("BTCBaseClass.GetPropInt");
	MarkNativeAsOptional("BTCBaseClass.GetPropFloat");
	MarkNativeAsOptional("BTCBaseClass.GetPropAny");
		
	MarkNativeAsOptional("BTCBaseClass.SetPropInt");
	MarkNativeAsOptional("BTCBaseClass.SetPropFloat");
	MarkNativeAsOptional("BTCBaseClass.SetPropAny");

	MarkNativeAsOptional("BTCBaseClass.RemoveAllItems");
	MarkNativeAsOptional("BTCBaseClass.SpawnWeapon");


	MarkNativeAsOptional("BTC_Hook");
	MarkNativeAsOptional("BTC_HookEx");
	MarkNativeAsOptional("BTC_Unhook");
	MarkNativeAsOptional("BTC_UnhookEx");
}
#endif