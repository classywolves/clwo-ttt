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

#define AUTO_BHOP_MIN_ROUNDS 1
#define AUTO_BHOP_MAX_ROUNDS 5

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

public OnPluginStart()
{
    GetCVars();
    
    PrintToServer("[SDB] Loaded successfully");
}

public void GetCVars()
{
    matFullbright = FindConVar("sv_autobunnyhopping");
}

public Action TTT_StartSpecialDay(int specialDay)
{
    if (specialDay != SPECIAL_DAY_BHOP) return Plugin_Continue;
    
    remainingRounds = GetRandomInt(AUTO_BHOP_MIN_ROUNDS, AUTO_BHOP_MAX_ROUNDS);
    
    SetAutoBHop(true);
    isDayRunning = true;
}

public Action TTT_StopSpecialDay()
{
    if (!isDayRunning) return Plugin_Continue;
    
    SetAutoBHop(false);
    isDayRunning = false;
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

public void SetAutoBHop(bool enabled)
{
    int iFlags = autoBHop.Flags;
    autoBHop.Flags = iFlags &~ FCVAR_CHEAT;
    
    autoBHop.SetBool(enabled, true, false);
    
    autoBHop.Flags = iFlags | FCVAR_CHEAT;
}
