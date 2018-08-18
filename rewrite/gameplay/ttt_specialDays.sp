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

public Plugin myinfo =
{
    name = "TTT Special Days",
    author = "c0rp3n",
    description = "TTT Special Days API.",
    version = "1.0.0",
    url = ""
};

Handle startSpecialDayForward;
Handle stopSpecialDayForward;

int specialDay = -1;

public OnPluginStart()
{
    RegisterCmds();
    
    PrintToServer("[SPD] Loaded successfully");
}

public APLRes AskPluginLoad2(Handle plugin, bool late, char[] error, int err_max)
{
    RegPluginLibrary("ttt_specialDays");
    
    startSpecialDayForward = CreateGlobalForward("TTT_StartSpecialDay", ET_Event, Param_Cell);
    stopSpecialDayForward = CreateGlobalForward("TTT_StopSpecialDay", ET_Event);
    
    return APLRes_Success;
}

public void RegisterCmds() {
    RegConsoleCmd("sm_startday", Command_StartDay, "Allows an admin to trigger a special day.");
    RegConsoleCmd("sm_stopday", Command_StopDay, "Allows an admin to stop a special day.");
}

// Called after MapStart and any CVars will have been set and registered thus is safe to call any Special Day.
public void OnConfigsExecuted()
{
    if (SPECIAL_DAY_COUNT) {
        if (GetRandomInt(0, 5) == 1)
        {
            specialDay = GetRandomInt(0, SPECIAL_DAY_COUNT);
    
            Action result = Plugin_Continue;
            
            Call_StartForward(startSpecialDayForward);
            Call_PushCell(specialDay);
            Call_Finish(result);
    
            if (result == Plugin_Stop || result == Plugin_Changed)
            {
                PrintToServer("Failed to start Special Day: %n", specialDay);
                return;
            }
    
            PrintToServer("Started Special Day: %n", specialDay);
        }
        else
        {
            specialDay = -1;
        }
    }
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
    
        if (result == Plugin_Stop || result == Plugin_Changed)
        {
            player.Msg("Failed to stop Special Day: %n", specialDay);
            PrintToServer("Failed to stop Special Day: %n", specialDay);
            return Plugin_Handled;
        }
    }
    
    Call_StartForward(startSpecialDayForward);
    Call_PushCell(specialDay);
    Call_Finish(result);
    
    if (result == Plugin_Stop || result == Plugin_Changed)
    {
        player.Msg("Failed to start Special Day: %n", specialDay);
        PrintToServer("Failed to start Special Day: %n", specialDay);
        return Plugin_Handled;
    }
    
    player.Msg("Started Special Day: %n", specialDay);
    PrintToServer("Started Special Day: %n", specialDay);
    
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
    
    if (result == Plugin_Stop || result == Plugin_Changed)
    {
        player.Msg("Failed to stop Special Day: %n", specialDay);
        PrintToServer("Failed to stop Special Day: %n", specialDay);
        return Plugin_Handled;
    }
    
    player.Msg("Stopped Special Day: %n", specialDay);
    PrintToServer("Stopped Special Day: %n", specialDay);
    
    return Plugin_Handled;
}
