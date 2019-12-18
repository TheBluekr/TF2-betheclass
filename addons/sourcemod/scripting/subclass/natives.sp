// Create natives for other plugins to call
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (GetEngineVersion() != Engine_TF2)
	{
		Format(error, err_max, "This plugin only works for Team Fortress 2.");
		return APLRes_Failure;
	}
	
	CreateNative("BTCBase.BTCBase", Native_BTCInstance);
	CreateNative("BTCBase.userid.get", Native_BTCGetUserId);
	CreateNative("BTCBase.index.get", Native_BTCGetIndex);
	CreateNative("BTCBase.iClassType.get", Native_BTC_getClassType);
	CreateNative("BTCBase.iClassType.set", Native_BTC_setClassType);
	CreateNative("BTCBase.GetProperty", Native_BTC_getProperty);
	CreateNative("BTCBase.SetProperty", Native_BTC_setProperty);
	CreateNative("BTCBase.Reset", Native_BTC_Reset);
	CreateNative("BTCBase.OnSpawn", Native_BTC_OnSpawn);
	CreateNative("BTCBase.IsCustom", Native_BTC_IsCustom);
	CreateNative("BTCBase.IsWizard", Native_BTC_IsWizard);
	CreateNative("BTCBase.IsMercenary", Native_BTC_IsMercenary);

	CreateNative("BTCBase.Convert", Native_BTC_Convert); // Same as OnSpawn, except it handles the work

	CreateNative("BTCBase.fMana.get", Native_BTCWizard_GetMana);
	CreateNative("BTCBase.fMana.set", Native_BTCWizard_SetMana);
	CreateNative("BTCBase.Jam", Native_BTCWizard_Jam);

	CreateNative("BTCBase.iGrenadeStock.get", Native_BTCMerc_GetGrenadeStock);
	CreateNative("BTCBase.iGrenadeStock.set", Native_BTCMerc_SetGrenadeStock);
	CreateNative("BTCBase.fGrenadeCooldown.get", Native_BTCMerc_GetGrenadeCooldown);
	CreateNative("BTCBase.fGrenadeCooldown.set", Native_BTCMerc_SetGrenadeCooldown);

	CreateNative("BTC_MaxClass", Native_BTC_MaxClass);

	RegPluginLibrary("BeTheClass");
	return APLRes_Success;
}

// Future warning, natives can't be bool, only int
public int Native_BTCInstance(Handle plugin, int numParams)
{
	BaseClass baseplayer = BaseClass(GetNativeCell(1), GetNativeCell(2));
	return view_as<int>(baseplayer);
}

public int Native_BTCGetUserId(Handle plugin, int numParams)
{
	BaseClass baseplayer = GetNativeCell(1);
	return baseplayer.userid;
}

public int Native_BTCGetIndex(Handle plugin, int numParams)
{
	BaseClass baseplayer = GetNativeCell(1);
	return baseplayer.index;
}

public int Native_BTC_getClassType(Handle plugin, int numParams)
{
	BaseClass baseplayer = GetNativeCell(1);
	return view_as<int>(baseplayer.iClassType);
}

public int Native_BTC_setClassType(Handle plugin, int numParams)
{
	BaseClass baseplayer = GetNativeCell(1);
	BTCClass val = GetNativeCell(2);
	baseplayer.iClassType = val;
}

public int Native_BTC_getProperty(Handle plugin, int numParams)
{
	BaseClass baseplayer = GetNativeCell(1);
	char prop_name[64]; GetNativeString(2, prop_name, 64);
	any item;
	if( hPlayerFields[baseplayer.index].GetValue(prop_name, item) )
		return item;
	return 0;
}

public int Native_BTC_setProperty(Handle plugin, int numParams)
{
	BaseClass baseplayer = GetNativeCell(1);
	char prop_name[64]; GetNativeString(2, prop_name, 64);
	any item = GetNativeCell(3);
	hPlayerFields[baseplayer.index].SetValue(prop_name, item);
}

// Don't call this unless necessary
public int Native_BTC_Reset(Handle plugin, int numParams)
{
	BaseClass baseplayer = GetNativeCell(1);
	baseplayer.iPresetType = None;
	baseplayer.iClassType = None;
	ToCMercenary(baseplayer).Init();
	ToCWizard(baseplayer).Init();
}

public int Native_BTC_OnSpawn(Handle plugin, int numParams) // Only call this if class got set already
{
	BaseClass baseplayer = GetNativeCell(1);
	TF2Attrib_RemoveAll(baseplayer.index);
	SetVariantString("");
	AcceptEntityInput(baseplayer.index, "SetCustomModel");
	switch(baseplayer.iClassType) {
		case Wizard:	{
			ToCWizard(baseplayer).OnSpawn();
		}
		case Mercenary:	{
			ToCMercenary(baseplayer).OnSpawn();
		}
	}
}

public int Native_BTC_Convert(Handle plugin, int numParams)
{
	BaseClass baseplayer = GetNativeCell(1);
	TF2Attrib_RemoveAll(baseplayer.index);
	SetVariantString("");
	AcceptEntityInput(baseplayer.index, "SetCustomModel");
	baseplayer.iClassType = GetNativeCell(2);
	switch(baseplayer.iClassType) {
		case Wizard:	{
			ToCWizard(baseplayer).OnSpawn();
		}
		case Mercenary:	{
			ToCMercenary(baseplayer).OnSpawn();
		}
		case -1:		{
			TF2_RespawnPlayer(baseplayer.index);
		}
	}
}

public int Native_BTC_IsCustom(Handle plugin, int numParams)
{
	BaseClass baseplayer = GetNativeCell(1);
	if(baseplayer.iClassType > None)
		return true;
	return false;
}

public int Native_BTC_IsWizard(Handle plugin, int numParams)
{
	BaseClass baseplayer = GetNativeCell(1);
	if(baseplayer.iClassType == Wizard)
		return true;
	return false;
}

public int Native_BTC_IsMercenary(Handle plugin, int numParams)
{
	BaseClass baseplayer = GetNativeCell(1);
	if(baseplayer.iClassType == Mercenary)
		return true;
	return false;
}

// Wizard methodmap native
public int Native_BTCWizard_GetMana(Handle plugin, int numParams)
{
	CWizard basewizard = ToCWizard(GetNativeCell(1));
	return view_as<int>(basewizard.fMana);
}
public int Native_BTCWizard_SetMana(Handle plugin, int numParams)
{
	CWizard basewizard = ToCWizard(GetNativeCell(1));
	float val = view_as<float>(GetNativeCell(2));
	basewizard.fMana = val;
}
public int Native_BTCWizard_Jam(Handle plugin, int numParams)
{
	ToCWizard(GetNativeCell(1)).Jam(GetNativeCell(2));
}

// Mercenary methodmap native
public int Native_BTCMerc_GetGrenadeStock(Handle plugin, int numParams)
{
	CMercenary basemerc = ToCMercenary(GetNativeCell(1));
	return basemerc.iGrenadeStock;
}
public int Native_BTCMerc_SetGrenadeStock(Handle plugin, int numParams)
{
	CMercenary basemerc = ToCMercenary(GetNativeCell(1));
	basemerc.iGrenadeStock = GetNativeCell(2);
}

public int Native_BTCMerc_GetGrenadeCooldown(Handle plugin, int numParams)
{
	CMercenary basemerc = ToCMercenary(GetNativeCell(1));
	return int(basemerc.fGrenadeCooldown);
}
public int Native_BTCMerc_SetGrenadeCooldown(Handle plugin, int numParams)
{
	CMercenary basemerc = ToCMercenary(GetNativeCell(1));
	float val = view_as<float>(GetNativeCell(2));
	basemerc.fGrenadeCooldown = val;
}

public int Native_BTC_MaxClass(Handle plugin, int numParams)
{
	return view_as<int>(MaxClass);
}