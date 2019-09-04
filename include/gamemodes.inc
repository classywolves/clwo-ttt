#pragma semicolon 1

#if !defined _ttt_included
    #include <ttt>
#endif

stock void SetUpTeams(int ratio = 2, int aTeam = TTT_TEAM_DETECTIVE, int bTeam = TTT_TEAM_TRAITOR)
{
    ArrayList aList = new ArrayList(1, 0);
    ArrayList bList = new ArrayList(1, 0);

    LoopValidClients(i)
    {
        if(!IsPlayerAlive(i))
        {
            continue;
        }
        aList.Push(i);
    }

    int num = aList.Length/ratio;

    for(int i = 0; i < num; i++)
    {
        int index = Math_GetRandomInt(0, aList.Length);
        int random = aList.Get(index, 0);
        aList.Erase(index);
        bList.Push(random);
    }

    for(int a = 0; a < aList.Length; a++)
    {
        int aplayer  = aList.Get(a);
        if(TTT_GetClientRole(aplayer) != aTeam)
        {
            TTT_SetClientRole(aplayer, aTeam);
        }
    }

    for(int b = 0; b < bList.Length; b++)
    {
        int bplayer  = bList.Get(b);
        if(TTT_GetClientRole(bplayer) != bTeam)
        {
            TTT_SetClientRole(bplayer, bTeam);
        }
    }
}

stock void GiveHeavy(int team)
{
    LoopValidClients(i)
    {
        if(TTT_GetClientRole(i) == team)
        {
            GivePlayerItem(i, "item_heavyassaultsuit");
        }   
    }
}

stock void SetHealth(int ctTeamHP = 100, int tTeamHP = 100)
{
    LoopValidClients(i)
    {
        if(TTT_GetClientRole(i) == TTT_TEAM_DETECTIVE)
        {
            SetEntityHealth(i, ctTeamHP);
        }
        if(TTT_GetClientRole(i) == TTT_TEAM_TRAITOR)
        {
            SetEntityHealth(i, tTeamHP);
        }   
    }
        
    CPrintToChatAll("[INFO] {darkblue}CT {default}health: {orange}%i", ctTeamHP);
    CPrintToChatAll("[INFO] {darkred}T {default}health: {orange}%i", tTeamHP);
}

stock void SetSpeed(int team, float speed = 1.0)
{
    LoopValidClients(i)
    {
        if(TTT_GetClientRole(i) == team)
        {
            SetEntPropFloat(i, Prop_Send, "m_flLaggedMovementValue", speed);
        }   
    }   
}

stock void SetGravity(int team, float gravity = 1.0)
{
    LoopValidClients(i)
    {
        if(TTT_GetClientRole(i) == team)
        {
            SetEntityGravity(i, gravity);
        }   
    }   
}