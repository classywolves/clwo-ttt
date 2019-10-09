#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <cstrike>

#include <colorvariables>
#include <generics>
#include <clwo-store>
#include <clwo-store-messages>

public Plugin myinfo =
{
    name = "CLWO Store Raffle",
    author = "c0rp3n",
    description = "CLWO Store plugin to host raffle based giveaways.",
    version = "1.1.0",
    url = ""
};

ConVar g_cRaffleMin = null;

bool g_bRaffleRunning = false;

enum struct Raffle
{
    int hostid;
    int prizePool;
    ArrayList participants;
}

Raffle g_raffle;

public void OnPluginStart()
{
    g_raffle.participants = new ArrayList(1, 0);

    g_cRaffleMin = CreateConVar("clwo_store_raffle_min", "5", "The minimum amount of players on the server to run a raffle.");

    RegConsoleCmd("sm_raffle", Command_Raffle, "Hosts a raffle on the server.");
    RegAdminCmd("sm_araffle", Command_AdminRaffle, ADMFLAG_CHEATS, "Hosts a raffle on the server.");
    RegConsoleCmd("sm_rlist", Command_List, "Lists all of the players currently entered in the raffle.");
    RegConsoleCmd("sm_rdraw", Command_Draw, "Draws a winner for the raffle.");

    RegConsoleCmd("sm_join", Command_Join, "Join the current raffle.");

    AutoExecConfig(true, "store-raffle", "clwo");

    PrintToServer("[RFL] Loaded succcessfully");
}

public void OnClientPutInServer(int client)
{
    
}

public void OnClientDisconnect(int client)
{
    if (client == GetClientOfUserId(g_raffle.hostid))
    {
        Raffle_Cancel();
        return;
    }

    int userid = GetClientUserId(client);
    int index = g_raffle.participants.FindValue(userid);
    if (index)
    {
        g_raffle.participants.Erase(index);
    }
}

public Action Command_Raffle(int client, int args)
{
    if (args < 1)
    {
        CPrintToChat(client, "[SM] Usage: sm_raffle <amount>");
        return Plugin_Handled;
    }

    if (g_bRaffleRunning)
    {
        CPrintToChat(client, STORE_ERROR ... "There is already a raffle running, you will have to wait for it to finish before starting a new one.");
        return Plugin_Handled;
    }

    int reqCleints = g_cRaffleMin.IntValue;
    if (GetClientCount(true) < reqCleints)
    {
        CPrintToChat(client, STORE_ERROR ... "There must be {orange}%d {default} players on the server in order to host a raffle.", reqCleints);
        return Plugin_Handled;
    }

    char buffer[16];
    GetCmdArg(1, buffer, sizeof(buffer));
    int amount = StringToInt(buffer);

    if (Store_GetCredits(client) < amount)
    {
        CPrintToChat(client, STORE_ERROR ... "You do not have enough credits to host this raffle.");
        return Plugin_Stop;
    }
    else
    {
        Store_AddCredits(client, -amount);
    }

    Raffle_Create(client, amount);

    return Plugin_Handled;
}

public Action Command_AdminRaffle(int client, int args)
{
    if (args < 1)
    {
        CPrintToChat(client, "[SM] Usage: sm_araffle <amount>");
        return Plugin_Handled;
    }

    if (g_bRaffleRunning)
    {
        CPrintToChat(client, STORE_ERROR ... "There is already a raffle running, you will have to wait for it to finish before starting a new one.");
        return Plugin_Stop;
    }

    char buffer[16];
    GetCmdArg(1, buffer, sizeof(buffer));
    int amount = StringToInt(buffer);

    Raffle_Create(client, amount);

    return Plugin_Handled;
}

public Action Command_Join(int client, int args)
{
    if (!g_bRaffleRunning)
    {
        CPrintToChat(client, STORE_ERROR ... "There is not currently a raffle to join. Use {yellow}/raffle {default}to host one.");
        return Plugin_Stop;
    }

    if (client == GetClientOfUserId(g_raffle.hostid))
    {
        CPrintToChat(client, STORE_ERROR ... "You cannot join your own raffle.");
        return Plugin_Stop;
    }

    int userid = GetClientUserId(client);
    if (g_raffle.participants.FindValue(userid) >= 0)
    {
        CPrintToChat(client, STORE_ERROR ... "You are already entered into the current raffle.");
        return Plugin_Stop;
    }

    g_raffle.participants.Push(userid);
    CPrintToChatAll(STORE_MESSAGE ... "%N just joined {yellow}%N's {default}for {orange}%dcR {default}raffle. Use /join to enter yourself.", client, g_raffle.prizePool, GetClientOfUserId(g_raffle.hostid));

    return Plugin_Handled;
}

public Action Command_List(int client, int args)
{
    if (!g_bRaffleRunning)
    {
        CPrintToChat(client, STORE_ERROR ... "There is not currently a raffle to join. Use {yellow}/raffle {default}to host one.");
        return Plugin_Stop;
    }

    int host = GetClientOfUserId(g_raffle.hostid);
    CPrintToChat(client, STORE_MESSAGE ... "{yellow}%N's {default}raffle entrants:", host);
    for (int i = 0; i < g_raffle.participants.Length; i++)
    {
        int entrant = GetClientOfUserId(g_raffle.participants.Get(i));
        CPrintToChat(client, " - {yellow}%N", entrant);
    }

    return Plugin_Handled;
}

public Action Command_Draw(int client, int args)
{
    if (!g_bRaffleRunning)
    {
        CPrintToChat(client, STORE_ERROR ... "There is not currently a raffle to join. Use {yellow}/raffle {default}to host one.");
        return Plugin_Stop;
    }

    if (client != GetClientOfUserId(g_raffle.hostid))
    {
        CPrintToChat(client, STORE_ERROR ... "You cannot draw someone else's raffle.");
    }

    Raffle_End();

    return Plugin_Handled;
}

public void Raffle_Create(int client, int amount)
{
    g_bRaffleRunning = true;

    g_raffle.hostid = GetClientUserId(client);
    g_raffle.prizePool = amount;
    g_raffle.participants.Clear();

    CPrintToChatAll(STORE_MESSAGE ... "{yellow}%N {default}has started a raffle for {orange}%dcR. {default}Use {yellow}/join {default}to participate in the raffle.", client, amount);
}

public void Raffle_Cancel()
{
    int client = GetClientOfUserId(g_raffle.hostid);

    g_bRaffleRunning = false;
    g_raffle.hostid = -1;
    g_raffle.prizePool = -1;
    g_raffle.participants.Clear();

    CPrintToChatAll(STORE_MESSAGE ... "{yellow}%N {default}has cancelled there raffle.", client);
}

public void Raffle_End()
{
    int client = GetClientOfUserId(g_raffle.hostid);

    if (g_raffle.participants.Length < 1)
    {
        CPrintToChat(client, STORE_ERROR ... "You ended the raffle before anyone could join.");
    }
    else
    {
        int winner = -1;
        while (!IsValidClient(winner))
        {
            int index = GetRandomInt(0, g_raffle.participants.Length - 1);
            winner = GetClientOfUserId(g_raffle.participants.Get(index));
            if (!winner)
            {
                g_raffle.participants.Erase(index);
            }
        }

        Store_AddCredits(winner, g_raffle.prizePool);
        CPrintToChatAll(STORE_MESSAGE ... "{yellow}%N {default}won {orange}%dcR {default}from {yellow}%N's {default}raffle.", winner, g_raffle.prizePool, client);
    }

    g_bRaffleRunning = false;
    g_raffle.hostid = -1;
    g_raffle.prizePool = -1;
    g_raffle.participants.Clear();
}