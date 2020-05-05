#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <string>

#undef REQUIRE_PLUGIN
#include <colorvariables>
#include <generics>
#include <chat-processor>
#include <ttt_ranks>
#include <ttt_targeting>
#include <ttt_messages>
#include <donators>
#include <clientprefs>


public Plugin myinfo =
{
    name = "CLWO Chat",
    author = "c0rp3n / Sourcecode / iNilo",
    description = "Processes chat for CLWO TTT & Course.",
    version = "1.0.0",
    url = "https://clwo.eu"
};

int g_iReplyTo[MAXPLAYERS + 1];
bool g_bDonators = false;
bool g_biMod = false;
Handle g_hClientCookieOverRideRank = null;


Handle g_hClientBlockList;
Handle g_hDisabledPM;
Handle g_hStaffOnlyPM;
Handle g_hClientStreaming;

public OnPluginStart()
{
    LoadTranslations("common.phrases");

    RegisterCmds();
    RegisterCvars();

    PrintToServer("[CHT] Loaded successfully");
}

public void RegisterCmds()
{
    RegAdminCmd("sm_say", Command_Say, ADMFLAG_CHAT, "sm_say - Sends a message to all players");
    RegAdminCmd("sm_msay", Command_MSay, ADMFLAG_CHAT, "sm_msay - Send a panel message to all players");
    RegAdminCmd("sm_smsay", Command_SMSay, ADMFLAG_CHAT, "sm_smsay - MSay, but targetted");
    RegAdminCmd("sm_csay", Command_CSay, ADMFLAG_CHAT, "sm_csay - Sends a central message to all players");
    RegAdminCmd("sm_scsay", Command_SCSay, ADMFLAG_CHAT, "sm_scsay - CSay, but targetted");
    
    RegConsoleCmd("sm_chat", Command_Chat, "sm_chat - Sends a message to staff");
    RegConsoleCmd("sm_psay", Command_Msg, "sm_msg <name or #userid> <message> - sends private message");
    RegConsoleCmd("sm_msg", Command_Msg, "sm_msg <name or #userid> <message> - sends private message");
    RegConsoleCmd("sm_r", Command_Reply, "sm_reply <message> - replies to previous private message");
    RegConsoleCmd("sm_reply", Command_Reply, "sm_reply <message> - replies to previous private message");

    RegAdminCmd("sm_setrankoverride", Command_RankOverride, ADMFLAG_RCON, "sm_setrankoverride <#userid|name> <number>");

    RegConsoleCmd("sm_block", Command_Block, "sm_block select players to blacklist");
    RegConsoleCmd("sm_blocks", Command_Block, "sm_block select players to blacklist");
}
public void RegisterCvars()
{
    g_hClientCookieOverRideRank = FindClientCookie("RankOverride");
    if(g_hClientCookieOverRideRank == null)
        g_hClientCookieOverRideRank = RegClientCookie("RankOverride", "The number to override the rank to" , CookieAccess_Protected);

    g_hClientBlockList = RegClientCookie("PrivateMessages_Blacklist", "Blocked players", CookieAccess_Public);

    g_hDisabledPM = RegClientCookie("DisablePrivateMessages", "Setting this to 1 will disable you from receiving PM's", CookieAccess_Public);
    g_hStaffOnlyPM = RegClientCookie("StaffOnlyPrivateMessages", "Setting this to 1 will only allow staff to PM you", CookieAccess_Public);
    g_hClientStreaming = RegClientCookie("StaffStreamMode", "Set your streaming mode to 1, to hide potential exposing of some chats", CookieAccess_Public);
    SetCookiePrefabMenu(g_hDisabledPM, CookieMenu_YesNo_Int, "[MSG's] Disable private messages");
    SetCookiePrefabMenu(g_hStaffOnlyPM, CookieMenu_YesNo_Int, "[MSG's] Enable staff only private messages");
    SetCookiePrefabMenu(g_hClientStreaming, CookieMenu_YesNo_Int, "[MSG's] Enable staff streaming mode");
    SetCookieMenuItem(ClientPrefMenuBlock, 0, "[MSG's] Manage blocklist");

}

public void OnMapStart()
{
    DynamicAddToDownloadTable(1, 4, "inilo/general_v1_452489/chat_v1_452489/chat_beep%02i_452489.mp3", true, true);
    CheckLibs();
}
public OnAllPluginsLoaded()
{
    CheckLibs();
}


public void CheckLibs()
{
    g_biMod = LibraryExists("iMod");
    g_bDonators = LibraryExists("donators");
    PrintToServer("iMod == %b", g_biMod);
    PrintToServer("Donators == %b", g_bDonators);
}

public OnLibraryRemoved(const char[] name)
{
    if (StrEqual(name, "iMod"))
    {
        g_biMod = false;
    }
    if (StrEqual(name, "donators"))
    {
        g_bDonators = false;
    }
}
 
public OnLibraryAdded(const char[] name)
{

    if (StrEqual(name, "iMod"))
    {
        g_biMod = true;
    }
    if (StrEqual(name, "donators"))
    {
        g_bDonators = true;
    }
}

public Action CP_OnChatMessage(int& author, ArrayList recipients, char[] flagstring, char[] name, char[] message, bool& processcolors, bool& removecolors)
{
    //please don't use {colors} here because it exceeds the buffers, example with anne:
    //{default}[{lime}♥{default}]{default}[{lime}T.MOD{default}]{default}[{lime}♀♀{default}]{default}[{yellow}Teacher{default}] {teamcolor}Anne{default}
    // use \x0xxxx versions
    char cRankBuffer[16];
    char teamColor[512];
    char staffTag[512];
    char cFullBuffer[512];
    int iBufferSize = 512;
    char sChatTag[512];
    char cPreChatTag[512];

    int rank = Ranks_GetClientRank(author);
    
    if (message[0] != '@') // Not staff / all say or pm.
    {   
        if (rank > RANK_PLEB)
        {
            if(AreClientCookiesCached(author))
            {
                char cCookie[128];
                GetClientCookie(author, g_hClientCookieOverRideRank, cCookie, sizeof(cCookie));
                if(strlen(cCookie) > 0)
                {
                    rank = StringToInt(cCookie);
                }
            }
            Ranks_GetRankTag(rank, cRankBuffer);
            Format(staffTag, sizeof(staffTag), "\x01[\x05%s\x01]", cRankBuffer);
        }

        switch (GetClientTeam(author))
        {
            case CS_TEAM_SPECTATOR:
            {
                Format(teamColor, sizeof(teamColor), "grey2");
            }
            case CS_TEAM_T, CS_TEAM_CT:
            {
                Format(teamColor, sizeof(teamColor), "teamcolor");
            }
        }

        //Remove colors from message
        CRemoveColors(message, _CV_MAX_MESSAGE_LENGTH);
        RemoveHexColors(message, message, _CV_MAX_MESSAGE_LENGTH);

        //Remove colors from name
        CRemoveColors(name, iBufferSize);

        //lets add in our donator/special guest tags.

        #if defined _donators_included_
        char sTemp[512];
        if(g_bDonators)
        {
            if(Donator_IsDonator(author))
            {
                if(!Donator_DisabledDonatorPrefix(author))
                {
                    Format(cPreChatTag, sizeof(cPreChatTag), "\x01[\x05♥\x01]");                    
                }
            }
            if(Guest_IsSpecialGuest(author) && !Guest_DisabledSpecialGuestPrefix(author))
            {
                Guest_GetTag(author, sTemp, sizeof(sTemp));
                Format(sChatTag, sizeof(sChatTag), "\x01[\x05%s\x01]", sTemp);
            }
            //suffix for donator.
            if(Donator_IsDonator(author) && Donator_GetType(author) > 1)
            {
                
                if(!Donator_DisabledChatTag(author))
                {
                    Donator_GetChatTag(author, sTemp, sizeof(sTemp));
                    Format(sChatTag, sizeof(sChatTag), "%s\x01[\x09%s\x01]", sChatTag, sTemp); //append, just incase our special guest is a donator
                }
            }
        }
        #endif
        // Format message name
        Format(cFullBuffer, sizeof(cFullBuffer), "%s%s%s {%s}%s\x01", cPreChatTag, staffTag, sChatTag, teamColor, name);
        Format(name, iBufferSize, "%s", cFullBuffer);

        if(message[0] == '!' || message[0] == '/')
        {
            //Only send message to player if it's a command
            recipients.Clear();
            recipients.Push(GetClientUserId(author));
        }

        LogAction(author, -1, "\"%L\" said in chat (text %s)", author, message);

        return Plugin_Changed;
    }

    if (rank > RANK_VIP && StrContains(flagstring, "All", false) == -1 || rank == RANK_INFORMER)
    {
        strcopy(message, strlen(message), message[1]);

        recipients.Clear();

        LoopValidClients(i)
        {
            int nrank = Ranks_GetClientRank(i);
            if(RANK_VIP < nrank)
            {
                recipients.Push(GetClientUserId(i));
            }
        }

        if(AreClientCookiesCached(author))
        {
            char cCookie[128];
            GetClientCookie(author, g_hClientCookieOverRideRank, cCookie, sizeof(cCookie));
            if(strlen(cCookie) > 0)
            {
                rank = StringToInt(cCookie);
            }
        }

        Ranks_GetRankTag(rank, cRankBuffer);
        Format(staffTag, sizeof(staffTag), "\x01[\x05%s\x01]", cRankBuffer);

        Format(name, iBufferSize, "\x09[STAFF]%s\x09 %s", staffTag, name);
        Format(message, _CV_MAX_MESSAGE_LENGTH, "\x0A%s", message);
        Format(flagstring, iBufferSize, "Cstrike_Chat_All"); //Yes, I hardcoded it, sorry, I cba to make it better

        LogAction(author, -1, "\"%L\" triggered sm_chat (text %s)", author, message);

        return Plugin_Changed;
    }


    if (rank > RANK_INFORMER && StrContains(flagstring, "All", false) != -1)
    {
        strcopy(message, strlen(message), message[1]);

        recipients.Clear();

        LoopValidClients(i)
        {
            recipients.Push(GetClientUserId(i));
        }      

        if(AreClientCookiesCached(author))
        {
            char cCookie[128];
            GetClientCookie(author, g_hClientCookieOverRideRank, cCookie, sizeof(cCookie));
            if(strlen(cCookie) > 0)
            {
                rank = StringToInt(cCookie);
            }
        }

        Ranks_GetRankTag(rank, cRankBuffer);
        Format(staffTag, sizeof(staffTag), "\x01[\x05%s\x01]", cRankBuffer);

        Format(name, iBufferSize, "\x07[ALL]%s \x07%s\x01", staffTag, name);
        Format(flagstring, iBufferSize, "Cstrike_Chat_All"); //Yes, I hardcoded it, sorry, I cba to make it better

        LogAction(author, -1, "\"%L\" triggered sm_say (text %s)", author, message);

        return Plugin_Changed;
    }

    else
    {
        strcopy(message, strlen(message), message[1]);

        recipients.Clear();

        LoopValidClients(i)
        {
            int nrank = Ranks_GetClientRank(i);
            if(nrank > RANK_INFORMER)
            {
                recipients.Push(GetClientUserId(i));
            }
        }

        recipients.Push(GetClientUserId(author));

        Format(name, iBufferSize, "\x09[TO STAFF] %s\x09", name);
        Format(message, _CV_MAX_MESSAGE_LENGTH, "\x0A%s", message);
        Format(flagstring, iBufferSize, "Cstrike_Chat_All"); //Yes, I hardcoded it, sorry, I cba to make it better

        LogAction(author, -1, "\"%L\" triggered sm_chat (text %s)", author, message);

        return Plugin_Changed;
    }
     
}

public Action Command_Say(int client, int args)
{
    if (args < 1)
    {
        CPrintToChat(client, TTT_USAGE ... "sm_say <message>");
        return Plugin_Handled;
    }

    char message[255], buffer[128];

    GetCmdArg(1, message, sizeof(message));

    for (int i = 2; i <= args; i++)
    {
        GetCmdArg(i, buffer, sizeof(buffer));
        Format(message, sizeof(message), "%s %s", message, buffer);
    }
    
    SendChatToAll(client, message);
    return Plugin_Handled;
}

public Action Command_MSay(int client, int args)
{
    if (args < 1)
    {
        CPrintToChat(client, TTT_USAGE ... "sm_msay <message>");
        return Plugin_Handled;
    }

    char message[255], buffer[128], title[128];

    GetCmdArg(1, message, sizeof(message));

    for (int i = 2; i <= args; i++)
    {
        GetCmdArg(i, buffer, sizeof(buffer));
        Format(message, sizeof(message), "%s %s", message, buffer);
    }

    Format(title, sizeof(title), "%N: ", client);
    LoopValidClients(j)
    {
        TTT_SendPanelMsg(j, title, message);
    }

    return Plugin_Handled;
}

public Action Command_SMSay(int client, int args)
{
    if (args < 2)
    {
        CPrintToChat(client, TTT_USAGE ... "sm_smsay <#userid|name> <message>");
        return Plugin_Handled;
    }

    char message[255], arg1[128], buffer[128], title[128];

    GetCmdArg(1, arg1, sizeof(arg1));
    int target = TTT_Target(arg1, client, true, false, false);

    if (target < 0)
    {
        return Plugin_Handled;
    }

    if (args >= 2)
    {
        // They've included a message!
        GetCmdArg(2, message, sizeof(message));

        for (int i = 3; i <= args; i++)
        {
            GetCmdArg(i, buffer, sizeof(buffer));
            Format(message, sizeof(message), "%s %s", message, buffer);
        }
    }

    Format(title, sizeof(title), "%N: ", client);
    TTT_SendPanelMsg(target, title, message);

    return Plugin_Handled;
}

public Action Command_CSay(int client, int args)
{
    if (args < 1)
    {
        CPrintToChat(client, TTT_USAGE ... "sm_csay <message>");
        return Plugin_Handled;
    }

    char message[255], buffer[128];
    GetCmdArg(1, message, sizeof(message));

    for (int i = 2; i <= args; i++)
    {
        GetCmdArg(i, buffer, sizeof(buffer));
        Format(message, sizeof(message), "%s %s", message, buffer);
    }

    PrintCenterTextAll(message);
    return Plugin_Handled;
}

public Action Command_SCSay(int client, int args)
{
    if (args < 2)
    {
        CPrintToChat(client, TTT_USAGE ... "sm_scsay <#userid|name> <message>");
        return Plugin_Handled;
    }

    char message[255], arg1[128], buffer[128];

    GetCmdArg(1, arg1, sizeof(arg1));
    int target = TTT_Target(arg1, client, true, false, false);

    if (target < 0)
    {
        return Plugin_Handled;
    }

    if (args >= 2)
    {
        // They've included a message!
        GetCmdArg(2, message, sizeof(message));

        for (int i = 3; i <= args; i++)
        {
            GetCmdArg(i, buffer, sizeof(buffer));
            Format(message, sizeof(message), "%s %s", message, buffer);
        }
    }

    PrintCenterText(target, message);
    return Plugin_Handled;
}

public Action Command_Chat(int client, int args)
{
    char message[255], buffer [128];

    int rank = Ranks_GetClientRank(client);

    if (args < 1)
    {
        CPrintToChat(client, TTT_USAGE ... "sm_chat <message>");
        return Plugin_Handled;
    }
    
    GetCmdArg(1, message, sizeof(message));

    for (int i = 2; i <= args; i++)
    {
        GetCmdArg(i, buffer, sizeof(buffer));
        Format(message, sizeof(message), "%s %s", message, buffer);
    }
    
    if (rank <= RANK_VIP)
    {
        SendChatToAdminPleb(client, message);
        return Plugin_Handled;
    }

    else
    {
        SendChatToAdmin(client, message);
        return Plugin_Handled;
    }    
}

public Action Command_Msg(int client, int args)
{
    if (args < 2)
    {
        CPrintToChat(client, TTT_USAGE ... "sm_msg <#userid|name> <message>");
        return Plugin_Handled;
    }

    char text[192], arg[64];
    GetCmdArgString(text, sizeof(text));

    int len = BreakString(text, arg, sizeof(arg));
    
    int target = FindTarget(client, arg, true, false);

    if (target == -1)
    {
        return Plugin_Handled;
    }
        
    SendPrivateChat(client, target, text[len]);

    return Plugin_Handled;
}

public Action Command_Reply(int client, int args)
{
    if (args < 1)
    {
        CPrintToChat(client, TTT_USAGE ... "sm_reply <message>");
        return Plugin_Handled;  
    }
    int target = g_iReplyTo[client];
    if (!IsValidClient(target)) {
        ReplyToCommand(client, "[SM] No one to reply to.");
        return Plugin_Handled;
    }

    char text[256];
    GetCmdArgString(text, sizeof(text));

    SendPrivateChat(client, target, text);
    
    return Plugin_Handled;      
}
public Action Command_RankOverride(int client, int args)
{
    if (args < 1)
    {
        ReplyToCommand(client, " [SM] Usage: sm_setrankoverride <#userid|name> <number>");
        return Plugin_Handled;
    }

    char arg[65];
    GetCmdArg(1, arg, sizeof(arg)); 

    char arg2[65];
    GetCmdArg(2, arg2, sizeof(arg2));
    int rank_int = StringToInt(arg2);

    char target_name[MAX_TARGET_LENGTH];
    int target_list[MAXPLAYERS];
    int target_count;
    bool tn_is_ml;
    
    if ((target_count = ProcessTargetString(
            arg,
            client,
            target_list,
            MAXPLAYERS,
            COMMAND_FILTER_NO_BOTS|COMMAND_FILTER_NO_IMMUNITY,
            target_name,
            sizeof(target_name),
            tn_is_ml)) <= 0)
    {
        ReplyToCommand(client," [SM] Invalid Target");
        return Plugin_Handled;
    }
    for (int i = 0; i < target_count; i++)
    {
        int target = target_list[i];
        if(args < 2)
        {
            SetClientCookie(target, g_hClientCookieOverRideRank, "");
            ReplyToCommand(client, " [SM] Removed the rank override of %N", target);
        }
        else
        {
            SetClientCookie(target, g_hClientCookieOverRideRank, arg2);
            char buffer[16];
            Ranks_GetRankTag(rank_int, buffer);
            ReplyToCommand(client, " [SM] Set the rank override of %N to [%s]", target, buffer);
        }
        
    }
    return Plugin_Handled;

}

void SendChatToAll(int client, char[] message)
{
    char buffer[16];
    char staffTag[64];
    char name[255];

    int rank = Ranks_GetClientRank(client);
    
    if(AreClientCookiesCached(client))
    {
        char cCookie[128];
        GetClientCookie(client, g_hClientCookieOverRideRank, cCookie, sizeof(cCookie));
        if(strlen(cCookie) > 0)
        {
            rank = StringToInt(cCookie);
        }
    }

    Ranks_GetRankTag(rank, buffer);
    Format(staffTag, 64, "\x01[\x05%s\x01]", buffer);

    GetClientName(client, name, sizeof(name));
    
    Format(name, MAX_NAME_LENGTH, "\x07[ALL]%s \x07%s\x01", staffTag, name);

    CPrintToChatAll("%s: \x01%s", name, message);

    char cSoundName[512];
    DynamicGetRandomSoundFile(1, 1, "inilo/general_v1_452489/chat_v1_452489/chat_beep04_452489.mp3", cSoundName, sizeof(cSoundName));
    for (int i = 1; i <= MaxClients; i++)
    {
        if(!IsValidClient(i))
            continue;
        ClientCommand(i, "play \"%s\"", cSoundName);
    }


    LogAction(client, -1, "\"%L\" triggered sm_say (text %s)", client, message);
}

void SendChatToAdmin(int client, char[] message)
{
    char buffer[16];
    char staffTag[64];
    char name[255];

    char cSoundName[512];
    DynamicGetRandomSoundFile(1, 1, "inilo/general_v1_452489/chat_v1_452489/chat_beep03_452489.mp3", cSoundName, sizeof(cSoundName));

    int rank = Ranks_GetClientRank(client);

    if(AreClientCookiesCached(client))
    {
        char cCookie[128];
        GetClientCookie(client, g_hClientCookieOverRideRank, cCookie, sizeof(cCookie));
        if(strlen(cCookie) > 0)
        {
            rank = StringToInt(cCookie);
        }
    }


    Ranks_GetRankTag(rank, buffer);
    Format(staffTag, 64, "\x01[\x05%s\x01]", buffer);
    GetClientName(client, name, sizeof(name));

    LoopValidClients(i)
    {
        if(Ranks_GetClientRank(i) > RANK_PLEB)
        {
            CPrintToChat(i, "\x09[STAFF]%s\x09 %s: \x0A%s", staffTag, name, message);
            ClientCommand(i, "play \"%s\"", cSoundName);
        }
    }

    LogAction(client, -1, "\"%L\" triggered sm_chat (text %s)", client, message);
}

stock bool GetBoolFromCookie(int client, Handle Cookie)
{
    char cValue[8];
    GetClientCookie(client,Cookie, cValue, sizeof(cValue));
    return view_as<bool>(StringToInt(cValue));
}

void SendChatToAdminPleb(int client, char[] message)
{
    char name[255];
    GetClientName(client, name, 255);
    
    LoopValidClients(i)
    {
        if(Ranks_GetClientRank(i) > RANK_VIP)
        {
            CPrintToChat(i,"\x09[TO STAFF] %s: \x0A%s", name, message);  
        }
    }
    CPrintToChat(client,"\x09[TO STAFF] %s: \x0A%s", name, message);

    LogAction(client, -1, "\"%L\" triggered sm_chat (text %s)", client, message);
}

void SendPrivateChat(int client, int target, char[] message)
{
    //Remove colors from message
    CRemoveColors(message, _CV_MAX_MESSAGE_LENGTH);
    RemoveHexColors(message, message, _CV_MAX_MESSAGE_LENGTH);

    //Get names and remove colors
    char clientName[MAX_NAME_LENGTH], targetName[MAX_NAME_LENGTH];
    GetClientName(client, clientName, sizeof(clientName));
    CRemoveColors(clientName, sizeof(clientName));

    GetClientName(target, targetName, sizeof(targetName));
    CRemoveColors(targetName, sizeof(targetName));

    //prelogic

    char cValue[8];
    GetClientCookie(target, g_hDisabledPM, cValue, sizeof(cValue)); //
    if(StringToInt(cValue) == 1 && !CanOverride(client))
    {
        ReplyToCommand(client, ">\x01[\x08failed to send\x01]\x01: %N has disabled private messages", target);
        PrintToChat(target, ">\x01[\x08blocked a private message\x01]");
        return;
    }

    GetClientCookie(target, g_hStaffOnlyPM, cValue, sizeof(cValue)); //
    if(StringToInt(cValue) == 1 && GetUserAdmin(client) == INVALID_ADMIN_ID)
    {
        ReplyToCommand(client, ">\x01[\x08failed to send\x01]\x01: %N has disabled private messages for non staff members", target);
        PrintToChat(target, ">\x01[\x08blocked a non staff message\x01]");
        return;
    }

    //check for blocklist.
    if(HasClientBlockedAccountID(target, GetSteamAccountID(client)) && !CanOverride(client))
    {
        ReplyToCommand(client, ">\x01[\x08failed to send\x01]\x01: %N has disabled private messages", target);
        PrintToChat(target, ">\x01[\x08message ignored (player is on blocklist)\x01]");
        return;
    }




    char cSoundName[512];
    DynamicGetRandomSoundFile(1, 1, "inilo/general_v1_452489/chat_v1_452489/chat_beep02_452489.mp3", cSoundName, sizeof(cSoundName));

    if (!client)
    {
        PrintToServer("(Private to %N) %N: %s", targetName, client, message);
    }
    else if (target == client)
    {
        CPrintToChat(client, ">\x01[{grey}me{gold} -> {grey}me\x01] %s", message);
        //add sound.
        ClientCommand(target, "play \"%s\"", cSoundName);
    } else {
        g_iReplyTo[target] = client;
        CPrintToChat(target, ">\x01[{grey}%s{gold} -> {grey}me\x01] %s", clientName, message);
        CPrintToChat(client, ">\x01[{grey}me{gold} -> {grey}%s\x01] %s", targetName, message);
        //add sound.
        ClientCommand(target, "play \"%s\"", cSoundName);
    }

    for (int x = 1; x <= MaxClients; x++)
    {
        if(!IsValidClient(x))
            continue;
        if(x == target)
            continue;
        if(x == client)
            continue;
        if(Ranks_GetClientRank(x) < RANK_SADMIN)
            continue;
        if(!AreClientCookiesCached(x))
            continue;
        if(GetBoolFromCookie(x, g_hClientStreaming))
            continue;
        CPrintToChat(x, ">\x01[\x10Spy\x01][{grey}%N{gold} -> {grey}%N\x01] %s", client, target, message);
    }

    LogAction(client, target, "\"%L\" triggered sm_psay to \"%L\" (text %s)", client, target, message);
}

stock RemoveHexColors(const char[] input, char[] output, int size) {
    int x = 0;
    for (int i=0; input[i] != '\0'; i++) {

        if (x+1 == size) {
            break;
        }

        char character = input[i];

        if (character > 0x10) {
            output[x++] = character;
        }
    }

    output[x] = '\0';
}


stock void DynamicAddToDownloadTable(int start, int stop, const char[] sound_fsp, bool download, bool precache)
{
    char cFSP_File[512];
    char cRSP_File[512];

    char auto_sound_fsp[512];
    char auto_sound_rsp[512];
    Format(auto_sound_fsp, sizeof(auto_sound_fsp), "sound/%s", sound_fsp);
    Format(auto_sound_rsp, sizeof(auto_sound_rsp), "*%s", sound_fsp);

    for (int sound = start; sound <= stop; sound++)
    {
        Format(cFSP_File, sizeof(cFSP_File), auto_sound_fsp, sound);
        Format(cRSP_File, sizeof(cRSP_File), auto_sound_rsp, sound);
        // PrintToConsoleAll("fsp -> %s",cFSP_File);
        // PrintToConsoleAll("rsp -> %s",cRSP_File);

        //verify the sound exists on disk.
        if(!FileExists(cFSP_File))
        {
            //PrintToChatiNilo("[DynamicAddToDownloadTable] [%s] FILE NOT FOUND ON DISK!", cFSP_File);
            //LogError("[DynamicAddToDownloadTable] [%s] FILE NOT FOUND ON DISK!", cFSP_File);
            //WriteError("[DynamicAddToDownloadTable] [%s] FILE NOT FOUND ON DISK!", cFSP_File);
            return; //make sure we are not precaching this file or adding it to downloads
        }
        if(download)
        {
            AddFileToDownloadsTable(cFSP_File);
        }
        if(precache)
        {
            FakePrecacheSound(cRSP_File);
            //EmitSoundToAll(cRSP_File,SOUND_FROM_WORLD,SNDCHAN_STATIC);
        }
    }
}

stock void DynamicGetRandomSoundFile(int start, int stop, const char[] sound_fsp, char[] output ,int maxlen)
{
    char auto_sound_rsp[512];
    Format(auto_sound_rsp, sizeof(auto_sound_rsp),"*%s", sound_fsp);
    Format(output, maxlen, auto_sound_rsp, GetRandomInt(start, stop));
}
stock void FakePrecacheSound(const char[] szPath)
{
    AddToStringTable( FindStringTable( "soundprecache" ), szPath );
}


public Action Command_Block(int client, int args)
{
    //View blocklist
    //add player to blocklist
    //remove player from blocklist
    MenuBlock(client);
    return Plugin_Handled;
}
public void MenuBlock(int client)
{
    if(!IsValidClient(client))
        return;
    Menu menu = new Menu(Block_Callback);
    menu.SetTitle("Private messages blocklist");
    menu.AddItem("#view#", "View your current blocklist");
    menu.AddItem("#add#", "Add a player to your blocklist");
    menu.Display(client, MENU_TIME_FOREVER);
}
public void MenuAddToBlacklist(int client)
{

    if(!IsValidClient(client))
        return;
    Menu menu = new Menu(MenuAddToBlacklist_Callback);
    menu.SetTitle("Please select player to add to your blocklist");
    int blcksize = GetClientBlacklistSize(client);
    for (int target = 1; target < MaxClients; target++)
    {
        if(!IsValidClient(target))
            continue;
        char cItem[64];
        char cDisplay[64];
        int account_id = GetSteamAccountID(target);
        if( account_id == 0)
            continue;
        bool blocked = HasClientBlockedAccountID(client, account_id);
        Format(cItem, sizeof(cItem), "%i", account_id);
        //check if already blacklisten.
        if(blocked)
        {
            Format(cDisplay, sizeof(cDisplay), "%N (blocked)", target);
        }
        else
        {
            if(blcksize >= 10)
            {
                Format(cDisplay, sizeof(cDisplay), "%N (blacklist full)", target);
                blocked = true;
            }
            else
            {
                Format(cDisplay, sizeof(cDisplay), "%N", target);
            }
            
        }
        menu.AddItem(cItem, cDisplay, blocked ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
    }
    menu.ExitBackButton = true;
    menu.Display(client, MENU_TIME_FOREVER);
}
public void MenuManageBlackList(int client)
{
    if(!IsValidClient(client))
        return;
    if(!AreClientCookiesCached(client))
    {
        PrintToChat(client, " [SM] Your blacklist is still being loaded");
        return;
    }
    Menu menu = new Menu(MenuManageBlackList_Callback);
    menu.SetTitle("Manage your blacklist");
    //loop the account ID's.
    char cBlacklist[512];
    char cBlacklistSplit[64][64];
    GetClientCookie(client, g_hClientBlockList, cBlacklist, sizeof(cBlacklist));
    int lngth = strlen(cBlacklist);
    int found = ExplodeString(cBlacklist, ",", cBlacklistSplit, 64, 64);
    PrintToConsole(client, " [BLACKLIST] length[%i] found[%i] content[%s]", lngth, found, cBlacklist);
    if(lngth == 0 || found == 0)
    {
        PrintToChat(client, " [SM] Your blocklist is empty");
        return; 
    }
    for(int blacklist_n = 0; blacklist_n <= found; blacklist_n++)
    {
        if(strlen(cBlacklistSplit[blacklist_n]) == 0)
            continue;
        char cItem[64];
        char cDisplay[64];
        Format(cItem, sizeof(cItem), cBlacklistSplit[blacklist_n]);
        int try_target = AccountIDToClient(StringToInt(cBlacklistSplit[blacklist_n]));
        if(IsValidClient(try_target))
        {
            Format(cDisplay, sizeof(cDisplay), "Remove %s (%N)", cBlacklistSplit[blacklist_n], try_target); 
        }
        else
        {
            Format(cDisplay, sizeof(cDisplay), "Remove %s", cBlacklistSplit[blacklist_n]);  
        }
        
        
        menu.AddItem(cItem, cDisplay);
    }
    menu.ExitBackButton = true;
    menu.Display(client, MENU_TIME_FOREVER);
}

public void AccountIdInBlacklist(int client, int accountid, bool add)
{
    if(!AreClientCookiesCached(client))
    {
        PrintToChat(client, " [SM] Your blocklist is still being loaded");
        return;
    }
    PrintToConsole(client, " [BLOCKLIST] request to add[%b] account[%i]", add, accountid);
    char cBlacklist[512];
    char cBlacklistSplit[64][64];
    int iBlacklist[64];
    GetClientCookie(client, g_hClientBlockList, cBlacklist, sizeof(cBlacklist));
    int lngth = strlen(cBlacklist);
    int found = ExplodeString(cBlacklist, ",", cBlacklistSplit, 64, 64);
    PrintToConsole(client, " [BLOCKLIST] length[%i] found[%i] content[%s]", lngth, found, cBlacklist);
    for(int blacklist_n = 0; blacklist_n <= found; blacklist_n++)
    {
        char cItem[64];
        Format(cItem, sizeof(cItem), cBlacklistSplit[blacklist_n]);
        int current_blocked = StringToInt(cItem);
        iBlacklist[blacklist_n] = current_blocked;  
    }
    //list is loaded.
    //loop it.
    int free_place = 0;
    for(int blacklist_n = 0; blacklist_n < 64; blacklist_n++)
    {
        //loop the list.
        //PrintToConsole(client, "[BLOCKLIST] current blocklist[%i] -> %i", blacklist_n, iBlacklist[blacklist_n]);
        if(add)
        {
            if(iBlacklist[blacklist_n] == 0)
            {
                free_place = blacklist_n;
            }
            if(iBlacklist[blacklist_n] == accountid)
            {
                PrintToChat(client, " [SM] This player is already blocked");
                return;
            }
        }
        else
        {
            //remove the player
            if(iBlacklist[blacklist_n] == accountid)
            {
                iBlacklist[blacklist_n] = 0; //erase the player
            }
        }
    }
    if(add)
    {
        iBlacklist[free_place] = accountid; //added to list, convert back to string now.
    }

    //rebuild the list.
    char cBlacklistRedone[512];
    int count = 0;
    for(int blacklist_n = 0; blacklist_n < 64; blacklist_n++)
    {
        if(iBlacklist[blacklist_n] == 0)
            continue; //dont care.
        //PrintToConsole(client, "[BLOCKLIST] rebuilding with %i", iBlacklist[blacklist_n]);
        if(count == 0)
        {
            //first.
            Format(cBlacklistRedone, sizeof(cBlacklistRedone), "%i", iBlacklist[blacklist_n]);
        }
        else
        {
            Format(cBlacklistRedone, sizeof(cBlacklistRedone), "%s,%i", cBlacklistRedone, iBlacklist[blacklist_n]);
        }
        count++;
    }
    //save this bitch ass to a the cookie.
    SetClientCookie(client, g_hClientBlockList, cBlacklistRedone);
    PrintToChat(client, " [SM] Updated your blocklist!");
    PrintToConsole(client, " [BLOCKLIST] final[%s]", cBlacklistRedone);
    if(add)
    {
        MenuAddToBlacklist(client);
    }
    else
    {
        //reshow remove
        MenuManageBlackList(client);
    }
}

public bool CanOverride(int client)
{
    return CheckCommandAccess(client, "sm_chat", ADMFLAG_CHAT);
}

public void ClientPrefMenuBlock(int client, CookieMenuAction action, any info, char[] buffer, int maxlen)
{
    MenuBlock(client);
}

public bool HasClientBlockedAccountID(int client, int accountid)
{
    char cBlacklist[512];
    char cBlacklistSplit[64][64];
    int iBlacklist[64];
    GetClientCookie(client, g_hClientBlockList, cBlacklist, sizeof(cBlacklist));
    int found = ExplodeString(cBlacklist, ",", cBlacklistSplit, 64, 64);
    //PrintToConsole(client, " [BLOCKLIST] length[%i] found[%i] content[%s]", lngth, found, cBlacklist);
    for(int blacklist_n = 0; blacklist_n <= found; blacklist_n++)
    {
        char cItem[64];
        Format(cItem, sizeof(cItem), cBlacklistSplit[blacklist_n]);
        int current_blocked = StringToInt(cItem);
        iBlacklist[blacklist_n] = current_blocked;  
    }
    for(int blacklist_n = 0; blacklist_n < 64; blacklist_n++)
    {
        if(iBlacklist[blacklist_n] == 0)
            continue;
        if(iBlacklist[blacklist_n] == accountid)
            return true;
    }
    return false;
}
public int GetClientBlacklistSize(int client)
{
    char cBlacklist[512];
    char cBlacklistSplit[64][64];
    GetClientCookie(client, g_hClientBlockList, cBlacklist, sizeof(cBlacklist));
    int lngth = strlen(cBlacklist);
    int found = ExplodeString(cBlacklist, ",", cBlacklistSplit, 64, 64);
    if(lngth == 0)
        return 0;
    return found;
}

public int MenuAddToBlacklist_Callback(Menu menu, MenuAction action, int param1, int param2)
{
    int client = param1;
    if(!IsValidClient(client))
        return;
    switch(action)
    {
        case MenuAction_Select:
        {
            char info[32];
            menu.GetItem(param2, info, sizeof(info));
            //convert the item into EWardayType
            int account_id_to_block = StringToInt(info);
            AccountIdInBlacklist(client, account_id_to_block, true);
        }
        case MenuAction_Cancel:
        {
            int close_reason = param2;  
            switch(close_reason)
            {
                case MenuCancel_ExitBack:
                {
                    MenuBlock(client);
                }
            }
        }
        case MenuAction_End:
        {
            delete menu;
        }
    }
}
public int MenuManageBlackList_Callback(Menu menu, MenuAction action, int param1, int param2)
{
    int client = param1;
    if(!IsValidClient(client))
        return;
    switch(action)
    {
        case MenuAction_Select:
        {
            char info[32];
            menu.GetItem(param2, info, sizeof(info));
            //convert the item into EWardayType
            int account_id_to_block = StringToInt(info);
            AccountIdInBlacklist(client, account_id_to_block, false);
        }
        case MenuAction_Cancel:
        {
            int close_reason = param2;  
            switch(close_reason)
            {
                case MenuCancel_ExitBack:
                {
                    MenuBlock(client);
                }
            }
        }
        case MenuAction_End:
        {
            delete menu;
        }
    }
}

public int Block_Callback(Menu menu, MenuAction action, int param1, int param2)
{
    int client = param1;
    if(!IsValidClient(client))
        return;
    switch(action)
    {
        case MenuAction_Select:
        {
            char info[32];
            menu.GetItem(param2, info, sizeof(info));
            if(StrEqual(info,"#view#"))
            {
                MenuManageBlackList(client);
            }
            if(StrEqual(info,"#add#"))
            {
                MenuAddToBlacklist(client);
            }
        }
        case MenuAction_End:
        {
            delete menu;
        }
    }
}

stock int AccountIDToClient(int AccountID)
{
    for (int client = 1; client <= MaxClients; client++)
    {
        if(!IsValidClient(client))
            continue;
        int account_id = GetSteamAccountID(client,true);
        if(account_id == 0)
            continue;
        if(AccountID == account_id)
            return client;
    }
    return 0;
}
