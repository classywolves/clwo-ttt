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
#include <math_methodmap>
#include <player_methodmap>

#define VAMPIRE_MAX_LEVEL 4

int spriteBeam = -1;
int spriteHalo = -1;

public Plugin myinfo =
{
    name = "TTT Vampire",
    author = "Popey & c0rp3n",
    description = "TTT Vampire Skill",
    version = "0.0.1",
    url = ""
};

public OnPluginStart()
{
    PreCache();
    //RegisterCmds();
    HookEvents();
    //InitDBs();

    LoadTranslations("common.phrases");

    PrintToServer("[VMP] Loaded successfully");
}

public void PreCache()
{
    spriteBeam = PrecacheModel("materials/sprites/laserbeam.vmt");
    spriteHalo = PrecacheModel("materials/sprites/glow.vmt");
}

/*
public void RegisterCmds()
{

}
*/

public void HookEvents()
{
    LoopValidClients(i)
    {
        HookDamage(i);
    }
}

public void HookDamage(int client)
{
    SDKHook(client, SDKHook_OnTakeDamagePost, HookOnTakeDamagePost);
}

/*
public void InitDBs()
{

}
*/

public void OnClientPutInServer(int client)
{
    HookDamage(client);
}

// This function will regenerate a persons health by a percentage of any damage
//  the player does.
public void HookOnTakeDamagePost(int victim, int attacker, int inflictor, float damage, int damageType, int weapon, const float damageForce[3], const float damagePosition[3])
{
    Player playerVictim = Player(victim);
    Player playerAttacker = Player(attacker);

    if (!(playerVictim.ValidClient || playerAttacker.ValidClient || playerAttacker.Alive))
    return;

    int upgradeLevel = playerAttacker.Skill(Skill_Vampire, 0, VAMPIRE_MAX_LEVEL);
    if (!upgradeLevel)
    return;

    int health = playerAttacker.Health;
    int maxHealth = playerAttacker.MaxHealth;
    if (health >= maxHealth)
    return;

    int healthGain = (int)RoundFloat(damage * 0.0375 * upgradeLevel);

    int newHealth = Math().Min(health + healthGain, maxHealth);
    playerAttacker.Health = newHealth;

    if (GetRandomInt(0, 100) > (100 - (6 * upgradeLevel)))
    {
        float attackerOrigin[3], victimOrigin[3];
        playerAttacker.Pos(attackerOrigin);
        playerVictim.Pos(victimOrigin);
        attackerOrigin[2] -= 10.0;
        victimOrigin[2] -= 10.0;

        TE_SetupBeamPoints(attackerOrigin, victimOrigin, spriteBeam, spriteHalo, 0, 66, 0.2, 1.0, 20.0, 1, 0.0, {255, 0, 0, 255}, 5);
        TE_SendToAll();
    }

    CPrintToChat(attacker, "{purple}[TTT] {yellow}Vampirism!  Set your health too {blue}%d{yellow}.", newHealth);
}
