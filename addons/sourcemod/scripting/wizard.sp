#include <sourcemod>
#include <betheclass>
#include <tf2attributes>
#include <tf2>
#include <tf2_stocks>

// Define sounds
#define SOUND_RECHARGE			"misc/halloween/spelltick_set.wav"
#define SOUND_SPELL_RARE		"vo/merasmus/rare_spell.wav"

// Define models
#define Wizard_Model			"models/ivory/wizards/fix/v2/merasmus.mdl"

#define Sniper_Model			"models/player/sniper.mdl"

public Plugin myinfo = {
	name = "BTC Wizard subplugin",
	author = "TheBluekr",
	description = "Addon for Be The Class Hub",
	version = "0.1",
	url = "https://git.thebluekr.nl/vspr/be-the-class"
};

enum /* CvarName */ {
	WizardLimit,
	WizardMana,
	WizardManaRegen,
	WizardManaOnHit,
	WizardFireCost,
	WizardFireCooldown,
	WizardFireCharges,
	WizardBatsCost,
	WizardBatsCooldown,
	WizardBatsCharges,
	WizardUberCost,
	WizardUberCooldown,
	WizardUberCharges,
	WizardJumpCost,
	WizardJumpCooldown,
	WizardJumpCharges,
	WizardInvisCost,
	WizardInvisCooldown,
	WizardInvisCharges,
	WizardInvisBonus,
	WizardMeteorCost,
	WizardMeteorCooldown,
	WizardMeteorCharges,
	WizardMonoCost,
	WizardMonoCooldown,
	WizardMonoCharges,
	MaxBTCWizardConVars
};

enum /** HUDs **/ {
	SpellHUD,
	CoolHUD,
	StatusHUD,
	MaxBTCWizardHUDs
};

enum struct BTCGlobals_Wizard {
	Handle m_hHUDs[MaxBTCWizardHUDs];
	ConVar m_hCvars[MaxBTCWizardConVars];
}

BTCGlobals_Wizard g_btc_wizard;

public void OnPluginStart() {
	g_btc_wizard.m_hCvars[WizardLimit] = CreateConVar("btc_wizard_limit", "2", "Limit for amount of wizards", FCVAR_NOTIFY, true, 0.0, false, 0.0);
	g_btc_wizard.m_hCvars[WizardMana] = CreateConVar("btc_wizard_mana", "100.0", "Limit for total wizard mana pool", FCVAR_NOTIFY, true, 0.0, false, 0.0);
	g_btc_wizard.m_hCvars[WizardManaRegen] = CreateConVar("btc_wizard_mana_regen", "1.0", "Mana regen rate per second", FCVAR_NOTIFY, true, 0.0, false, 0.0);
	g_btc_wizard.m_hCvars[WizardManaOnHit] = CreateConVar("btc_wizard_mana_onhit", "10.0", "Bonus mana awarded on melee hit", FCVAR_NOTIFY, true, 0.0, false, 0.0);
	g_btc_wizard.m_hCvars[WizardFireCost] = CreateConVar("btc_wizard_fire_cost", "20.0", "Mana cost for fire spell", FCVAR_NOTIFY, true, 0.0, false, 0.0);
	g_btc_wizard.m_hCvars[WizardFireCooldown] = CreateConVar("btc_wizard_fire_cooldown", "4.5", "Cooldown for fire spell", FCVAR_NOTIFY, true, 0.0, false, 0.0);
	g_btc_wizard.m_hCvars[WizardFireCharges] = CreateConVar("btc_wizard_fire_charges", "2", "Charges for fire spell", FCVAR_NOTIFY, true, 0.0, false, 0.0);
	g_btc_wizard.m_hCvars[WizardBatsCost] = CreateConVar("btc_wizard_bats_cost", "25.0", "Mana cost for bats spell", FCVAR_NOTIFY, true, 0.0, false, 0.0);
	g_btc_wizard.m_hCvars[WizardBatsCooldown] = CreateConVar("btc_wizard_bats_cooldown", "4.5", "Cooldown for bats spell", FCVAR_NOTIFY, true, 0.0, false, 0.0);
	g_btc_wizard.m_hCvars[WizardBatsCharges] = CreateConVar("btc_wizard_bats_charges", "1", "Charges for bats spell", FCVAR_NOTIFY, true, 0.0, false, 0.0);
	g_btc_wizard.m_hCvars[WizardUberCost] = CreateConVar("btc_wizard_uber_cost", "60.0", "Mana cost for uber spell", FCVAR_NOTIFY, true, 0.0, false, 0.0);
	g_btc_wizard.m_hCvars[WizardUberCooldown] = CreateConVar("btc_wizard_uber_cooldown", "60.0", "Cooldown for uber spell", FCVAR_NOTIFY, true, 0.0, false, 0.0);
	g_btc_wizard.m_hCvars[WizardUberCharges] = CreateConVar("btc_wizard_uber_charges", "1", "Charges for uber spell", FCVAR_NOTIFY, true, 0.0, false, 0.0);
	g_btc_wizard.m_hCvars[WizardJumpCost] = CreateConVar("btc_wizard_jump_cost", "35.0", "Mana cost for uber spell", FCVAR_NOTIFY, true, 0.0, false, 0.0);
	g_btc_wizard.m_hCvars[WizardJumpCooldown] = CreateConVar("btc_wizard_jump_cooldown", "6.0", "Cooldown for jump spell", FCVAR_NOTIFY, true, 0.0, false, 0.0);
	g_btc_wizard.m_hCvars[WizardJumpCharges] = CreateConVar("btc_wizard_jump_charges", "2", "Charges for jump spell", FCVAR_NOTIFY, true, 0.0, false, 0.0);
	g_btc_wizard.m_hCvars[WizardInvisCost] = CreateConVar("btc_wizard_invis_cost", "20.0", "Mana cost for invis spell", FCVAR_NOTIFY, true, 0.0, false, 0.0);
	g_btc_wizard.m_hCvars[WizardInvisCooldown] = CreateConVar("btc_wizard_invis_cooldown", "20.0", "Cooldown for invis spell", FCVAR_NOTIFY, true, 0.0, false, 0.0);
	g_btc_wizard.m_hCvars[WizardInvisCharges] = CreateConVar("btc_wizard_invis_charges", "1", "Charges for invis spell", FCVAR_NOTIFY, true, 0.0, false, 0.0);
	g_btc_wizard.m_hCvars[WizardInvisBonus] = CreateConVar("btc_wizard_invis_bonus", "15.0", "Bonus awarded on melee hit while invisible (can be negative)", FCVAR_NOTIFY, false, 0.0, false, 0.0);
	g_btc_wizard.m_hCvars[WizardMeteorCost] = CreateConVar("btc_wizard_meteor_cost", "90.0", "Mana cost for meteor spell", FCVAR_NOTIFY, true, 0.0, false, 0.0);
	g_btc_wizard.m_hCvars[WizardMeteorCooldown] = CreateConVar("btc_wizard_meteor_cooldown", "40.0", "Cooldown for meteor spell", FCVAR_NOTIFY, true, 0.0, false, 0.0);
	g_btc_wizard.m_hCvars[WizardMeteorCharges] = CreateConVar("btc_wizard_meteor_charges", "1", "Charges for meteor spell", FCVAR_NOTIFY, true, 0.0, false, 0.0);
	g_btc_wizard.m_hCvars[WizardMonoCost] = CreateConVar("btc_wizard_mono_cost", "75.0", "Mana cost for monoculus spell", FCVAR_NOTIFY, true, 0.0, false, 0.0);
	g_btc_wizard.m_hCvars[WizardMonoCooldown] = CreateConVar("btc_wizard_mono_cooldown", "40.0", "Cooldown for monoculus spell", FCVAR_NOTIFY, true, 0.0, false, 0.0);
	g_btc_wizard.m_hCvars[WizardMonoCharges] = CreateConVar("btc_wizard_mono_charges", "1", "Charges for monoculus spell", FCVAR_NOTIFY, true, 0.0, false, 0.0);

	for( int i; i<MaxBTCWizardHUDs; i++ )
		g_btc_wizard.m_hHUDs[i] = CreateHudSynchronizer();

	AddCommandListener(OnVoiceMenu, "voicemenu");

	AddNormalSoundHook(HookSound);
}

methodmap CWizard < BTCBaseClass
{
	public CWizard(const int ind, bool uid=false) {
		return view_as<CWizard>( BTCBaseClass(ind, uid) );
	}
	property float fMana {
		public get()
		{
			return this.GetPropFloat("fMana");
		}
		public set(const float val)
		{
			this.SetPropFloat("fMana", val);
		}
	}
	property float fCooldown {
		public get()
		{
			return this.GetPropFloat("fCooldown");
		}
		public set(const float val)
		{
			this.SetPropFloat("fCooldown", val);
		}
	}
	property float fAntiSpamCooldown {
		public get()
		{
			return this.GetPropFloat("fAntiSpamCooldown");
		}
		public set(const float val)
		{
			this.SetPropFloat("fAntiSpamCooldown", val);
		}
	}
	property float fFireCooldown {
		public get()
		{
			return this.GetPropFloat("fFireCooldown");
		}
		public set(const float val)
		{
			this.SetPropFloat("fFireCooldown", val);
		}
	}
	property int iFireCharges {
		public get()
		{
			return this.GetPropInt("iFireCharges");
		}
		public set(const int val)
		{
			this.SetPropInt("iFireCharges", val);
		}
	}
	property float fBatsCooldown {
		public get()
		{
			return this.GetPropFloat("fBatsCooldown");
		}
		public set(const float val)
		{
			this.SetPropFloat("fBatsCooldown", val);
		}
	}
	property int iBatsCharges {
		public get()
		{
			return this.GetPropInt("iBatsCharges");
		}
		public set(const int val)
		{
			this.SetPropInt("iBatsCharges", val);
		}
	}
	property float fUberCooldown {
		public get()
		{
			return this.GetPropFloat("fUberCooldown");
		}
		public set(const float val)
		{
			this.SetPropFloat("fUberCooldown", val);
		}
	}
	property int iUberCharges {
		public get()
		{
			return this.GetPropInt("iUberCharges");
		}
		public set(const int val)
		{
			this.SetPropInt("iUberCharges", val);
		}
	}
	property float fJumpCooldown {
		public get()
		{
			return this.GetPropFloat("fJumpCooldown");
		}
		public set(const float val)
		{
			this.SetPropFloat("fJumpCooldown", val);
		}
	}
	property int iJumpCharges {
		public get()
		{
			return this.GetPropInt("iJumpCharges");
		}
		public set(const int val)
		{
			this.SetPropInt("iJumpCharges", val);
		}
	}
	property float fInvisCooldown {
		public get()
		{
			return this.GetPropFloat("fInvisCooldown");
		}
		public set(const float val)
		{
			this.SetPropFloat("fInvisCooldown", val);
		}
	}
	property int iInvisCharges {
		public get()
		{
			return this.GetPropInt("iInvisCharges");
		}
		public set(const int val)
		{
			this.SetPropInt("iInvisCharges", val);
		}
	}
	property float fMeteorCooldown {
		public get()
		{
			return this.GetPropFloat("fMeteorCooldown");
		}
		public set(const float val)
		{
			this.SetPropFloat("fMeteorCooldown", val);
		}
	}
	property int iMeteorCharges {
		public get()
		{
			return this.GetPropInt("iMeteorCharges");
		}
		public set(const int val)
		{
			this.SetPropInt("iMeteorCharges", val);
		}
	}
	property float fMonoCooldown {
		public get()
		{
			return this.GetPropFloat("fMonoCooldown");
		}
		public set(const float val)
		{
			this.SetPropFloat("fMonoCooldown", val);
		}
	}
	property int iMonoCharges {
		public get()
		{
			return this.GetPropInt("iMonoCharges");
		}
		public set(const int val)
		{
			this.SetPropInt("iMonoCharges", val);
		}
	}
	property int iSelectedSpell {
		public get()
		{
			return this.GetPropInt("iSelectedSpell");
		}
		public set(const int val)
		{
			this.SetPropInt("iSelectedSpell", val);
		}
	}
	property int iSpelltype {
		public get()
		{
			return this.GetPropInt("iSpelltype");
		}
		public set(const int val)
		{
			this.SetPropInt("iSpelltype", val);
		}
	}
	property int iCastSound {
		public get()
		{
			return this.GetPropInt("iCastSound");
		}
		public set(const int val)
		{
			this.SetPropInt("iCastSound", val);
		}
	}
	property float fInvisBonus {
		public get()
		{
			return this.GetPropFloat("fInvisBonus");
		}
		public set(const float val)
		{
			this.SetPropFloat("fInvisBonus", val);
		}
	}
	public void UpdateHUD(Handle hHUD, const char[] text, float x, float y, float holdTime, int r, int g, int b, int a, int effect, float fxTime, float fadeIn, float fadeOut) {
		SetHudTextParams(x, y, holdTime, r, g, b, a, effect, fxTime, fadeIn, fadeOut);
		ShowSyncHudText(this.index, hHUD, text);
	}
	public bool IsReady() {
		if(TF2_IsPlayerInCondition(this.index, TFCond_Cloaked) || TF2_IsPlayerInCondition(this.index, TFCond_Dazed) || TF2_IsPlayerInCondition(this.index, TFCond_Taunting) || TF2_IsPlayerInCondition(this.index, TFCond_Bonked) || TF2_IsPlayerInCondition(this.index, TFCond_RestrictToMelee) || TF2_IsPlayerInCondition(this.index, TFCond_MeleeOnly) || TF2_IsPlayerInCondition(this.index, TFCond_HalloweenGhostMode) || TF2_IsPlayerInCondition(this.index, TFCond_HalloweenKart))
			return false;
		return true;
	}
	public void OnSpawn() {
		TF2Attrib_RemoveAll(this.index);
		TF2_SetPlayerClass(this.index, TFClass_Sniper, _, true);
		TF2Attrib_SetByName(this.index, "max health additive bonus", 25.0);
		SetEntityHealth(this.index, 200); // Just in case

		this.RemoveAllItems(true);

		//Cooldowns
		this.fCooldown = 1.0; // 1s
		this.fAntiSpamCooldown = 0.0;
		this.fFireCooldown = 0.0;
		this.fBatsCooldown = 0.0;
		this.fUberCooldown = 15.0;
		this.fJumpCooldown = 6.0;
		this.fInvisCooldown = 7.0;
		this.fMeteorCooldown = 25.0;
		this.fMonoCooldown = 20.0;
		//SpellCharges
		this.iFireCharges = 2; //Fire
		this.iBatsCharges = 1; //Bats
		this.iUberCharges = 0; //Uber
		this.iJumpCharges = 0; //Jump
		this.iInvisCharges = 0; //Invis
		this.iMeteorCharges = 0; //Meteor
		this.iMonoCharges = 0; //Mono
		//Others
		this.fMana = g_btc_wizard.m_hCvars[WizardMana].FloatValue;
		this.iSelectedSpell = 1;
		this.iCastSound = 0;
		this.iSpelltype = 0;
		this.fInvisBonus = 0.0;

		SetVariantString(Wizard_Model);
		AcceptEntityInput(this.index, "SetCustomModel");
		SetEntProp(this.index, Prop_Send, "m_bUseClassAnimations", 1);
		char attribs[128];
		Format(attribs, sizeof(attribs), "124 ; 1 ; 2 ; 1.025 ; 107 ; 1.05 ; 326 ; 1.05 ; 292 ; 106 ; 214 ; %i", GetRandomInt(36000, 99999));
		this.SpawnWeapon("tf_weapon_club", 880, 1, 13, attribs);
		this.SpawnWeapon("tf_weapon_spellbook", 1070, 1, 0, "124 ; 1 ; 547 ; 0.5")
	}

	public void OnKill(BTCBaseClass victim, Event event) {
	}
	public void OnDeath(BTCBaseClass attacker, Event event) {
		float victimpos[3];
		GetClientAbsOrigin(this.index, victimpos);
		char killSound[35];
		Format(killSound, sizeof(killSound), "vo/halloween_merasmus/sf12_combat_idle0%i.mp3", GetRandomInt(1, 2));
		EmitSoundToAll(killSound, this.index, _, _, _, 0.5, _, _, victimpos, _, false);

		this.UpdateHUD(g_btc_wizard.m_hHUDs[SpellHUD], "", 0.0, -1.0, 0.5, 0, 255, 0, 255, 2, 0.0, 0.0, 0.0);
		this.UpdateHUD(g_btc_wizard.m_hHUDs[CoolHUD], "", 0.0, -1.0, 0.5, 0, 255, 0, 255, 2, 0.0, 0.0, 0.0);
	}

	public void OnDamage(BTCBaseClass victim, Event event) {
		if(this.index == victim.index)
			return;
		if(GetEntPropEnt(this.index, Prop_Send, "m_hActiveWeapon") == GetPlayerWeaponSlot(this.index, TFWeaponSlot_Melee) && event.GetInt("custom") == 0 /* Spells should have a custom value */ ) {
			this.fMana += g_btc_wizard.m_hCvars[WizardManaOnHit].FloatValue; // Award 10 mana on melee hit
			if(this.fInvisBonus > 0.0) {
				this.fMana += g_btc_wizard.m_hCvars[WizardInvisBonus].FloatValue;
			}
		}
	}

	public void OnHurt(BTCBaseClass attacker, Event event) {
		if(event.GetInt("health") > 0 && event.GetInt("damageamount") > 0) {
			float fWizardPos[3];
			char medSound[35];
			GetClientAbsOrigin(this.index, fWizardPos);
			Format(medSound, sizeof(medSound), "vo/merasmus/sf12_pain0%i.mp3", GetRandomInt(1, 6));
			EmitSoundToAll(medSound, this.index, _, _, _, 0.3, _, _, fWizardPos, _, false);
		}
	}

	public void OnVoiceMenu(const char[] szCmd1, const char[] szCmd2) {
		if(szCmd1[0] == '0' && szCmd2[0] == '0' && this.fAntiSpamCooldown <= 0.0) // Medic call
		{
			if(this.iSelectedSpell <= 1)
				this.iSelectedSpell = 7;
			else
				this.iSelectedSpell--;
			RequestFrame(ResetSpellCharges, this.index);
		}
	}

	public void Think() {
		if(!IsValidClient(this.index, true))
			return;
		
		if(TF2_IsPlayerInCondition(this.index, view_as<TFCond>(50)))
			this.UpdateHUD(g_btc_wizard.m_hHUDs[StatusHUD], "Your magic is being jammed! Run Away!", -1.0, 0.75, 0.5, 255, 255, 255, 255, 2, 0.0, 0.0, 0.0);
		else
			this.UpdateHUD(g_btc_wizard.m_hHUDs[StatusHUD], "", -1.0, 0.75, 0.5, 255, 255, 255, 255, 2, 0.0, 0.0, 0.0);
		
		char SpellHUDText[255]; // Display of current selected spell
		char CoolHUDText[255];

		this.fFireCooldown -= 0.1;
		if(this.fFireCooldown < 0.0)
			this.fFireCooldown = 0.0;
		this.fBatsCooldown -= 0.1;
		if(this.fBatsCooldown < 0.0)
			this.fBatsCooldown = 0.0;
		this.fUberCooldown -= 0.1;
		if(this.fUberCooldown < 0.0)
			this.fUberCooldown = 0.0;
		this.fJumpCooldown -= 0.1;
		if(this.fJumpCooldown < 0.0)
			this.fJumpCooldown = 0.0;
		this.fInvisCooldown -= 0.1;
		if(this.fInvisCooldown < 0.0)
			this.fInvisCooldown = 0.0;
		this.fMeteorCooldown -= 0.1;
		if(this.fMeteorCooldown < 0.0)
			this.fMeteorCooldown = 0.0;
		this.fMonoCooldown -= 0.1;
		if(this.fMonoCooldown < 0.0)
			this.fMonoCooldown = 0.0;

		Format(CoolHUDText, sizeof(CoolHUDText), "              (%i) %i\n              (%i) %i\n              (%i) %i\n              (%i) %i\n              (%i) %i\n              (%i) %i\n              (%i) %i\n", this.iFireCharges, RoundToZero(this.fFireCooldown), this.iBatsCharges, RoundToZero(this.fBatsCooldown), this.iUberCharges, RoundToZero(this.fUberCooldown), this.iJumpCharges, RoundToZero(this.fJumpCooldown), this.iInvisCharges, RoundToZero(this.fInvisCooldown), this.iMeteorCharges, RoundToZero(this.fMeteorCooldown), this.iMonoCharges, RoundToZero(this.fMonoCooldown));
		switch(this.iSelectedSpell) {
			case 1: {
				Format(SpellHUDText, sizeof(SpellHUDText), ">Fire\n Bats\n Uber\n Jump\n Invis\n Meteor\n Mono\n Mana: %i", RoundToZero(this.fMana));
				this.iSpelltype = 0;
				this.iCastSound = 0;
			}
			case 2: {
				Format(SpellHUDText, sizeof(SpellHUDText), " Fire\n>Bats\n Uber\n Jump\n Invis\n Meteor\n Mono\n Mana: %i", RoundToZero(this.fMana));
				this.iSpelltype = 1;
				this.iCastSound = 1;
			}
			case 3: {
				Format(SpellHUDText, sizeof(SpellHUDText), " Fire\n Bats\n>Uber\n Jump\n Invis\n Meteor\n Mono\n Mana: %i", RoundToZero(this.fMana));
				this.iSpelltype = 2;
				this.iCastSound = 1;
			}
			case 4: {
				Format(SpellHUDText, sizeof(SpellHUDText), " Fire\n Bats\n Uber\n>Jump\n Invis\n Meteor\n Mono\n Mana: %i", RoundToZero(this.fMana));
				this.iSpelltype = 4;
				this.iCastSound = 1;
			}
			case 5: {
				Format(SpellHUDText, sizeof(SpellHUDText), " Fire\n Bats\n Uber\n Jump\n>Invis\n Meteor\n Mono\n Mana: %i", RoundToZero(this.fMana));
				this.iSpelltype = 5;
				this.iCastSound = 1;
			}
			case 6: {
				Format(SpellHUDText, sizeof(SpellHUDText), " Fire\n Bats\n Uber\n Jump\n Invis\n>Meteor\n Mono\n Mana: %i", RoundToZero(this.fMana));
				this.iSpelltype = 9;
				this.iCastSound = 9;
			}
			case 7: {
				Format(SpellHUDText, sizeof(SpellHUDText), " Fire\n Bats\n Uber\n Jump\n Invis\n Meteor\n>Mono\n Mana: %i", RoundToZero(this.fMana));
				this.iSpelltype = 10;
				this.iCastSound = 9;
			}
		}

		this.UpdateHUD(g_btc_wizard.m_hHUDs[SpellHUD], SpellHUDText, 0.0, -1.0, 0.5, 0, 255, 0, 255, 2, 0.0, 0.0, 0.0);
		this.UpdateHUD(g_btc_wizard.m_hHUDs[CoolHUD], CoolHUDText, 0.0, -1.0, 0.5, 0, 255, 0, 255, 2, 0.0, 0.0, 0.0);
		
		char sModel[128];
		GetEntPropString(this.index, Prop_Data, "m_ModelName", sModel, sizeof(sModel)); // Get the complete Modelname.
		if(StrEqual(sModel, Sniper_Model, false)) { // Bug fix, removing quads turns the player to default sniper model
			SetVariantString(Wizard_Model);
			AcceptEntityInput(this.index, "SetCustomModel");
			SetEntProp(this.index, Prop_Send, "m_bUseClassAnimations", 1);
		}

		if(this.fMana < g_btc_wizard.m_hCvars[WizardMana].FloatValue) // This should reflect the scale a bit better
		{
			this.fMana += g_btc_wizard.m_hCvars[WizardManaRegen].FloatValue;
		}
		if(this.fMana > g_btc_wizard.m_hCvars[WizardMana].FloatValue)
			this.fMana = g_btc_wizard.m_hCvars[WizardMana].FloatValue;

		if(this.fFireCooldown <= 0.0 && this.iFireCharges < g_btc_wizard.m_hCvars[WizardFireCharges].IntValue)
		{
			this.iFireCharges++;
			if(this.iFireCharges < g_btc_wizard.m_hCvars[WizardFireCharges].IntValue && g_btc_wizard.m_hCvars[WizardFireCharges].IntValue > 1)
			{
			    this.fFireCooldown = g_btc_wizard.m_hCvars[WizardFireCooldown].FloatValue;
			}
		}
		if(this.fBatsCooldown <= 0.0 && this.iBatsCharges < g_btc_wizard.m_hCvars[WizardBatsCharges].IntValue)
		{
			this.iBatsCharges++;
			if(this.iBatsCharges < g_btc_wizard.m_hCvars[WizardBatsCharges].IntValue && g_btc_wizard.m_hCvars[WizardBatsCharges].IntValue > 1)
			{
			    this.fBatsCooldown = g_btc_wizard.m_hCvars[WizardBatsCooldown].FloatValue;
			}
		}
		if(this.fUberCooldown <= 0.0 && this.iUberCharges < g_btc_wizard.m_hCvars[WizardUberCharges].IntValue)
		{
			this.iUberCharges++;
			if(this.iUberCharges < g_btc_wizard.m_hCvars[WizardUberCharges].IntValue && g_btc_wizard.m_hCvars[WizardUberCharges].IntValue > 1)
			{
			    this.fUberCooldown = g_btc_wizard.m_hCvars[WizardUberCooldown].FloatValue;
			}
		}
		if(this.fJumpCooldown <= 0.0 && this.iJumpCharges < g_btc_wizard.m_hCvars[WizardJumpCharges].IntValue)
		{
			this.iJumpCharges++;
			if(this.iJumpCharges < g_btc_wizard.m_hCvars[WizardJumpCharges].IntValue && g_btc_wizard.m_hCvars[WizardJumpCharges].IntValue > 1)
			{
			    this.fJumpCooldown = g_btc_wizard.m_hCvars[WizardJumpCooldown].FloatValue;
			}
		}
		if(this.fInvisCooldown <= 0.0 && this.iInvisCharges < g_btc_wizard.m_hCvars[WizardInvisCharges].IntValue)
		{
			this.iInvisCharges++;
			if(this.iInvisCharges < g_btc_wizard.m_hCvars[WizardInvisCharges].IntValue && g_btc_wizard.m_hCvars[WizardInvisCharges].IntValue > 1)
			{
			    this.fInvisCooldown = g_btc_wizard.m_hCvars[WizardInvisCooldown].FloatValue;
			}
		}
		if(this.fMeteorCooldown <= 0.0 && this.iMeteorCharges < g_btc_wizard.m_hCvars[WizardMeteorCharges].IntValue)
		{
			this.iMeteorCharges++;
			if(this.iMeteorCharges < g_btc_wizard.m_hCvars[WizardMeteorCharges].IntValue && g_btc_wizard.m_hCvars[WizardMeteorCharges].IntValue > 1)
			{
			    this.fMeteorCooldown = g_btc_wizard.m_hCvars[WizardMeteorCooldown].FloatValue;
			}
		}
		if(this.fMonoCooldown <= 0.0 && this.iMonoCharges < g_btc_wizard.m_hCvars[WizardMonoCharges].IntValue)
		{
			this.iMonoCharges++;
			if(this.iMonoCharges < g_btc_wizard.m_hCvars[WizardMonoCharges].IntValue && g_btc_wizard.m_hCvars[WizardMonoCharges].IntValue > 1)
			{
				this.fMonoCooldown = g_btc_wizard.m_hCvars[WizardMonoCooldown].FloatValue;
			}
		}

		int iSpellbook = FindSpellBook(this.index);

		if((GetClientButtons(this.index) & IN_RELOAD) && this.fAntiSpamCooldown <= 0.0)
		{
			if(this.iSelectedSpell >= 7) // Increase this if we add more
			{
				this.iSelectedSpell = 1;
			}
			else
			{
				this.iSelectedSpell++;
			}
			RequestFrame(ResetSpellCharges, this.index);
			this.fAntiSpamCooldown = 0.3;
		}

		SetEntProp(iSpellbook, Prop_Send, "m_iSelectedSpellIndex", this.iSpelltype); // No need to call it 7 times if we can just set it here

		if((GetClientButtons(this.index) & IN_ATTACK2) && this.IsReady() && !TF2_IsPlayerInCondition(this.index, view_as<TFCond>(50)) && this.fCooldown <= 0.0) { // Cast mechanic
			if(this.iSpelltype == 0 && this.iFireCharges > 0 && this.fMana >= g_btc_wizard.m_hCvars[WizardFireCost].FloatValue) { // Fire spell
				this.fFireCooldown = g_btc_wizard.m_hCvars[WizardFireCooldown].FloatValue;
				this.iFireCharges--;
				this.fMana -= g_btc_wizard.m_hCvars[WizardFireCost].FloatValue;
			}
			else if(this.iSpelltype == 1 && this.iBatsCharges > 0 && this.fMana >= g_btc_wizard.m_hCvars[WizardBatsCost].FloatValue) { // Bats
				this.fBatsCooldown = g_btc_wizard.m_hCvars[WizardBatsCooldown].FloatValue;
				this.iBatsCharges--;
				this.fMana -= g_btc_wizard.m_hCvars[WizardBatsCost].FloatValue;
			}
			else if(this.iSpelltype == 2 && this.iUberCharges > 0 && this.fMana >= g_btc_wizard.m_hCvars[WizardUberCost].FloatValue) { // Uber
				this.fUberCooldown = g_btc_wizard.m_hCvars[WizardUberCooldown].FloatValue;
				this.iUberCharges--;
				this.fMana -= g_btc_wizard.m_hCvars[WizardUberCost].FloatValue;
			}
			else if(this.iSpelltype == 4 && this.iJumpCharges > 0 && this.fMana >= g_btc_wizard.m_hCvars[WizardJumpCost].FloatValue) { // Jump spell
				this.fJumpCooldown = g_btc_wizard.m_hCvars[WizardJumpCooldown].FloatValue;
				this.iJumpCharges--;
				this.fMana -= g_btc_wizard.m_hCvars[WizardJumpCost].FloatValue;
			}
			else if(this.iSpelltype == 5 && this.iInvisCharges > 0 && this.fMana >= g_btc_wizard.m_hCvars[WizardInvisCost].FloatValue) { // Invis
				this.fInvisCooldown = g_btc_wizard.m_hCvars[WizardInvisCooldown].FloatValue;
				this.iInvisCharges--;
				this.fMana -= g_btc_wizard.m_hCvars[WizardInvisCost].FloatValue;
			}
			else if(this.iSpelltype == 9 && this.iMeteorCharges > 0 && this.fMana >= g_btc_wizard.m_hCvars[WizardMeteorCost].FloatValue) { // Meteor Spell
				this.fMeteorCooldown = g_btc_wizard.m_hCvars[WizardMeteorCooldown].FloatValue;
				this.iMeteorCharges--;
				this.fMana -= g_btc_wizard.m_hCvars[WizardMeteorCost].FloatValue;
			}
			else if(this.iSpelltype == 10 && this.iMonoCharges > 0 && this.fMana >= g_btc_wizard.m_hCvars[WizardMonoCost].FloatValue) { // Monoculus
				this.fMonoCooldown = g_btc_wizard.m_hCvars[WizardMonoCooldown].FloatValue;
				this.iMonoCharges--;
				this.fMana -= g_btc_wizard.m_hCvars[WizardMonoCost].FloatValue;
			}
			else {
				return;
			}

			char MedSound[35];
			float fWizardPos[3];

			switch(this.iCastSound) {
				case 0: //Fire spell cast sound
					Format(MedSound, sizeof(MedSound), "vo/merasmus/spell_cast_fire%i.mp3", GetRandomInt(1, 4));
				case 1: //Common spell cast sound
					Format(MedSound, sizeof(MedSound), "vo/merasmus/spell_cast%i.mp3", GetRandomInt(1, 7));
				case 9: //Rare spell cast sound
					Format(MedSound, sizeof(MedSound), "vo/merasmus/spell_cast_rare%i.mp3", GetRandomInt(1, 2));
				default:
					Format(MedSound, sizeof(MedSound), "vo/merasmus/spell_cast%i.mp3", GetRandomInt(1, 7)); // Go to common spell as fallback
			}
			SetEntProp(iSpellbook, Prop_Send, "m_iSpellCharges", 1);
			GetClientAbsOrigin(this.index, fWizardPos);
			EmitSoundToAll(MedSound, this.index, _, _, _, 0.5, _, _, fWizardPos, _, false);
			FakeClientCommand(this.index, "use tf_weapon_spellbook");
			this.fCooldown = 2.5; // 2.5s before next cast
			SetPawnTimer(ResetSpellCharges, 0.5, this.index);
		}
	}

	public void OnConditionAdded(TFCond condition) {
		switch( condition ) {
			case TFCond_Dazed: {
				float fWizardPos[3];
				GetClientAbsOrigin(this.index, fWizardPos);
				char medSound[35];
				Format(medSound, sizeof(medSound), "vo/merasmus/stunned0%i.mp3", GetRandomInt(1, 3));
				EmitSoundToAll(medSound, this.index, _, _, _, 0.5, _, _, fWizardPos, _, false);
			}
		}
	}
}

public CWizard ToCWizard(const BTCBaseClass guy) {
	return view_as<CWizard>(guy);
}

int g_iWizardID;

public void OnLibraryAdded(const char[] name) {
	if( StrEqual(name, "BeTheClass") ) {
		g_iWizardID = BTC_RegisterPlugin("wizard");
		LoadBTCHooks();
	}
}

public void LoadBTCHooks() {
	if(!BTC_HookEx(OnCallDownload, Wizard_OnCallDownloads))
		LogError("Error loading OnCallDownload forwards for Wizard subplugin.");
	if(!BTC_HookEx(OnClassThink, Wizard_OnClassThink))
		LogError("Error loading OnClassThink forwards for Wizard subplugin.");
	if(!BTC_HookEx(OnClassSpawn, Wizard_OnClassSpawn))
		LogError("Error loading OnClassSpawn forwards for Wizard subplugin.");
	if(!BTC_HookEx(OnClassDeath, Wizard_OnClassDeath))
		LogError("Error loading OnClassDeath forwards for Wizard subplugin.");
	if(!BTC_HookEx(OnClassHurt, Wizard_OnClassHurt))
		LogError("Error loading OnClassHurt forwards for Wizard subplugin.");
	if(!BTC_HookEx(OnClassMenu, Wizard_OnClassMenu))
		LogError("Error loading OnClassMenu forwards for Wizard subplugin.");
}


stock bool IsWizard(const BTCBaseClass player) {
	return player.GetPropInt("iClassType") == g_iWizardID;
}

public void OnRoundStart(Event event, const char[] name, bool dontBroadcast) {
	BTCBaseClass player = BTCBaseClass(GetEventInt(event,"userid"), true);
	if(!IsValidClient(player.index) || !IsWizard(player)) {
		return;
	}
	float fWizardPos[3];
	GetClientAbsOrigin(player.index, fWizardPos);
	char medSound[35];
	Format(medSound, sizeof(medSound), "vo/merasmus/round_begin0%i.mp3", GetRandomInt(1, 4));
	EmitSoundToAll(medSound, player.index, _, _, _, 0.5, _, _, fWizardPos, _, false);
}

public void Wizard_OnCallDownloads() {
	PrecacheModel(Wizard_Model, true);
}

public void Wizard_OnClassMenu(Menu &menu) {
	char tostr[10]; IntToString(g_iWizardID, tostr, sizeof(tostr));
	menu.AddItem(tostr, "Wizard");
}

public void Wizard_OnClassThink(const BTCBaseClass player) {
	if(!IsWizard(player))
		return;
	ToCWizard(player).Think();
}

public Action Wizard_OnClassSpawn(const BTCBaseClass player, Event event) {
	if(player.GetPropInt("iPresetType") != g_iWizardID)
		return Plugin_Continue;
	player.SetPropInt("iClassType", g_iWizardID);
	ToCWizard(player).OnSpawn();
	return Plugin_Handled;
}

public void Wizard_OnClassDeath(const BTCBaseClass attacker, const BTCBaseClass victim, Event event) {
	if(IsWizard(attacker))
		ToCWizard(attacker).OnKill(victim, event);
	else if (IsWizard(victim))
		ToCWizard(victim).OnDeath(attacker, event);
}

public void Wizard_OnClassHurt(const BTCBaseClass attacker, const BTCBaseClass victim, Event event) {
	if(IsWizard(attacker))
		ToCWizard(attacker).OnDamage(victim, event);
	else if (IsWizard(victim))
		ToCWizard(victim).OnHurt(attacker, event);
}

public void ResetSpellCharges(int iClient) {
	int iSpellbook = FindSpellBook(iClient);
	SetEntProp(iSpellbook, Prop_Send, "m_iSpellCharges", 0);
}

public Action OnVoiceMenu(int iClient, const char[] command, int argc) {
	if(!IsValidClient(iClient) || argc < 2)
		return Plugin_Continue;
	BTCBaseClass player = BTCBaseClass(iClient)
	if(!IsWizard(player))
		return Plugin_Continue;
	char szCmd1[8]; GetCmdArg(1, szCmd1, sizeof(szCmd1));
	char szCmd2[8]; GetCmdArg(2, szCmd2, sizeof(szCmd2));
	ToCWizard(player).OnVoiceMenu(szCmd1, szCmd2);
	return Plugin_Handled;
}

public Action HookSound(int clients[64], int& numClients, char sound[PLATFORM_MAX_PATH], int& entity, int& channel, float& volume, int& level, int& pitch, int& flags, char soundEntry[PLATFORM_MAX_PATH], int& seed) {
	if(!IsValidClient(entity) || channel < 1)
		return Plugin_Continue;
	BTCBaseClass player = BTCBaseClass(entity);
	if(channel==SNDCHAN_VOICE && IsWizard(player))
		return Plugin_Stop;
	return Plugin_Continue;
}

/// TF2 Events
public void TF2_OnConditionAdded(int iClient, TFCond condition) {
	if(!IsValidClient(iClient))
		return;
	BTCBaseClass player = BTCBaseClass(iClient);
	if(!IsWizard(player))
		return;
	ToCWizard(player).OnConditionAdded(condition);
}
public void TF2_OnConditionRemoved(int iClient, TFCond condition) {
	if(!IsValidClient(iClient))
		return;
	BTCBaseClass player = BTCBaseClass(iClient);
	if(!IsWizard(player))
		return;
	if(condition == TFCond_Stealthed)
		ToCWizard(player).fInvisBonus = 0.8;
}

/// Stocks
stock bool IsValidClient(int clientIdx, bool isPlayerAlive=false) {
	if (clientIdx <= 0 || clientIdx > MaxClients) return false;
	if(isPlayerAlive) return IsClientInGame(clientIdx) && IsPlayerAlive(clientIdx);
	return IsClientInGame(clientIdx);
}

stock void SetPawnTimer(Function func, float thinktime = 0.1, any param1 = -999, any param2 = -999) {
	DataPack thinkpack = new DataPack();
	thinkpack.WriteFunction(func);
	thinkpack.WriteCell(param1);
	thinkpack.WriteCell(param2);

	CreateTimer(thinktime, DoThink, thinkpack, TIMER_DATA_HNDL_CLOSE);
}

public Action DoThink(Handle hTimer, DataPack hndl) {
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

stock int FindSpellBook(int iClient) {
	int spellbook = -1;
	while ((spellbook = FindEntityByClassname(spellbook, "tf_weapon_spellbook")) != -1)
	{
		if (IsValidEntity(spellbook) && GetEntPropEnt(spellbook, Prop_Send, "m_hOwnerEntity") == iClient)
			if(!GetEntProp(spellbook, Prop_Send, "m_bDisguiseWeapon"))
				return spellbook;
	}
	return -1;
}