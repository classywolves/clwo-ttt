/*
 * Base CS:GO plugin requirements.
 */
#include <sourcemod>
#include <sdktools>
#include <cstrike>

/*
 * Custom include files.
 */
#include <colorvariables>
#include <sourcecomms>
#include <generics>
#include <ttt>

public OnPluginStart()
{
  RegisterCookies();
  RegisterCmds();
  HookEvents();
  InitDBs();

  LoadTranslations("common.phrases");
  
  PrintToServer("[RNW] Loaded succcessfully");
}

public void RegisterCookies() {
  cookieInnocentWins = RegClientCookie("innocent_wins", "Number of wins the innocent has.", CookieAccess_Private);
  cookieDetectiveWins = RegClientCookie("detective_wins", "Number of wins the detective has.", CookieAccess_Private);
  cookieTraitorWins = RegClientCookie("traitor_wins", "Number of wins the traitor has.", CookieAccess_Private);

  cookieInnocentLosses = RegClientCookie("innocent_losses", "Number of losses the innocent has.", CookieAccess_Private);
  cookieDetectiveLosses = RegClientCookie("detective_losses", "Number of losses the detective has.", CookieAccess_Private);
  cookieTraitorLosses = RegClientCookie("traitor_losses", "Number of losses the traitor has.", CookieAccess_Private);
}

public void RegisterCmds() {
}

public void HookEvents() {
}

public void InitDBs() {
}

public void TTT_OnRoundEnd(int winner) {
  LoopClients(client) {
    Player player = Player(client);

    if (winner == TRAITOR) {
      if (player.Traitor) player.TraitorWins++;
      if (player.Innocent) player.InnocentLosses++;
      if (player.Detective) player.DetectiveLosses++;
    } else {
      if (player.Traitor) player.TraitorLosses++;
      if (player.Innocent) player.InnocentWins++;
      if (player.Detective) player.DetectiveWins++;
    }
  }
}