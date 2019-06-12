/*
 * Base CS:GO plugin requirements.
 */
#include <sourcemod>
#include <sdktools>
#include <cstrike>

/*
 * Custom include files.
 */
#include <ttt>
#include <colorvariables>
#include <generics>

Handle cookieInnocentWins;
Handle cookieDetectiveWins;
Handle cookieTraitorWins;
Handle cookieInnocentLosses;
Handle cookieDetectiveLosses;
Handle cookieTraitorLosses;

public OnPluginStart()
{
    RegisterCookies();

    LoadTranslations("common.phrases");

    PrintToServer("[RNW] Loaded succcessfully");
}

public void RegisterCookies()
{
    cookieInnocentWins = RegClientCookie("innocent_wins", "Number of wins the innocent has.", CookieAccess_Private);
    cookieDetectiveWins = RegClientCookie("detective_wins", "Number of wins the detective has.", CookieAccess_Private);
    cookieTraitorWins = RegClientCookie("traitor_wins", "Number of wins the traitor has.", CookieAccess_Private);

    cookieInnocentLosses = RegClientCookie("innocent_losses", "Number of losses the innocent has.", CookieAccess_Private);
    cookieDetectiveLosses = RegClientCookie("detective_losses", "Number of losses the detective has.", CookieAccess_Private);
    cookieTraitorLosses = RegClientCookie("traitor_losses", "Number of losses the traitor has.", CookieAccess_Private);
}

public void TTT_OnRoundEnd(int winner)
{
    LoopClients(client)
    {
        int role = TTT_GetClientRole(client);
        if (winner == TTT_TEAM_TRAITOR)
        {
            if (role == TTT_TEAM_TRAITOR) SetClientCookieInt(client, cookieTraitorWins, GetClientCookieInt(client, cookieTraitorWins) + 1);
            if (role == TTT_TEAM_INNOCENT) SetClientCookieInt(client, cookieInnocentWins, GetClientCookieInt(client, cookieInnocentWins) + 1);
            if (role == TTT_TEAM_DETECTIVE) SetClientCookieInt(client, cookieDetectiveWins, GetClientCookieInt(client, cookieDetectiveWins) + 1);
        }
        else
        {
            if (role == TTT_TEAM_TRAITOR) SetClientCookieInt(client, cookieTraitorLosses, GetClientCookieInt(client, cookieTraitorLosses) + 1);
            if (role == TTT_TEAM_INNOCENT) SetClientCookieInt(client, cookieInnocentLosses, GetClientCookieInt(client, cookieInnocentLosses) + 1);
            if (role == TTT_TEAM_DETECTIVE) SetClientCookieInt(client, cookieDetectiveLosses, GetClientCookieInt(client, cookieDetectiveLosses) + 1);
        }
    }
}