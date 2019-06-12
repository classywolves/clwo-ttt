//Base CS:GO Plugin Requirements
#include <sourcemod>
#include <sdktools>
#include <cstrike>

//Custom includes
#include <ttt>
#include <ttt_shop>
#include <ttt_messages>
#include <generics>
#include <colorvariables>

public Plugin myinfo = 
{
    name = "TTT Karma Upgrades",
    author = "D0G :3",
    description = "Player upgrades rewarded based on Karma",
    version = "0.0.1",
    url = ""
};

public void TTT_OnRoundStart()
{
    int hpKarmaReward = 110
    int creditKarmaReward = 400
    
    LoopValidClients(i)
    {   
        int clientKarma = TTT_GetClientKarma(i)
        if (clientKarma >= 10000)
        {
            SetEntityHealth(i, hpKarmaReward);
            TTT_AddClientCredits(i, creditKarmaReward);
            TTT_Message(i, "Due to your high karma, you recieved some extra health and credits!");
        }
    }
}