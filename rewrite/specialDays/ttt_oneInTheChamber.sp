/*
 * Base CS:GO plugin requirements.
 */
#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <timers>

/*
 * Custom include files.
 */
#include <ttt>
#include <colorvariables>
#include <generics>

/*
 * Custom methodmaps.
 */
#include <player_methodmap>
#include <ttt_specialDays>

#define OITC_ROUNDS_MIN 3
#define OITC_ROUNDS_MAX 10

public Plugin myinfo =
{
    name = "TTT One in the Chamber",
    author = "c0rp3n",
    description = "TTT Special Day One in the Chamber.",
    version = "1.0.0",
    url = ""
};

bool isDayRunning = false;
int remainingRounds = -1;

ConVar mapPlacedWeapons;
ConVar deathDropGun;

public OnPluginStart()
{


    PrintToServer("[SD1] Loaded successfully");
}

public void GetCVars()
{
    mapPlacedWeapons = FindConVar("mp_weapons_allow_map_placed");
    deathDropGun = FindConVar("mp_death_drop_gun");
}

public Action TTT_StartSpecialDay(int specialDay)
{
    if (specialDay != SPECIAL_DAY_OITC) return Plugin_Continue;

    remainingRounds = GetRandomInt(OITC_ROUNDS_MIN, OITC_ROUNDS_MAX);

    mapPlacedWeapons.SetBool(false);
    deathDropGun.SetBool(false);
    isDayRunning = true;

    return Plugin_Changed;
}

public Action TTT_StopSpecialDay()
{
    if (!isDayRunning) return Plugin_Continue;

    mapPlacedWeapons.SetBool(true);
    deathDropGun.SetBool(true);
    isDayRunning = false;

    return Plugin_Changed;
}

public bool TTT_IsSpecialDayRunning(bool isRunning)
{
    isRunning = isDayRunning;
    return Plugin_Changed;
}

public void TTT_OnRoundStart(int innocents, int traitors, int detective)
{
    if (isDayRunning)
    {
        if (remainingRounds <= 0)
        {
            TTT_StopSpecialDay();
            return;
        }

        if (remainingRounds > 1) { CPrintToChatAll("{purple}[TTT] {yellow}For the next {blue}%n {yellow}rounds One in the Chamber will be active.", remainingRounds); }
        else { CPrintToChatAll("{purple}[TTT] {yellow}This is the final round of One in the Chamber."); }

        remainingRounds--;
    }
}

public void TTT_OnClientDeath(int victim, int attacker)
{
    if (isDayRunning)
    {
        int weaponEntity = GetPlayerWeaponSlot(attacker, CS_SLOT_SECONDARY);
        if (weaponEntity != -1)
        {
            int clipSize = GetEntProp(weaponEntity, Prop_Send, "m_iClip1") + 1;
            SetEntProp(attacker, Prop_Send, "m_iAmmo", 0);
            SetEntProp(weaponEntity, Prop_Send, "m_iClip1", clipSize);
        }
    }
}
