#if defined _betheclass_included
	#endinput
#endif
#define _betheclass_included

enum BTCClass { // Add any classes added here
	None = -1,
	Undefined = 0,
	Wizard = 1,
	Mercenary = 2
};

methodmap BTCBase {
	public native BTCBase(const int index, bool userid=false);

	property int userid {
		public native get();
	}
	
	property int index {
		public native get();
	}

	property BTCClass iClassType {
		public native get();
		public native set(const BTCClass val);
	}

	// Wizard specific property
	property float fMana {
		public native get();
		public native set(const float val);
	}

	// Time in seconds (with decimal)
	public native void Jam(const float val);

	// Mercenary specific property
	property int iGrenadeStock {
		public native get();
		public native set(const int val);
	}
	// Time in seconds (with decimal)
	property float fGrenadeCooldown {
		public native get();
		public native set(const float val);
	}
	
	public native any GetProperty(const char prop_name[64]);
	public native void SetProperty(const char prop_name[64], any value);

	public native void Reset();
	public native bool IsCustom();
	public native bool IsWizard();
	public native bool IsMercenary();

	public native void OnSpawn();
	public native void Convert(const BTCClass index);
};

// Native for Faust to adaptively get valid boundaries
native BTCClass BTC_MaxClass();

/**
 * Called when BTC handles a client spawn event
 *
 * @param client	Client index
 * @param index		Reference to custom class index, customizable
 *
 * @return	Anything above Plugin_Continue will prevent the event
 */
//forward Action BTC_OnSpawn(int client, BTCClass &index);
/**
 * Called when a client is using a BTC ability
 *
 * @param client	Client index
 * @param index		Custom class index
 * @param ability	Ability index, check classes for values as they're not consistent
 *
 * @return	Anything above Plugin_Continue will prevent use
 */
//forward Action BTC_OnAbility(int client, BTCClass index, int ability);


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
	// BaseClass methodmap
	MarkNativeAsOptional("BTCBase.BTCBase");
	MarkNativeAsOptional("BTCBase.userid.get");
	MarkNativeAsOptional("BTCBase.index.get");
	MarkNativeAsOptional("BTCBase.iClassType.get");
	MarkNativeAsOptional("BTCBase.iClassType.set");
	MarkNativeAsOptional("BTCBase.bIsMinion.set");
	MarkNativeAsOptional("BTCBase.GetProperty");
	MarkNativeAsOptional("BTCBase.SetProperty");
	MarkNativeAsOptional("BTCBase.Reset");
	MarkNativeAsOptional("BTCBase.IsCustom");
	MarkNativeAsOptional("BTCBase.IsWizard");
	MarkNativeAsOptional("BTCBase.IsMercenary");

	MarkNativeAsOptional("BTCBase.OnSpawn");
	MarkNativeAsOptional("BTCBase.Convert");

	MarkNativeAsOptional("BTCBase.fMana.get");
	MarkNativeAsOptional("BTCBase.fMana.set");
	MarkNativeAsOptional("BTCBase.Jam");

	MarkNativeAsOptional("BTCBase.iGrenadeStock.get");
	MarkNativeAsOptional("BTCBase.iGrenadeStock.set");
	MarkNativeAsOptional("BTCBase.fGrenadeCooldown.get");
	MarkNativeAsOptional("BTCBase.fGrenadeCooldown.set");

	MarkNativeAsOptional("BTC_MaxClass");
}
#endif