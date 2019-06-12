#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <cstrike>

#include <ttt>
#include <colorvariables>
#include <generics>
#include <ttt_skills>

#include <math_methodmap>

#define VAMPIRE_MAX_LEVEL 4

public Plugin myinfo =
{
    name = "TTT Vampire",
    author = "Popey & c0rp3n",
    description = "TTT Vampire Skill",
    version = "0.0.1",
    url = ""
};

int spriteBeam = -1;
int spriteHalo = -1;

public OnPluginStart()
{
    PreCache();
    HookEvents();

    LoadTranslations("common.phrases");

    PrintToServer("[VMP] Loaded successfully");
}

public OnAllPluginsLoaded()
{
    Skills_RegisterSkill(Skill_Vampire, "Vampirism", "The player regains health from any damage they do onto another player.", VAMPIRE_MAX_LEVEL);
}

public void PreCache()
{
    spriteBeam = PrecacheModel("materials/sprites/laserbeam.vmt");
    spriteHalo = PrecacheModel("materials/sprites/glow.vmt");
}

public void HookEvents()
{
    LoopValidClients(i)
    {
        SDKHook(i, SDKHook_OnTakeDamagePost, HookOnTakeDamagePost);
    }
}

/*
public void InitDBs()
{

}
*/

public void OnClientPutInServer(int client)
{
    SDKHook(client, SDKHook_OnTakeDamagePost, HookOnTakeDamagePost);
}

// This function will regenerate a persons health by a percentage of any damage
//  the player does.
public void HookOnTakeDamagePost(int victim, int attacker, int inflictor, float damage, int damageType, int weapon, const float damageForce[3], const float damagePosition[3])
{
    if (!(IsValidClient(victim) || IsValidClient(attacker) || IsPlayerAlive(attacker)))
    {
        return;
    }

    int upgradeLevel = Skills_GetSkill(attacker, Skill_Vampire, 0, VAMPIRE_MAX_LEVEL);
    if (upgradeLevel < 1)
    {
        return;
    }

    int health = GetClientHealth(attacker);
    if (health >= 100)
    {
        return;
    }

    int healthGain = RoundFloat(damage * 0.0375 * upgradeLevel);

    int newHealth = Math().Min(health + healthGain, 100);
    SetEntityHealth(attacker, newHealth);

    if (GetRandomInt(0, 100) > (100 - (6 * upgradeLevel)))
    {
        float attackerOrigin[3], victimOrigin[3];
        GetClientEyePosition(attacker, attackerOrigin);
        GetClientEyePosition(victim, victimOrigin);
        attackerOrigin[2] -= 10.0;
        victimOrigin[2] -= 10.0;

        TE_SetupBeamPoints(attackerOrigin, victimOrigin, spriteBeam, spriteHalo, 0, 66, 0.2, 1.0, 20.0, 1, 0.0, {255, 0, 0, 255}, 5);
        TE_SendToAll();
    }

    CPrintToChat(attacker, "{purple}[TTT] {yellow}Vampirism!  Set your health too {blue}%d{yellow}.", newHealth);
}
