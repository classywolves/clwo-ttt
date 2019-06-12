#pragma semicolon 1

/*
 * Base CS:GO plugin requirements.
 */
#include <sourcemod>
#include <sdktools>
#include <cstrike>

/*
 * Custom include files.
 */
#include <colorvariables>
#include <sourcecomms>
#include <generics>

char maps[][] =
{
    "ttt_dtk_streets_v2",
    //"ttt_princess_skyscraper4",
    "de_mirage",
    "ttt_screamcastle_final"
};

char guns[][64] =
{
    "weapon_ak47",
    "weapon_aug",
    "weapon_bizon",
    "weapon_deagle",
    "weapon_decoy",
    "weapon_elite",
    "weapon_famas",
    "weapon_fiveseven",
    "weapon_flashbang",
    "weapon_g3sg1",
    "weapon_galilar",
    "weapon_glock",
    "weapon_hegrenade",
    "weapon_hkp2000",
    "weapon_incgrenade",
    "weapon_knife",
    "weapon_m249",
    "weapon_m4a1",
    "weapon_mac10",
    "weapon_mag7",
    "weapon_molotov",
    "weapon_mp7",
    "weapon_mp9",
    "weapon_negev",
    "weapon_nova",
    "weapon_p250",
    "weapon_p90",
    "weapon_sawedoff",
    "weapon_scar20",
    "weapon_sg556",
    "weapon_smokegrenade",
    "weapon_ssg08",
    "weapon_taser",
    "weapon_tec9",
    "weapon_ump45",
    "weapon_xm1014"
};

public OnPluginStart()
{
    RegisterCmds();
    HookEvents();
    InitDBs();

    LoadTranslations("common.phrases");

    PrintToServer("[RNG] Loaded succcessfully");
}

public void RegisterCmds()
{
    RegAdminCmd("sm_rguns", Command_RandomGuns, ADMFLAG_CHANGEMAP, "Give all players a random gun!");
}

public void HookEvents()
{
}

public void InitDBs()
{
}

public Action Command_RandomGuns(int client, int args)
{
    // Usage is "/rguns"
    giveRandomGuns();

    return Plugin_Handled;
}

public void TTT_OnRoundStart()
{
	char map[256];
	GetCurrentMap(map, sizeof(map));

	if (inArray(maps, sizeof(maps), map))
    {
		giveRandomGuns();
		giveRandomGuns();
		giveRandomGuns();
	}
}

public bool inArray(char[][] array, int arraySize, char[] value)
{
	for (int i = 0; i < arraySize; i++)
    {
		if (StrEqual(array[i], value))
        {
			return true;
		}
	}

	return false;
}

public void giveRandomGuns()
{
	LoopAliveClients(i)
    {
		GivePlayerItem(i, guns[GetRandomInt(0, sizeof(guns) - 1)]);
	}
}
