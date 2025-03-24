#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <timers>

#include <ttt>
#include <colorvariables>
#include <generics>

public Plugin myinfo =
{
    name = "TTT Special Days",
    author = "c0rp3n",
    description = "TTT Special Days API.",
    version = "1.0.0",
    url = ""
};

ArrayList g_aSpecialDays = null;

StringMap g_smSpecialDayIndexMap = null;

GlobalForward g_StartSpecialDayForward;
GlobalForward g_StopSpecialDayForward;

int specialDay = -1;

enum struct SpecialDay
{
    char id[16];
    char name[64];
    char description[192];
};

public APLRes AskPluginLoad2(Handle plugin, bool late, char[] error, int err_max)
{
    startSpecialDayForward = CreateGlobalForward("TTT_StartSpecialDay", ET_Event, Param_Cell);
    stopSpecialDayForward = CreateGlobalForward("TTT_StopSpecialDay", ET_Event);

    CreateNative("TTT_IsSpecialDay");

    RegPluginLibrary("special-days");

    return APLRes_Success;
}

public OnPluginStart()
{
    RegisterCmds();

    PrintToServer("[SPD] Loaded successfully");
}

public void RegisterCmds()
{
    RegConsoleCmd("sm_startday", Command_StartDay, "Allows an admin to trigger a special day.");
    RegConsoleCmd("sm_stopday", Command_StopDay, "Allows an admin to stop a special day.");
}

public bool Native_IsSpecailDay(Handle plugin, int numParams)
{
    bool isRunning = false;

    Action result = Plugin_Continue;
    Call_StartForward(g_hOnCheckCommandAccess);
    Call_PushCellRef(isRunning);
    Call_Finish(result);

    if (result == Plugin_Changed)
    {
        return isRunning;
    }

    return false;
}

public Action Command_StartDay(int client, int args)
{
    Player player = Player(client);
    if (player.Access(RANK_ADMIN, true)) return Plugin_Handled;

    if (args < 1)
    {
        player.Error("Usage: sm_startday <specialDayIndex>");
        return Plugin_Handled;
    }

    if (specialDay == -1)
    {
        player.Error("No Special Day was active at this time.");
        return Plugin_Handled;
    }

    Action result = Plugin_Continue;

    // Stop any other active special days.
    if (specialDay != -1)
    {
        Call_StartForward(stopSpecialDayForward);
        Call_Finish(result);

        if (result == Plugin_Changed)
        {
            player.Msg("Special Day %n was running.", specialDay);
            PrintToServer("Special Day %n was running.", specialDay);
            return Plugin_Handled;
        }
    }

    result = Plugin_Continue;

    Call_StartForward(startSpecialDayForward);
    Call_PushCell(specialDay);
    Call_Finish(result);

    if (result == Plugin_Changed)
    {
        player.Msg("Started Special Day: %n", specialDay);
        PrintToServer("Started Special Day: %n", specialDay);
    }
    else
    {
        player.Msg("Failed to start Special Day: %n", specialDay);
        PrintToServer("Failed to start Special Day: %n", specialDay);
    }

    return Plugin_Handled;
}

public Action Command_StopDay(int client, int args)
{
    Player player = Player(client);
    if (player.Access(RANK_ADMIN, true)) return Plugin_Handled;

    if (specialDay == -1)
    {
        player.Error("No Special Day was active at this time.");
        return Plugin_Handled;
    }

    Action result = Plugin_Continue;

    Call_StartForward(stopSpecialDayForward);
    Call_Finish(result);

    if (result == Plugin_Changed)
    {
        player.Msg("Stopped Special Day: %n", specialDay);
        PrintToServer("Stopped Special Day: %n", specialDay);
    }
    else
    {
        player.Msg("Failed to stop Special Day: %n", specialDay);
        PrintToServer("Failed to stop Special Day: %n", specialDay);
    }

    return Plugin_Handled;
}
