#pragma semicolon 1

/*
 * Base CS:GO plugin requirements.
 */
#include <clientprefs>
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>

/*
 * Custom include files.
 */
#include <ttt>
#include <ttt_taser>
#include <colorvariables>
#include <generics>

/*
 * Custom methodmap includes.
 */
#include <player_methodmap>

#define INVISIBILITY_MAX_LEVEL 3

Handle invisibilityTimers[MAXPLAYERS + 1] = { INVALID_HANDLE, ... };

public OnPluginStart() {
    RegisterCmds();

    LateLoadAll();

    PrintToServer("[TSR] Loaded successfully");
}

public void RegisterCmds() {
    RegConsoleCmd("sm_testinvis", Command_TestInvis, "Test invisibility");
}

public void OnClientPutInServer(int client) {
    SDKHook(client, SDKHook_TraceAttack, OnTraceAttack);
}

public OnClientDisconnect(int client)
{
    ClearTimer(invisibilityTimers[client]);
}

public void TTT_OnRoundStart(int innocents, int traitors, int detective)
{
    LoopClients(i)
    {
        CallTimer(invisibilityTimers[i]);
    }
}

public void TTT_OnRoundEnd(int winner)
{
    LoopClients(i)
    {
        CallTimer(invisibilityTimers[i]);
    }
}

public void LateLoadAll() {
    LoopValidClients(client)
    {
        SDKHook(client, SDKHook_TraceAttack, OnTraceAttack);
    }
}

// Block players from shooting if they're not allowed to shoot.
public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon) {
    if (buttons & IN_ATTACK || buttons & IN_ATTACK2) {
        Player attacker = Player(client);
        if (attacker.BlockShoot) {
            if (!attacker.ErrorTimeout(2)) {
                attacker.Msg("{red}You are not allowed to shoot whilst invulnerable!");
            }
            buttons &= ~IN_ATTACK;
            buttons &= ~IN_ATTACK2;
        }
    }

    return Plugin_Continue;
}

public Action OnTraceAttack(int iVictim, int &iAttacker, int &inflictor, float &damage, int &damagetype, int &ammotype, int hitbox, int hitgroup) {
    if (TTT_IsWorldDamage(iAttacker, damagetype)) {
        return Plugin_Continue;
    }

    Player victim = Player(iVictim);
    if (!victim.Traitor) {
        return Plugin_Continue;
    }

    Player attacker = Player(iAttacker);
    if (victim.Invulnerable) {
        // This player cannot take damage.
        if (!attacker.ErrorTimeout(2)) {
            attacker.Error("This person is invulnerable!");
        }

        damage = 0.0;

        return Plugin_Changed;
    }

    return Plugin_Continue;
}

public Action TTT_OnTased(int attacker, int victim) {
    if (TTT_GetClientRole(victim) == TTT_TEAM_TRAITOR) {
        ActivateInvisibility(victim);
    }
}

public Action Command_TestInvis(int client, int args) {
    Player player = Player(client);
    if (!player.Access(RANK_DEV, true)) {
        return Plugin_Handled;
    }

    player.Msg("Activating Invisibility!");
    ActivateInvisibility(client);

    return Plugin_Handled;
}

public void ActivateInvisibility(int client) {
    Player player = Player(client);
    int upgradeLevel = player.Skill(Skill_Invisibility, 0, INVISIBILITY_MAX_LEVEL);

    if (upgradeLevel && player.Traitor) {
        player.Msg("{yellow}Your invisibility has {green}activated!");
        player.Invisible = true;
        player.Invulnerable = true;
        player.BlockShoot = true;

        invisibilityTimers[client] = CreateTimer(2.5 * upgradeLevel, DisableInvisibility, GetClientUserId(client));

        for (float i = 0.0; i < 2.5 * upgradeLevel; i += 0.1) {
            DataPack pack;
            CreateDataTimer(i, InvisibilityCountdown, pack);
            pack.WriteCell(player.Client);
            pack.WriteFloat(i / (2.5 * upgradeLevel));
        }
    }
}

public Action InvisibilityCountdown(Handle timer, Handle pack) {
    ResetPack(pack);

    int client = ReadPackCell(pack);
    float percent = ReadPackFloat(pack);

    Player player = Player(client);

    char bar[80], progress[255];
    GetProgressBar(percent, bar);
    Format(progress, sizeof(progress), "Remaining Invisibility: [%s]", bar);

    Handle hHudText = CreateHudSynchronizer();
    SetHudTextParams(0.01, 0.01, 0.2, 255, 128, 0, 255, 0, 0.0, 0.0, 0.0);
    ShowSyncHudText(player.Client, hHudText, progress);
    CloseHandle(hHudText);
}

public void GetProgressBar(float percent, char bar[80]) {
    int bars = 20;
    int squares = RoundFloat(bars * percent);

    for (int i = 0; i < bars - squares; i++) {
        StrCat(bar, 80, "▰"); // Full Bar
    }

    for (int i = 0; i < squares; i++) {
        StrCat(bar, 80, "▱"); // Empty Bar
    }

    //CPrintToChatAll("Percent: %f Bars: %i, Squares: %i, Bar: %s", percent, bars, squares, bar);
}

public Action DisableInvisibility(Handle time, int userid) {
    int client = GetClientOfUserId(userid)
    Player player = Player(client);

    player.Msg("Your invisibility has {red}deactivated!");
    player.Invisible = false;
    player.Invulnerable = false;
    player.BlockShoot = false;
}
