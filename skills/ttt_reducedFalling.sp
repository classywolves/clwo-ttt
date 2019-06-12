#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <cstrike>

#include <colorvariables>
#include <generics>
#include <ttt_skills>

#define REDUCED_FALLING_MAX_LEVEL 4

public Plugin myinfo =
{
    name = "TTT Reduced Fall Damage",
    author = "Popey & c0rp3n",
    description = "TTT Reduced Fall Damage Skill",
    version = "1.0.0",
    url = ""
};

public OnPluginStart()
{
    HookEvents();

    LoadTranslations("common.phrases");

    PrintToServer("[FLL] Loaded successfully");
}

public OnAllPluginsLoaded()
{
    Skills_RegisterSkill(Skill_ReducedFallDamage, "Feather Falling", "Reduces the amount of damage taken from fall damage.", REDUCED_FALLING_MAX_LEVEL);
}

public void HookEvents()
{
    LoopValidClients(i)
    {
        SDKHook(i, SDKHook_OnTakeDamageAlive, HookOnTakeDamage);
    }
}

public void OnClientPutInServer(int client)
{
    SDKHook(client, SDKHook_OnTakeDamageAlive, HookOnTakeDamage);
}

public Action HookOnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, const float damageForce[3], const float damagePosition[3], int damagecustom)
{
    // We only care for fall damage here.
    if (!(damagetype & DMG_FALL))
    {
        return Plugin_Continue;
    }

    int upgradeLevel = Skills_GetSkill(victim, Skill_ReducedFallDamage, 0, REDUCED_FALLING_MAX_LEVEL);
    if (upgradeLevel <= 0)
    {
        return Plugin_Continue;
    }

    float oldDamage = damage;
    damage -= damage * (0.2 * float(upgradeLevel));

    CPrintToChat(victim, "{purple}[TTT] {yellow}Feather falling reduced your damage from {green}%.0f {yellow}to {green}%.0f{yellow}.", oldDamage, damage);
    return Plugin_Changed;
}
