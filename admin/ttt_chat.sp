#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <cstrike>

#include <colorvariables>
#include <generics>
#include <chat-processor>
#include <ttt_ranks>
#include <ttt_targeting>
#include <ttt_messages>
#include <donators>

public Plugin myinfo =
{
    name = "CLWO Chat",
    author = "c0rp3n",
    description = "Processes chat for CLWO TTT & Course.",
    version = "1.0.0",
    url = ""
};

int g_iReplyTo[MAXPLAYERS + 1];
bool g_bDonators = false;
bool g_biMod = false;

public OnPluginStart()
{
    LoadTranslations("common.phrases");

    RegisterCmds();

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
    RegConsoleCmd("sm_msg", Command_Msg, "sm_msg <name or #userid> <message> - sends private message");
    RegConsoleCmd("sm_r", Command_Reply, "sm_reply <message> - replies to previous private message");
    RegConsoleCmd("sm_reply", Command_Reply, "sm_reply <message> - replies to previous private message");
}

public void OnMapStart()
{
    DynamicAddToDownloadTable(1, 1, "inilo/general_v1_452489/chat_v1_452489/chat_beep02_452489.mp3", true, true);
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
    char buffer[16];
    char teamColor[6];
    char staffTag[64];

    int rank = GetPlayerRank(author);
    
    if (message[0] != '@') // Not staff / all say or pm.
    {   
        if (rank > RANK_PLEB)
        {
            GetRankTag(rank, buffer);
            Format(staffTag, 64, "{default}[{lime}%s{default}]", buffer);
        }

        switch (GetClientTeam(author))
        {
            case CS_TEAM_SPECTATOR:
            {
                Format(teamColor, 12, "grey2");
            }
            case CS_TEAM_T, CS_TEAM_CT:
            {
                Format(teamColor, 12, "teamcolor");
            }
        }

        //Remove colors from message
        CRemoveColors(message, _CV_MAX_MESSAGE_LENGTH);
        RemoveHexColors(message, message, _CV_MAX_MESSAGE_LENGTH);

        //Remove colors from name
        CRemoveColors(name, MAX_NAME_LENGTH);

        //lets add in our donator/special guest tags.
        char sChatTag[64];
        char cPreChatTag[64];
        #if defined _donators_included_
        char sTemp[64];
        if(g_bDonators)
        {
            if(Donator_IsDonator(author))
            {
                if(!Donator_DisabledDonatorPrefix(author))
                {
                    Format(cPreChatTag, sizeof(cPreChatTag), "\x01[\x05♥\x01]\x01");                    
                }
            }
            if(Guest_IsSpecialGuest(author) && !Guest_DisabledSpecialGuestPrefix(author))
            {
                Guest_GetTag(author, sTemp, sizeof(sTemp));
                Format(sChatTag, sizeof(sChatTag), "\x01[\x05%s\x01]\x01", sTemp);
            }
            //suffix for donator.
            if(Donator_IsDonator(author) && Donator_GetType(author) > 1)
            {
                
                if(!Donator_DisabledChatTag(author))
                {
                    Donator_GetChatTag(author, sTemp, sizeof(sTemp));
                    Format(sChatTag, sizeof(sChatTag), "%s\x01[{lime}%s\x01]\x01", sChatTag, sTemp); //append, just incase our special guest is a donator
                }
            }
        }
        #endif

        // Format message name
        Format(name, MAX_NAME_LENGTH, "%s%s {%s}%s%s{default}", cPreChatTag, staffTag, teamColor, sChatTag, name);

        return Plugin_Changed;
    }

    if (rank > RANK_VIP && (StrContains(flagstring, "team", false) != -1 ||  StrContains(flagstring, "Cstrike_Chat_CT", false) != -1 ||  StrContains(flagstring, "Cstrike_Chat_T", false) != -1||  StrContains(flagstring, "Cstrike_Chat_Spec", false) != -1))
    {
        strcopy(message, strlen(message), message[1]);

        recipients.Clear();

        LoopValidClients(i)
        {
            int nrank = GetPlayerRank(i);
            if(RANK_VIP < nrank)
            {
                recipients.Push(GetClientUserId(i));
            }
        }

        GetRankTag(rank, buffer);
        Format(staffTag, 64, "{default}[{lime}%s{default}]", buffer);

        Format(name, MAX_NAME_LENGTH, "{yellow}[STAFF] %s{yellow} %s", staffTag, name);
        Format(message, _CV_MAX_MESSAGE_LENGTH, "{bluegrey}%s", message);
        Format(flagstring, 17, "Cstrike_Chat_All"); //Yes, I hardcoded it, sorry, I cba to make it better

        LogAction(author, -1, "\"%L\" triggered sm_say (text %s)", author, message);

        return Plugin_Changed;
    }


    if (rank > RANK_VIP && (StrContains(flagstring, "team", false) == -1 ||  StrContains(flagstring, "Cstrike_Chat_CT", false) == -1 ||  StrContains(flagstring, "Cstrike_Chat_T", false) == -1 || StrContains(flagstring, "Cstrike_Chat_Spec", false) == -1))
    {
        strcopy(message, strlen(message), message[1]);

        recipients.Clear();

        LoopValidClients(i)
        {
            recipients.Push(GetClientUserId(i));
        }      

        GetRankTag(rank, buffer);
        Format(staffTag, 64, "{default}[{lime}%s{default}]", buffer);

        Format(name, MAX_NAME_LENGTH, "{red}[ALL] %s {red}%s{default}", staffTag, name);
        Format(flagstring, 17, "Cstrike_Chat_All"); //Yes, I hardcoded it, sorry, I cba to make it better

        LogAction(author, -1, "\"%L\" triggered sm_chat (text %s)", author, message);

        return Plugin_Changed;
    }

    else
    {
        strcopy(message, strlen(message), message[1]);

        recipients.Clear();

        LoopValidClients(i)
        {
            int nrank = GetPlayerRank(i);
            if(RANK_VIP < nrank)
            {
                recipients.Push(GetClientUserId(i));
            }
        }

        recipients.Push(GetClientUserId(author));

        Format(name, MAX_NAME_LENGTH, "{yellow}[TO STAFF] %s{yellow}", name);
        Format(message, _CV_MAX_MESSAGE_LENGTH, "{bluegrey}%s", message);
        Format(flagstring, 17, "Cstrike_Chat_All"); //Yes, I hardcoded it, sorry, I cba to make it better

        LogAction(author, -1, "\"%L\" triggered sm_chat (text %s)", author, message);

        return Plugin_Changed;
    }
     
}

public Action Command_Say(int client, int args)
{
    if (args < 1)
    {
        TTT_Usage(client, "sm_say <message>");
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
        TTT_Usage(client, "sm_msay <message>");
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
        TTT_Usage(client, "sm_smsay <#userid|name> <message>");
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
        TTT_Usage(client, "sm_csay <message>");
        return Plugin_Handled;
    }

    char message[255], buffer[128];
    GetCmdArg(1, message, sizeof(message));

    for (int i; i <= args; i++)
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
        TTT_Usage(client, "sm_scsay <#userid|name> <message>");
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

    int rank = GetPlayerRank(client);

    if (args < 1)
    {
        TTT_Usage(client, "sm_chat <message>");
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
        TTT_Usage(client, "sm_msg <#userid|name> <message>");
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
        TTT_Usage(client, "sm_reply <message>");
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

void SendChatToAll(int client, char[] message)
{
    char buffer[16];
    char staffTag[64];
    char name[255];

    int rank = GetPlayerRank(client);
    
    GetRankTag(rank, buffer);
    Format(staffTag, 64, "{default}[{lime}%s{default}]", buffer);

    GetClientName(client, name, sizeof(name));
    
    Format(name, MAX_NAME_LENGTH, "{red}[ALL] %s {red}%s{default}", staffTag, name);

    CPrintToChatAll("%s: {default}%s", name, message);

    LogAction(client, -1, "\"%L\" triggered sm_say (text %s)", client, message);
}

void SendChatToAdmin(int client, char[] message)
{
    char buffer[16];
    char staffTag[64];
    char name[255];

    int rank = GetPlayerRank(client);
    GetRankTag(rank, buffer);
    Format(staffTag, 64, "{default}[{lime}%s{default}]", buffer);
    GetClientName(client, name, sizeof(name));

    LoopValidClients(i)
    {
        if(GetPlayerRank(i) > RANK_PLEB)
        {
            CPrintToChat(i, "{yellow}[STAFF] %s{yellow} %s: {bluegrey}%s", staffTag, name, message);
        }
    }

    LogAction(client, -1, "\"%L\" triggered sm_chat (text %s)", client, message);
}

void SendChatToAdminPleb(int client, char[] message)
{
    char name[255];
    GetClientName(client, name, 255);
    
    LoopValidClients(i)
    {
        if(GetPlayerRank(i) > RANK_PLEB)
        {
            CPrintToChat(i,"{yellow}[TO STAFF] %s:  {bluegrey}%s", name, message);  
        }
    }
    CPrintToChat(client,"{yellow}[TO STAFF] %s:{bluegrey}%s", name, message);

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

    char cSoundName[512];
    DynamicGetRandomSoundFile(1, 1, "inilo/general_v1_452489/chat_v1_452489/chat_beep02_452489.mp3", cSoundName, sizeof(cSoundName));

    if (!client)
    {
        PrintToServer("(Private to %N) %N: %s", targetName, client, message);
    }
    else if (target == client)
    {
        CPrintToChat(client, "[{grey}me{gold} -> {grey}me{default}] %s", message);
        //add sound.
        ClientCommand(target, "play \"%s\"", cSoundName);
    } else {
        g_iReplyTo[target] = client;
        CPrintToChat(target, "[{grey}%s{gold} -> {grey}me{default}] %s", clientName, message);
        CPrintToChat(client, "[{grey}me{gold} -> {grey}%s{default}] %s", targetName, message);
        //add sound.
        ClientCommand(target, "play \"%s\"", cSoundName);
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
