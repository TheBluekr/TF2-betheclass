#if defined _betheclass_included
	#endinput
#endif
#define _betheclass_included

#include <vsh2>

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
	public native bool SetPropInt(const char prop_name[64], int value);

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
};

/**
 * Registers a class subplugin.
 * 
 * @param     plugin_name -> module name you want your calling plugin to be identified under
 * @return    integer of the plugin array index, -1 if error.
 */
native int BTC_RegisterPlugin(const char plugin_name[64]);

enum {
	OnClassMenu,
	MaxBTCForwards
};

public SharedPlugin __pl_betheclass = 
{
	name = "BeTheClass",
	file = "vsh2_betheclass.smx",
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

	MarkNativeAsOptional("VSH2Player.GetPropInt");
	MarkNativeAsOptional("VSH2Player.SetPropInt");
}
#endif