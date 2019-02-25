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

public Plugin myinfo =
{
    name = "TTT Blood Lust",
    author = "c0rp3n",
    description = "TTT Bloodlust Traitor anti delaying mechanism.",
    version = "0.0.1",
    url = ""
};

Handle bloodLustTimers[MAXPLAYERS+1] = { INVALID_HANDLE, ... };

//char traitorOverlay[PLATFORM_MAX_PATH] = "darkness/ttt/overlayTraitor";
//char traitorBloodLustOverlay[PLATFORM_MAX_PATH] = "corpen/ttt/overlayTraitorBloodLust";

float bloodLustStartTime = 45.0;
float bloodLustFinalTime = 30.0;

public OnPluginStart() {
    //PreCache();
    //HookEvents();

    PrintToServer("[BLM] Loaded successfully");
}

public void OnAllPluginsLoaded() {
    /*
    if (!LibraryExists("ttt_overlay")) {
    char sBuffer[PLATFORM_MAX_PATH];

    Format(sBuffer, sizeof(sBuffer), "materials/%s.vmt", traitorOverlay);
    AddFileToDownloadsTable(sBuffer);
    Format(sBuffer, sizeof(sBuffer), "materials/%s.vtf", traitorOverlay);
    AddFileToDownloadsTable(sBuffer);
    PrecacheDecal(traitorOverlay, true);
}
*/
}

public void PreCache() {
    /*
    char sBuffer[PLATFORM_MAX_PATH];

    Format(sBuffer, sizeof(sBuffer), "materials/%s.vmt", traitorBloodLustOverlay);
    AddFileToDownloadsTable(sBuffer);
    Format(sBuffer, sizeof(sBuffer), "materials/%s.vtf", traitorBloodLustOverlay);
    AddFileToDownloadsTable(sBuffer);
    PrecacheDecal(traitorBloodLustOverlay, true);
    */
}

public void TTT_OnRoundStart(int innocents, int traitors) {
    LoopClients(i) {
        if (TTT_GetClientRole(i) == TTT_TEAM_TRAITOR) {
            bloodLustTimers[i] = CreateTimer(bloodLustStartTime, BloodLustStart, i);
        }
        else {
            ClearTimer(bloodLustTimers[i]);
        }
    }
}

public void TTT_OnClientDeath(int victim, int attacker) {
    if (TTT_GetClientRole(attacker) == TTT_TEAM_TRAITOR)
    {
        ClearTimer(bloodLustTimers[attacker]);

        BloodLustReset(attacker);
        bloodLustTimers[attacker] = CreateTimer(bloodLustStartTime, BloodLustStart, GetClientUserId(attacker));
    }
}

public void TTT_OnRoundEnd(int winner) {
    LoopValidClients(i)
    {
        ClearTimer(bloodLustTimers[i]);
    }
}

public Action BloodLustStart(Handle timer, int userid) {
    int client = GetClientOfUserId(userid);
    if (!(TTT_GetClientRole(client) == TTT_TEAM_TRAITOR || IsAliveClient(client))) {
        ClearTimer(bloodLustTimers[client]);

        return Plugin_Continue;
    }

    CPrintToChat(client, "{purple}[TTT] {red}You are longing for blood!  Better kill again soon, lest there lie concequences.");
    //ShowOverlayToClient(client, traitorBloodLustOverlay);
    BloodLustScreenColor(client);
    ClearTimer(bloodLustTimers[client]);
    bloodLustTimers[client] = CreateTimer(bloodLustFinalTime, BloodLustFinal, GetClientUserId(client));

    return Plugin_Continue;
}

public Action BloodLustFinal(Handle timer, int userid) {
    int client = GetClientOfUserId(userid);
    if (!(TTT_GetClientRole(client) == TTT_TEAM_TRAITOR || IsAliveClient(client))) {
        ClearTimer(bloodLustTimers[client]);

        return Plugin_Continue;
    }

    CPrintToChat(client, "{purple}[TTT] {red}You have gone without blood for too long; you are now revealed to the players around you.");
    SetEntityRenderColor(client, 255, 0, 0, 255);
    ClearTimer(bloodLustTimers[client]);

    return Plugin_Continue;
}

public void BloodLustReset(int client) {
    SetEntityRenderColor(client, 255, 255, 255, 255);
    //ShowOverlayToClient(client, traitorOverlay);
    ClearScreenColor(client);
}

public void BloodLustScreenColor(int client) {
    Player player = Player(client);

    int color[4] = { 255, 0, 0 , 63 };
    int duration = 480;
    int holdTime = 120000;
    int flags = 0x0001 | 0x0008; // fade in and stay out.

    player.SetScreenColor(color, duration, holdTime, flags);
}

public void ClearScreenColor(int client) {
    Player player = Player(client);

    int color[4] = { 0, 0, 0 , 0 };
    int duration = 0;
    int holdTime = 0;
    int flags = 0x0010; // purge.

    player.SetScreenColor(color, duration, holdTime, flags);
}
