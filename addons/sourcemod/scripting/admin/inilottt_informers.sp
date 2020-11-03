#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>

#include <generics>
#include <ttt_ranks>
#include <ttt_messages>
#include <colorlib>
#include <sourcecomms>
#include <informers>

//ConVar cv_info_var_online_staff;

#define REQBL 11
#define REQWL 9

char g_cRequestBlacklist[REQBL][] = { //If commands and arguements include any of these phrases, the request won't go through
        {"rcon"}, {"cvar"}, {"convar"}, {"@"}, {"password"}, {"address"}, {"map"}, {"set"}, {"%"}, {";"}, {"/"}
};

char g_cRequestWhitelist[REQWL][] = { //If commands and arguements aren't any of these commands, the request won't go through
        {"slap"}, {"slay"}, {"burn"}, {"wep"}, {"yeet"}, {"cuck"}, {"barrel"}, {"turret"}, {"beep"}
};

public void OnPluginStart()
{
    informers_RegisterCvars();
    informers_RegisterCmds();
    informers_HookEvents();
    //post
    informers_PostPluginStart();
}

public void informers_PostPluginStart()
{
    //PrintToChatAll(" \x03[\x01%s\x03] \x01>\x06 online ✔\x01<","Informer powers");
}
public void informers_RegisterCvars()
{
    //cv_info_var_online_staff = CreateConVar("Staff_online", "#unknown#", "" );
    //cv_info_var_online_staff = CreateConVar("Staff_online", "#unknown#", "",FCVAR_NOTIFY );
}
public void informers_HookEvents()
{

}
public void informers_RegisterCmds()
{
    RegAdminCmd("sm_islay", Command_InformerSlay, ADMFLAG_GENERIC, "sm_islay <target>");
    RegAdminCmd("sm_imute", Command_InformerMute, ADMFLAG_GENERIC, "sm_imute <target> <time> <reason>");
    RegAdminCmd("sm_igag", Command_InformerMute, ADMFLAG_GENERIC, "sm_igag <target> <time> <reason>");
    RegAdminCmd("sm_itest", Command_InformerTest, ADMFLAG_SLAY, "sm_islay <target>");
    RegAdminCmd("sm_adopt", Command_InformerAdopt, ADMFLAG_VOTE, "sm_adopt <player>");
    RegAdminCmd("sm_empower", Command_InformerEmpower, ADMFLAG_CONVARS, "sm_empower <player>");
    RegAdminCmd("sm_request", Command_InformerRequest, ADMFLAG_VOTE, "sm_request [command info]");
    RegConsoleCmd("sm_adoptions", Command_InformerAdoptions,"sm_adoptions");
    RegAdminCmd("sm_orphan", Command_InformerOrphan, ADMFLAG_VOTE, "sm_orphan");

    RegAdminCmd("access_request", Command_Blank, ADMFLAG_VOTE, "Access to have requests sent to");
    RegAdminCmd("access_adoptstaff", Command_Blank, ADMFLAG_VOTE, "Access to adopt staff");
}

public Action Command_Blank(int client, int args)
{
    char cmd[64];
    GetCmdArg(0, cmd, sizeof(cmd));
    if(CheckCommandAccess(client, cmd, ADMFLAG_VOTE, false))
    {
        ReplyToCommand(client, "[SM] You have access to %s", cmd);
    }

    return Plugin_Handled;
}

public void OnClientDisconnect(client)
{
    informers_RemoveMyParent(client);
    //check if parent dc'd.
    informers_RemoveMyAdoption(client);
}
public Action Command_InformerAdoptions(int client, int args)
{
    if(IsValidClient(client))
    {
        informers_ShowAdoptions(client);
        return Plugin_Handled; 
    }
    return Plugin_Handled; 
}

public void informers_RoundFreezeEnd()
{
    if(!GetActiveStaffCount())
    {
        for (int i = 1; i <= MaxClients; i++)
        {
            if(IsValidClient(i))
            {
                if(Ranks_GetClientRank(i) == RANK_INFORMER)
                {
                    PrintToChat(i," [SM] There is \x0eno staff online \x01");
                    PrintToChat(i," [SM] You can now use \x0e!islay \x01-\x0e !imute\x01 - \x0e!igag \x01");
                }
            }
        }
        CPrintToChatAdmins(ADMFLAG_CHAT, "[SM] Informer commands enabled");
    }

}
public Action Command_InformerAdopt(int client, int args)
{
    AdminId clAdminId = GetUserAdmin(client);
    
    /*
    ReplyToCommand(client," [SM] Due abuse, I disabled this feature (you can thank valario and bob ross)" );
    return Plugin_Handled;
    */
    if(fc(client))
    {
        return Plugin_Handled;
    }
    
    if (args < 1)
    {
        new Handle:menu = CreateMenu(teamban_Command_InformerAdoptCallback);
        SetMenuTitle(menu, "What informer do you want to adopt");
        int count;
        for (int i = 1; i <= MaxClients; i++)
        {
            if(IsValidClient(i))
            {
                if(informers_CanAdopt(i, client))
                {
                    char name[32];
                    char targetid[3];
                    GetClientName(i, name, sizeof(name));
                    char stringformenu[255];
                    IntToString(i, targetid, sizeof(targetid));
                    if(informers_IHaveAParent(i) && !GetAdminFlag(clAdminId, Admin_Root, Access_Real))
                    {
                        Format(stringformenu,sizeof(stringformenu),"%s (adopted by %N)",name,informers_GetMyParent(i));						
                    }
                    else
                    {
                        Format(stringformenu,sizeof(stringformenu),"%s",name);
                    }
                    AddMenuItem(menu, targetid, stringformenu,informers_IHaveAParent(i) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
                    count++;
                }
            }
        }
        if(count == 0)
        {
            AddMenuItem(menu, "","No informers online",ITEMDRAW_DISABLED);
        }
        DisplayMenu(menu, client, MENU_TIME_FOREVER);
        return Plugin_Handled;
    }
    char arg[65];
    GetCmdArg(1, arg, sizeof(arg));
    int target = FindTarget(client,arg,true,true);
    if(informers_CanAdopt(target, client))
    {
        if(informers_IHaveAParent(target) && !GetAdminFlag(clAdminId, Admin_Root, Access_Real))
        {
            ReplyToCommand(client," [SM] This informer is already adopted by '%N'",informers_GetMyParent(target));
            return Plugin_Handled;
        }
        if(informers_GetMyParent(target) == client)
        {
            ReplyToCommand(client," [SM] You already adopted this informer");
            return Plugin_Handled;
        }
        //Open for adoption.
        if(informers_SetMyParent(target,client))
        {
            ReplyToCommand(client," [SM] You adopted '%N'",target);
            PrintToChat(target," [SM] You got \x0eadopted\x01 by '%N'.",client);
            PrintToChat(target," [SM] You can become an orphan again by using \x0e!orphan",client);
            CPrintToChatAdmins(ADMFLAG_CHAT, "[SM] %N adopted %N",client,target);
            return Plugin_Handled;
        }
        ReplyToCommand(client," [SM] Something went wrong while trying to adopt this informer");
        return Plugin_Handled;
    
    }
    else
    {
        ReplyToCommand(client," [SM] Something went wrong while trying to adopt this informer");
        return Plugin_Handled;
    }

}

public Action Command_InformerEmpower(int client, int args)
{
    /*
    ReplyToCommand(client," [SM] Due abuse, I disabled this feature (you can thank valario and bob ross)" );
    return Plugin_Handled;
    */
    if(fc(client))return Plugin_Handled;

    if(args < 1)
    {
        ReplyToCommand(client, "[SM] Usage: sm_empower <target");
        return Plugin_Handled;
    }

    char arg[65];
    GetCmdArg(1, arg, sizeof(arg));
    int target = FindTarget(client,arg,true,true);
    if(target != -1)
    {
        if(informers_GetMyParent(target) == client)
        {
            if(!informers_IAmEmpowered(target))
            {
                if(informers_SetMyParent(target,client,true))
                {
                    ReplyToCommand(client," [SM] You empowered '%N'.",target);
                    PrintToChat(target," [SM] You got \x0eempowered\x01 by '%N'.",client);
                    PrintToChat(target," [SM] You can become an orphan again by using \x0e!orphan",client);
                    CPrintToChatAdmins(ADMFLAG_CHAT, "[SM] %N empowered %N",client,target);
                    return Plugin_Handled;
                }
                ReplyToCommand(client," [SM] Something went wrong while trying to empowered this informer");
                return Plugin_Handled;	
            }
            //Open for adoption.

            else
            {
                if(informers_SetMyParent(target,client,false))
                {
                    ReplyToCommand(client," [SM] You unempowered '%N'.",target);
                    PrintToChat(target," [SM] You got \x0eunempowered\x01 by '%N'.",client);
                    PrintToChat(target," [SM] You can become an orphan again by using \x0e!orphan",client);
                    CPrintToChatAdmins(ADMFLAG_CHAT, "[SM] %N unempowered %N",client,target);
                    return Plugin_Handled;
                }
                ReplyToCommand(client," [SM] Something went wrong while trying to empowered this informer");
                return Plugin_Handled;	
            }	
        }
        else 
        {
            ReplyToCommand(client, "[SM] Please adopt this informer before trying to empower them!");
            return Plugin_Handled;
        }
    }
    else
    {
        ReplyToCommand(client," [SM] Something went wrong while trying to empowered this informer");
        return Plugin_Handled;
    }
}

public Action Command_InformerRequest(int client, int args)
{
    if(!informers_IHaveAParent(client))
    {
        ReplyToCommand(client, "[SM] You do not have a parent to send a command request to");
        return Plugin_Handled;
    }

    int admin  = informers_GetMyParent(client);

    if(!CheckCommandAccess(admin, "access_request", ADMFLAG_VOTE, false))
    {
        ReplyToCommand(client, "[SM] Your parent doesn't have the right permissions to recieve requests");
        return Plugin_Handled;
    }
    if(args < 1)
    {
        for(int r = 0; r < REQWL; r++)
        {
            PrintToConsole(client, "%i: %s", r, g_cRequestWhitelist[r]);
        }
        ReplyToCommand(client, "[SM] Check console for avaliable commands");
        ReplyToCommand(client, "[SM] Usage: sm_request <command> <standard command params>");
        return Plugin_Handled;
    }

    char cmd[64],sm_cmd[64] = "sm_", Args[512];
    char removal[64] = "sm_request ";	
    GetCmdArgString(Args, sizeof(Args));
    GetCmdArg(1, cmd, sizeof(cmd));

    bool canRequest = false;

    for(int w = 0; w < REQWL; w++)
    {
        if(StrContains(Args, g_cRequestWhitelist[w][0], false) != -1)
        {
            canRequest = true;
            break;
        }
    }
    if(canRequest)
    {
        for(int b = 0; b < REQBL; b++)
        {
            if(StrContains(Args, g_cRequestBlacklist[b][0], false) != -1)
            {
                canRequest = false;
                break;
            }
        }
    }

    if(!canRequest)
    {
        ReplyToCommand(client, "[SM] Something went wrong while sending this request!");
        return Plugin_Handled;
    }

    ReplaceString(Args, sizeof(Args), removal, "");
    ReplaceString(Args, sizeof(Args), cmd, "");
    
    if(StrContains(cmd, "sm_", false) == -1)
    {
        StrCat(sm_cmd, sizeof(sm_cmd), cmd);
        strcopy(cmd, sizeof(cmd), sm_cmd);
    }

    if(informers_ForwardToMyParent(client, cmd, Args, informers_IAmEmpowered(client), true))
    {
        LogAction(client, -1, "\"%L\" requested (%s %s) from \"%L\"", client, cmd, Args, informers_GetMyParent(client));
        ReplyToCommand(client, "[SM] Request sent to parent");
        return Plugin_Handled;
    }
    else 
    {
        ReplyToCommand(client, "[SM] Something went wrong while sending this request!");
        return Plugin_Handled;
    }
}

//This is called after selecting a name.
public int teamban_Command_InformerAdoptCallback(Menu menu, MenuAction action,int param1,int param2)
{
    /* If an option was selected, tell the client about the item. */
    new client = param1;
    if (action == MenuAction_Select)
    {
        char info[512];
        /* bool found = */
        menu.GetItem(param2, info, sizeof(info));
        //PrintToChat(param1, "You selected item: %d (found? %d info: %s)", param2, found, info);

        int target = StringToInt(info); //disconnected player
        if(informers_SetMyParent(target,client,false))
        {
            ReplyToCommand(client," [SM] You adopted '%N'",target);
            PrintToChat(target," [SM] You got \x0eadopted\x01 by '%N'.",client);
            PrintToChat(target," [SM] You can become an orphan again by using \x0e!orphan",client);
            CPrintToChatAdmins(ADMFLAG_CHAT, "[SM] %N adopted %N",client,target);
            return;
        }
    }
    else if (action == MenuAction_End)
    {
        CloseHandle(menu);
    }
}

public Action Command_InformerOrphan(int client, int args)
{
    if(fc(client))return Plugin_Handled;
    switch(Ranks_GetClientRank(client))
    {
        case RANK_INFORMER:
            {
                if(informers_IHaveAParent(client))
                {
                    informers_RemoveMyParent(client);
                    ReplyToCommand(client," [SM] We removed your parent, you are now an orphan again");
                    CPrintToChatAdmins(ADMFLAG_CHAT, "[SM] %N's removed his partent",client);
                    return Plugin_Handled;
                }
                else
                {
                    ReplyToCommand(client," [SM] You don't have a parent");
                    return Plugin_Handled;	
                }
            }
        default:
            {
                informers_RemoveMyAdoption(client);
                ReplyToCommand(client," [SM] You removed all your adoptions");
                CPrintToChatAdmins(ADMFLAG_CHAT, "[SM] %N's adoptions got removed",client);
                return Plugin_Handled;	
            }
    }
                
}

public Action Command_InformerSlay(int client, int args)
{
    if(fc(client))return Plugin_Handled;
    if (args < 1)
    {
        ReplyToCommand(client, " [SM] Usage: sm_islay <target>");
        return Plugin_Handled;
    }
    char arg[65];
    GetCmdArg(1, arg, sizeof(arg));
    int target = FindTarget(client,arg,true,true);
    if(target != -1)
    {
        if(GetActiveStaffCount() > 0)//there is staff online
        {
            if(informers_IHaveAParent(client))
            {
                //i have a parent
                //forward to the parent.
                char cCommand[512];
                char cArgs[512];
                GetCmdArg(0, cCommand, sizeof(cCommand));
                GetCmdArgString(cArgs,sizeof(cArgs));
                if(informers_ForwardToMyParent(client,cCommand,cArgs,informers_IAmEmpowered(client), false))
                {
                    ReplyToCommand(client, " [SM] Request send to your parent");
                }
                else
                {
                    ReplyToCommand(client, " [SM] Something went wrong while sending the command to your parent.");
                }
                return Plugin_Handled;
            }	
            else
            {
                //i dont have a parent.
                ReplyToCommand(client, " [SM] You are not adopted and there is higher staff online. (you cannot use your informer powers)");
                return Plugin_Handled;
            }
        }
        else //no staff online
        {
            ShowActivity2(client, " [SM] ", "slayed '%N'",target);
            LogAction(client, target, "\"%L\" slayed \"%L\"", client, target);
            ForcePlayerSuicide(target);
        }
    }
    return Plugin_Handled;
}

public Action Command_InformerMute(int client, int args)
{
    if(fc(client))return Plugin_Handled;
    if (args < 2)
    {
        ReplyToCommand(client, " [SM] Usage: sm_imute <target> <time> <reason>");
        return Plugin_Handled;
    }
    char arg1[65], arg2[65], reason[256], buffer[65];

    GetCmdArg(1, arg1, sizeof(arg1));
    GetCmdArg(2, arg2, sizeof(arg2));

    int time = StringToInt(arg2);
    if(time > 30)
    {
        ReplyToCommand(client, TTT_ERROR... "Time is too long, lowered to 30 minutes");
        time = 30;
    }
    int target = FindTarget(client,arg1,true,true);

    GetCmdArg(3, reason, sizeof(reason));
    if(args > 3)
    {
        for (int i = 4; i <= args; i++)
        {
            GetCmdArg(i, buffer, sizeof(buffer));
            Format(reason, sizeof(reason), "%s %s", reason, buffer);
        }
    }
    if(target != -1)
    {
        if(GetActiveStaffCount() > 0)//there is staff online
        {
            if(informers_IHaveAParent(client))
            {
                //i have a parent
                //forward to the parent.
                char cCommand[512];
                char cArgs[512];
                GetCmdArg(0, cCommand, sizeof(cCommand));
                GetCmdArgString(cArgs,sizeof(cArgs));
                if(informers_ForwardToMyParent(client,cCommand,cArgs,informers_IAmEmpowered(client), false))
                {
                    ReplyToCommand(client, " [SM] Request send to your parent");
                }
                else
                {
                    ReplyToCommand(client, " [SM] Something went wrong while sending the command to your parent.");
                }
                return Plugin_Handled;
            }	
            else
            {
                //i dont have a parent.
                ReplyToCommand(client, " [SM] You are not adopted and there is higher staff online. (you cannot use your informer powers)");
                return Plugin_Handled;
            }
        }
        else //no staff online
        {
            ShowActivity2(client, " [SM] ", "muted '%N' for %i minutes, because: %s",target, time, reason);
            SourceComms_SetClientMute(target, true, time, true, reason);
        }
    }
    return Plugin_Handled;
}

public Action Command_InformerGag(int client, int args)
{
    if(fc(client))return Plugin_Handled;
    if (args < 2)
    {
        ReplyToCommand(client, " [SM] Usage: sm_igag <target> <time> <reason>");
        return Plugin_Handled;
    }
    char arg1[65], arg2[65], reason[256], buffer[65];

    GetCmdArg(1, arg1, sizeof(arg1));
    GetCmdArg(2, arg2, sizeof(arg2));

    int time = StringToInt(arg2);
    if(time > 30)
    {
        ReplyToCommand(client, TTT_ERROR... "Time is too long, lowered to 30 minutes");
        time = 30;
    }
    int target = FindTarget(client,arg1,true,true);

    GetCmdArg(3, reason, sizeof(reason));
    if(args > 3)
    {
        for (int i = 4; i <= args; i++)
        {
            GetCmdArg(i, buffer, sizeof(buffer));
            Format(reason, sizeof(reason), "%s %s", reason, buffer);
        }
    }
    
    if(target != -1)
    {
        if(GetActiveStaffCount() > 0)//there is staff online
        {
            if(informers_IHaveAParent(client))
            {
                //i have a parent
                //forward to the parent.
                char cCommand[512];
                char cArgs[512];
                GetCmdArg(0, cCommand, sizeof(cCommand));
                GetCmdArgString(cArgs,sizeof(cArgs));
                if(informers_ForwardToMyParent(client,cCommand,cArgs,informers_IAmEmpowered(client), false))
                {
                    ReplyToCommand(client, " [SM] Request send to your parent");
                }
                else
                {
                    ReplyToCommand(client, " [SM] Something went wrong while sending the command to your parent.");
                }
                return Plugin_Handled;
            }	
            else
            {
                //i dont have a parent.
                ReplyToCommand(client, " [SM] You are not adopted and there is higher staff online. (you cannot use your informer powers)");
                return Plugin_Handled;
            }
        }
        else //no staff online
        {
            ShowActivity2(client, " [SM] ", "gagged '%N' for %i minutes, because: %s",target, time, reason);
            SourceComms_SetClientGag(target, true, time, true, reason);
        }
    }
    return Plugin_Handled;
}

public Action Command_InformerTest(int client, int args)
{
    if (args < 1)
    {
        ReplyToCommand(client, " [SM] Usage: sm_islay <target>");
        return Plugin_Handled;
    }
    char arg[65];
    GetCmdArg(1, arg, sizeof(arg));
    if(informers_IHaveAParent(client))
    {
        //i have a parent
        //forward to the parent.
        char cCommand[512];
        char cArgs[512];
        GetCmdArg(0, cCommand, sizeof(cCommand));
        GetCmdArgString(cArgs,sizeof(cArgs));
        if(informers_ForwardToMyParent(client,cCommand,cArgs,informers_IAmEmpowered(client), false))
        {
            ReplyToCommand(client, " [SM] Request send to your parent");
        }
        else
        {
            ReplyToCommand(client, " [SM] Something went wrong while sending the command to your parent.");
        }
        return Plugin_Handled;
    }	

    return Plugin_Handled;
}