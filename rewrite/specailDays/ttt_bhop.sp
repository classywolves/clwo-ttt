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

#define AUTO_BHOP_ROUNDS_MIN 1
#define AUTO_BHOP_ROUNDS_MAX 5

public Plugin myinfo =
{
    name = "TTT BHop Day",
    author = "c0rp3n",
    description = "TTT Special Day of auto BHop.",
    version = "1.0.0",
    url = ""
};

bool isDayRunning = false;
int remainingRounds = -1;

ConVar autoBHop;
ConVar enableBHop;

public OnPluginStart()
{
    GetCVars();
    
    PrintToServer("[SDB] Loaded successfully");
}

public void GetCVars()
{
    autoBHop = FindConVar("sv_autobunnyhopping");
    enableBHop = FindConVar("sv_enablebunnyhopping");
}

public Action TTT_StartSpecialDay(int specialDay)
{
    if (specialDay != SPECIAL_DAY_BHOP) return Plugin_Continue;
    
    remainingRounds = GetRandomInt(AUTO_BHOP_MIN_ROUNDS, AUTO_BHOP_MAX_ROUNDS);
    
    SetConVarBool(autoBHop, true);
    SetConVarBool(enableBHop, true);
    isDayRunning = true;
    
    return Plugin_Handled;
}

public Action TTT_StopSpecialDay()
{
    if (!isDayRunning) return Plugin_Continue;
    
    SetConVarBool(autoBHop, false);
    SetConVarBool(enableBHop, false);
    isDayRunning = false;
    
    return Plugin_Handled;
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
        
        if (remainingRounds > 1) { CPrintToChatAll("{purple}[TTT] {yellow}For the next {blue}%n {yellow}rounds auto BHop will be enabled.", remainingRounds); }
        else { CPrintToChatAll("{purple}[TTT] {yellow}For the next round auto BHop will be enabled."); }
        
        remainingRounds--;
    }
}
