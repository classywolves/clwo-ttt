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

#define KOTH_MIN_ROUNDS 5
#define KOTH_MAX_ROUNDS 10

public Plugin myinfo =
{
    name = "TTT King of the Hill Day",
    author = "c0rp3n",
    description = "TTT Special Day of King of the Hill.",
    version = "1.0.0",
    url = ""
};

bool isDayRunning = false;
int remainingRounds = -1;

public OnPluginStart()
{
    
    
    PrintToServer("[SDB] Loaded successfully");
}

public Action TTT_StartSpecialDay(int specialDay)
{
    if (specialDay != SPECIAL_DAY_KOTH) return Plugin_Continue;
    
    remainingRounds = GetRandomInt(KOTH_MIN_ROUNDS, KOTH_MAX_ROUNDS);
    
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
        
        if (remainingRounds > 1) { CPrintToChatAll("{purple}[TTT] {yellow}For the next {blue}%n {yellow}rounds King of the Hill will be active.", remainingRounds); }
        else { CPrintToChatAll("{purple}[TTT] {yellow}For the next round King of the Hill will be active."); }
        
        remainingRounds--;
    }
}
