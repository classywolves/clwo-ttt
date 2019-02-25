#pragma semicolon 1

/*
 * Base CS:GO plugin requirements.
 */
#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <cstrike>

/*
 * Custom include files.
 */
#include <ttt>
#include <colorvariables>
#include <generics>

/*
 * Custom methodmap includes.
 */
#include <player_methodmap>

#define REDUCED_FALLING_MAX_LEVEL 4

public Plugin myinfo =
{
    name = "TTT Reduced Fall Damage",
    author = "Popey & c0rp3n",
    description = "TTT Reduced Fall Damage Skill",
    version = "0.0.1",
    url = ""
};

public OnPluginStart()
{
    //RegisterCmds();
    HookEvents();
    //InitDBs();

    LoadTranslations("common.phrases");

    PrintToServer("[FAL] Loaded successfully");
}

/*
public void RegisterCmds()
{

}
*/

public void HookEvents()
{
    LoopValidClients(client) {
        OnClientPutInServer(client);
    }
}

/*
public void InitDBs()
{

}
*/

public void OnClientPutInServer(int client) {
    SDKHook(client, SDKHook_OnTakeDamageAlive, HookOnTakeDamage);
}

public Action HookOnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, const float damageForce[3], const float damagePosition[3], int damagecustom) {
    // We only care for fall damage here.
    if (!(damagetype & DMG_FALL)) {
        return Plugin_Continue;
    }

    Player player = Player(victim);
    int upgradeLevel = player.Skill(Skill_ReducedFallDamage, 0, REDUCED_FALLING_MAX_LEVEL);

    if (upgradeLevel <= 0) {
        return Plugin_Continue;
    }

    float reducePercent = 0.2 * float(upgradeLevel);

    if (reducePercent >= 1.0) {
        return Plugin_Handled;
    }

    float oldDamage = damage;
    damage -= damage * reducePercent;

    CPrintToChat(victim, "{purple}[TTT] {yellow}Feather falling reduced your damage from {blue}%.0f {yellow}to {blue}%.0f{yellow}.", oldDamage, damage);
    return Plugin_Changed;
}
