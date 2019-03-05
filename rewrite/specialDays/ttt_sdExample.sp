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
#include <ttt_specialDays>

/*
 * Custom methodmaps.
 */
#include <player_methodmap>

#define EXAMPLE_ROUNDS_MIN 1
#define EXAMPLE_ROUNDS_MAX 5

public Plugin myinfo =
{
    name = "TTT Example Day",
    author = "c0rp3n",
    description = "TTT Special Days Example.",
    version = "1.0.0",
    url = ""
};

bool isDayRunning = false;
int remainingRounds = -1;

public OnPluginStart()
{
    //GetCVars();

    PrintToServer("[SDE] Loaded successfully");
}

/*
public void GetCVars()
{

}
*/

public Action TTT_StartSpecialDay(int specialDay)
{
    if (specialDay != SPECIAL_DAY_EXAMPLE) return Plugin_Continue;

    remainingRounds = GetRandomInt(EXAMPLE_ROUNDS_MIN, EXAMPLE_ROUNDS_MAX);
    isDayRunning = true;

    return Plugin_Changed;
}

public Action TTT_StopSpecialDay()
{
    if (!isDayRunning) return Plugin_Continue;

    isDayRunning = false;

    return Plugin_Changed;
}

public bool TTT_IsSpecialDayRunning(bool isRunning)
{
    isRunning = isDayRunning;
    return Plugin_Changed;
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

        if (remainingRounds > 1) { CPrintToChatAll("{purple}[TTT] {yellow}For the next {blue}%n {yellow}rounds Example will be enabled.", remainingRounds); }
        else { CPrintToChatAll("{purple}[TTT] {yellow}For the next round auto Example will be enabled."); }

        remainingRounds--;
    }
}
