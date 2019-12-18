stock bool IsClientHere(int client)
{
	if (client > 0 && IsClientConnected(client) && !IsFakeClient(client) && IsClientInGame(client) && IsValidClient(client))
		return true;
	return false;
}

stock bool IsClientAlive(int client)
{
	if (client > 0 && IsValidClient(client) && IsClientConnected(client) && !IsFakeClient(client) && IsClientInGame(client) && IsPlayerAlive(client))
		return true;
	return false;
}

stock bool IsValidClient(int clientIdx, bool isPlayerAlive=false)
{
	if (clientIdx <= 0 || clientIdx > MaxClients) return false;
	if(isPlayerAlive) return IsClientInGame(clientIdx) && IsPlayerAlive(clientIdx);
	return IsClientInGame(clientIdx);
}

stock int FindSpellBook(int iClient)
{
	int spellbook = -1;
	while ((spellbook = FindEntityByClassname(spellbook, "tf_weapon_spellbook")) != -1)
	{
		if (IsValidEntity(spellbook) && GetEntPropEnt(spellbook, Prop_Send, "m_hOwnerEntity") == iClient)
			if(!GetEntProp(spellbook, Prop_Send, "m_bDisguiseWeapon"))
				return spellbook;
	}
	return -1;
}

stock int FindGrapplingHook(int iClient)
{
	int grapplinghook = -1;
	while ((grapplinghook = FindEntityByClassname(grapplinghook, "tf_weapon_grapplinghook")) != -1)
	{
		if (IsValidEntity(grapplinghook) && GetEntPropEnt(grapplinghook, Prop_Send, "m_hOwnerEntity") == iClient)
			if(!GetEntProp(grapplinghook, Prop_Send, "m_bDisguiseWeapon"))
				return grapplinghook;
	}
	
	return -1;
}

stock int GetOwner(const int ent)
{
	if ( IsValidEdict(ent) && IsValidEntity(ent) )
		return GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity");
	return -1;
}

stock void SetAmmo(const int client, const int slot, const int ammo)
{
	int weapon = GetPlayerWeaponSlot(client, slot);
	if (IsValidEntity(weapon)) {
		int iOffset = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType", 1)*4;
		int iAmmoTable = FindSendPropInfo("CTFPlayer", "m_iAmmo");
		SetEntData(client, iAmmoTable+iOffset, ammo, 4, true);
	}
}

stock int GetAmmo(const int client, const int slot)
{
	if (!IsValidClient(client))
		return 0;
	int weapon = GetPlayerWeaponSlot(client, slot);
	if (IsValidEntity(weapon)) {
		int iOffset = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType", 1)*4;
		int iAmmoTable = FindSendPropInfo("CTFPlayer", "m_iAmmo");
		return GetEntData(client, iAmmoTable+iOffset);
	}
	return 0;
}

stock float GetURandomFloatRange(float fMin, float fMax)
{
	return fMin + (GetURandomFloat() * (fMax - fMin));
}

stock void SetBaseSpeed(int iClient, float fSpeed)
{
	if (!IsValidClient(iClient))
		return;
	float fBaseSpeed;
	switch(TF2_GetPlayerClass(iClient)) {
		case TFClass_Scout:
			fBaseSpeed = 400.0;
		case TFClass_Sniper:
			fBaseSpeed = 300.0;
		case TFClass_Soldier:
			fBaseSpeed = 240.0;
		case TFClass_DemoMan:
			fBaseSpeed = 280.0;
		case TFClass_Medic:
			fBaseSpeed = 320.0;
		case TFClass_Heavy:
			fBaseSpeed = 230.0;
		case TFClass_Pyro:
			fBaseSpeed = 300.0;
		case TFClass_Spy:
			fBaseSpeed = 300.0;
		case TFClass_Engineer:
			fBaseSpeed = 300.0;
		case TFClass_Unknown:
			fBaseSpeed = 250.0;
		default:
			return;
	}
	float attribSpeed = fSpeed/fBaseSpeed; // Calc percentage
	if (attribSpeed >= 1.0)
		TF2Attrib_SetByDefIndex(iClient, 107, attribSpeed);
	else
		TF2Attrib_SetByDefIndex(iClient, 54, attribSpeed);
}

// ToDo, use methodmap for spawning weapons, allowing more control
stock int SpawnWeapon(int client, char[] name, int index, int level, int qual, char[] att)
{
	int damage = 1;
	Handle hWeapon = TF2Items_CreateItem(OVERRIDE_ALL|FORCE_GENERATION);
	if(hWeapon == INVALID_HANDLE)
	{
		return -1;
	}

	TF2Items_SetClassname(hWeapon, name);
	TF2Items_SetItemIndex(hWeapon, index);
	TF2Items_SetLevel(hWeapon, level);
	TF2Items_SetQuality(hWeapon, qual);
	new String:atts[32][32];
	new count = ExplodeString(att, ";", atts, 32, 32);

	if(count % 2)
	{
		--count;
	}

	if(count > 0)
	{
		TF2Items_SetNumAttributes(hWeapon, count/2);
		int j;
		for(new i; i<count; i+=2)
		{
			new attrib=StringToInt(atts[i]);
			if(!attrib)
			{
				LogError("Bad weapon attribute passed: %s ; %s", atts[i], atts[i+1]);
				CloseHandle(hWeapon);
				return -1;
			}

			TF2Items_SetAttribute(hWeapon, j, attrib, StringToFloat(atts[i+1]));
			j++;
		}
	}
	else
		TF2Items_SetNumAttributes(hWeapon, 0);

	if (TF2_IsPlayerInCondition(client, TFCond:64))
		damage*=1.5;
	int entity = TF2Items_GiveNamedItem(client, hWeapon);
	CloseHandle(hWeapon);
	EquipPlayerWeapon(client, entity);
	return entity;
}

stock int SpawnGrenade(int client, char[] model, char[] trail, bool GFE) // GFE (leaked TF2C grenade properties)
{
	// Make sure we don't crash the map with entities
	if (GetMaxEntities() - GetEntityCount() < 200)
	{
		ThrowError("Cannot create Grenade, too many entities exist. Try reloading the map.");
		return -1;
	}
	int entity = CreateEntityByName("prop_physics_override");
	if(IsValidEntity(entity))
	{
		DispatchKeyValue(entity, "model", model);
		DispatchKeyValue(entity, "solid", "6");
		if(GFE)
		{
			SetEntityGravity(entity, 0.5); // Gravity, copied over from leaked source code
			SetEntPropFloat(entity, Prop_Data, "m_flFriction", 0.8); // Friction, copied over from leaked source code
			SetEntPropFloat(entity, Prop_Send, "m_flElasticity", 0.45); // Elasticity, copied over from leaked source code
		}
		SetEntProp(entity, Prop_Data, "m_CollisionGroup", 1);
		SetEntProp(entity, Prop_Data, "m_usSolidFlags", 0x18);
		SetEntProp(entity, Prop_Data, "m_nSolidType", 6);
		switch(TF2_GetClientTeam(client))
		{
			case TFTeam_Red:	DispatchKeyValue(entity, "skin", "0");
			case TFTeam_Blue:	DispatchKeyValue(entity, "skin", "1");
		}
		DispatchKeyValue(entity, "renderfx", "0");
		DispatchKeyValue(entity, "rendercolor", "255 255 255");
		DispatchKeyValue(entity, "renderamt", "255");					
		SetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity", client);
		SpawnParticle(trail, _, _, entity, _, _, _, _);
		return entity;
	}
	return -1;
}

stock void EntityCleanup(int iRef) {
	int iEntity = EntRefToEntIndex(iRef);
	if(IsValidEntity(iEntity)) {
		AcceptEntityInput(iEntity, "Kill");
	}
}

stock int SpawnParticle(const char[] particleName, float durationTime = 0.0, bool startSpawn = true, int attachEnt = 0, const char[] attachBone = "", float effectPos[3] = NULL_VECTOR, float effectAng[3] = NULL_VECTOR, float effectVel[3] = NULL_VECTOR)
{
	int particle = CreateEntityByName("info_particle_system");
	if(IsValidEdict(particle))
	{
		float pos[3], ang[3];

		if(StrEqual(attachBone, ""))
		{
			GetEntPropVector(attachEnt, Prop_Send, "m_vecOrigin", pos);
			AddVectors(pos, effectPos, pos);
			GetEntPropVector(attachEnt, Prop_Send, "m_angRotation", ang);
			AddVectors(ang, effectAng, ang);
			TeleportEntity(particle, pos, ang, effectVel);
		}

		char tName[32];
		GetEntPropString(attachEnt, Prop_Data, "m_iName", tName, sizeof(tName));
		DispatchKeyValue(particle, "targetname", "tf2particle");
		DispatchKeyValue(particle, "parentname", tName);
		DispatchKeyValue(particle, "effect_name", particleName);
		DispatchSpawn(particle);

		if (attachEnt != 0)
		{
			SetVariantString("!activator");
			AcceptEntityInput(particle, "SetParent", attachEnt, particle, 0);
			
			if (!StrEqual(attachBone, ""))
			{
				SetVariantString(attachBone);
				AcceptEntityInput(particle, "SetParentAttachment", attachEnt, particle, 0);
				TeleportEntity(particle, effectPos, effectAng, effectVel);
			}
		}
		ActivateEntity(particle);
		
		if (startSpawn)
		{
			AcceptEntityInput(particle, "start");
		}
		
		if (durationTime > 0.0)
		{
			SetPawnTimer(RemoveParticle, durationTime, particle);
		}
		
		return particle;
	}
	return -1;
}

public void RemoveParticle(any particle)
{
	if (IsValidEntity(particle))
	{
		char classname[32];
		GetEdictClassname(particle, classname, sizeof(classname));
		if(StrEqual(classname, "info_particle_system", false))
		{
			AcceptEntityInput(particle, "stop");
			AcceptEntityInput(particle, "Kill");
		}
	}
}

stock void PrecacheParticleSystem(const char[] p_strEffectName)
{
	static s_numStringTable = INVALID_STRING_TABLE;
	if (s_numStringTable == INVALID_STRING_TABLE)
	{
		s_numStringTable = FindStringTable("ParticleEffectNames");
	}
	AddToStringTable(s_numStringTable, p_strEffectName);
}

// Importing this from VSH2, it's neat
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