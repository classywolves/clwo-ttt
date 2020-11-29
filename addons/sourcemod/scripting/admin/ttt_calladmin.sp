#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <cstrike>

#include <generics>
#include <chat-processor>
#include <SteamWorks>

#pragma semicolon 1

#define ITEMDRAW_SPACER_NOSLOT ((1<<1)|(1<<3))

public Plugin myinfo = {
	name = "TTT Calladmin",
	author = "Sourcecode",
	description = "Calladmin for CLWO TTT",
	version = "0.9",
	url = ""
};

//CallAdmin type
enum eCallType {
	CallType_none,
	CallType_mb,
	CallType_nostaff,
	CallType_other
}

/////////
//Globals
/////////
ArrayList g_aLastChatMessages = null; //Arraylist that stores the last 15 messages

eCallType g_iClientCallType[MAXPLAYERS+1]; //CallType
bool g_bClientCalledAdmin[MAXPLAYERS+1]; //Has client called in the last 1 mins?
bool g_bClientIsTypingReason[MAXPLAYERS+1]; //Is client typing a custom reason?
char g_cCharReason[MAXPLAYERS+1][512]; //call reason
char g_cReasonBuffer[MAXPLAYERS+1][512]; //Custom reason buffer
int g_iClientIsReporting[MAXPLAYERS+1]; //Is client creating a call?

//Convars
ConVar sv_visiblemaxplayers;

//Database
Database db;

public void OnPluginStart() {
	//Arraylist that stores the last 15 messages
	g_aLastChatMessages = new ArrayList(256);
	
	sv_visiblemaxplayers = FindConVar("sv_visiblemaxplayers");

	Database.Connect(T_Connect, "ttt");

	//Commands
	RegConsoleCmd("sm_calladmin", Command_CallAdmin, "sm_calladmin - Sends a message to staff members");
	RegConsoleCmd("sm_callstaff", Command_CallAdmin, "sm_callstaff - Sends a message to staff members");
}

////////
//Events
////////
public Action CP_OnChatMessage(int& client, ArrayList recipients, char[] flagstring, char[] name, char[] message, bool& processcolors, bool& removecolors)
{
	//Was client typing his reason?
	if (g_bClientIsTypingReason[client]) {
		//Get typed text and strip the quotes
		char cText[128];
		strcopy(cText, sizeof(cText), message);

		//Check for aborting the naming procedure
		if (StrEqual(cText, "!stop", false) || StrEqual(cText, "!cancel", false)) {
			PrintToChat(client, " [SM] Aborted naming procedure");
			
			//reset global variables
			strcopy(g_cReasonBuffer[client], 512, "");
			g_bClientIsTypingReason[client] = false;

			return Plugin_Continue;
		}

		//Copy msg to global variable
		strcopy(g_cReasonBuffer[client], 512, cText);
		
		//Show client confirm panel
		//BuildFinalPanel(client, -1, g_cReasonBuffer[client]);

		//Reset global variable
		g_bClientIsTypingReason[client] = false;
		
		return Plugin_Continue;
	}

	if (message[0] != '@') // Not staff / all say or pm.
	{
		//Format msg with name infront of it
		char cLastMessages[512];
		Format(cLastMessages, sizeof(cLastMessages), "%.32N: %s", client, message);
		
		//Push the formatted string to the arraylist
		g_aLastChatMessages.PushString(cLastMessages);

		//Trim the array list to max 15 length
		trimArray(g_aLastChatMessages, 15);
	}

	return Plugin_Changed;
}

//////////
//Commands
//////////
public Action Command_CallAdmin(int client, int args) {
	if(!IsValidClient(client))
		return Plugin_Handled;
	
	//Client already called admin in last 1 minutes
	if(g_bClientCalledAdmin[client]) {
		PrintToChat(client, "[SM] You already requested staff to come. Please be patient.");
		//return Plugin_Handled;
	}

	//Count staff
	int staff = 0;
	for (int i = 1; i <= MaxClients; i++) {
		//Make sure they have rights and are not in spec, also dont count yourself so staff can call admin aswell
		if (IsValidClient(i) && CheckCommandAccess(i, "", ADMFLAG_GENERIC) && GetClientTeam(i) != CS_TEAM_SPECTATOR && i != client)
		{
			staff++;
			PrintToConsole(client, "[debug] Found: %N, number %i", i, staff);
		}
	}

	//Tell them staff is already online
	if(staff != 0) {
		PrintToChat(client, "[SM] There is already a staff member online, you can message them by putting an '@' infront of your message");
		return Plugin_Handled;
	}

	//Show the reson panel
	RequestReasonForStaffCall(client);

	return Plugin_Handled;
}

///////////
//Functions
///////////
public void RequestReasonForStaffCall(int client) {
	//reaon panel
	Menu menu = new Menu(RequestReasonForStaffCall_Callback);
	menu.SetTitle("What is the reason you are requesting staff for?"); //max 8 per menu
	menu.AddItem("#mb#", "A player is misbehaving");
	menu.AddItem("#nostaff#", "General chaos on the server, definitely need staff");
	
	//TODO: Fix custom reason
	//menu.AddItem("#other#", "Other reason");

	menu.Display(client, MENU_TIME_FOREVER);
}

public int RequestReasonForStaffCall_Callback(Menu menu, MenuAction action, int param1, int param2) {
	switch(action) {
		case MenuAction_Select: {
			int client = param1;
			if(!IsValidClient(client))
				return;

			//get selected item
			char info[32];
			menu.GetItem(param2, info, sizeof(info));

			//misbehaving
			if(StrEqual(info,"#mb#")) {
				g_iClientCallType[client] = CallType_mb;
				SelectPlayer(client);
			}

			//no staff, need staff..
			if(StrEqual(info,"#nostaff#")) {
				//send to slack.
				g_iClientCallType[client] = CallType_nostaff;
				BuildFinalPanel(client, -1, "");
				
			}

			//custom reason
			if(StrEqual(info,"#other#")) {
				//Set global variables
				g_bClientIsTypingReason[client] = true;
				g_iClientCallType[client] = CallType_other;
				
				//Show the panel that they can type their reason in chat
				Panel mSayPanel = new Panel();
				mSayPanel.SetTitle("Please type the reason in the chat");
				mSayPanel.DrawText("(or !stop)");
				mSayPanel.DrawText("(or !cancel)");
				mSayPanel.DrawItem("Exit", ITEMDRAW_CONTROL);
				mSayPanel.Send(client, Handler_DoNothing, 30);

				delete mSayPanel;
			}
		}

		case MenuAction_End: {
			delete menu;
		}
	}
}

public void SelectPlayer(int client) {
	PrintToConsole(client, "selecting player");

	//Ask who is misbehaving
	Menu menu = new Menu(SelectPlayer_Callback);
	menu.SetTitle("Who is misbehaving"); //max 8 per menu
	menu.AddItem("#multiple#", "Multiple people");
	
	char cTemp[64];
	char cTemp2[64];
	for (int x = 1; x <= MaxClients; x++) {
		if(!IsValidClient(x))
			continue;
		
		Format(cTemp, sizeof(cTemp), "%i", GetClientUserId(x)); //userid
		Format(cTemp2, sizeof(cTemp2), "%N", x); //nickname

		//Add to menu
		menu.AddItem(cTemp, cTemp2);
	}

	menu.Display(client, MENU_TIME_FOREVER);
}

public int SelectPlayer_Callback(Menu menu, MenuAction action, int param1, int param2) {
	switch(action) {
		case MenuAction_Select: {
			int client = param1;
			if(!IsValidClient(client))
				return;

			//Get selected item
			char info[32];
			menu.GetItem(param2, info, sizeof(info));
			
			if(StrEqual(info, "#multiple#")) {
				//ask for the reason.
				SelectReasonForPlayer(client, -1);
			} else {
				int target = GetClientOfUserId(StringToInt(info));
				SelectReasonForPlayer(client, target);
			}
	
		}

		case MenuAction_End: {
			delete menu;
		}
	}
}

public void SelectReasonForPlayer(int client, int target) {
	//Set client target
	g_iClientIsReporting[client] = target;

	//Menu to select what player is doing
	Menu menu = new Menu(SelectReasonForPlayer_Callback);
	menu.SetTitle("What is going on with this player?"); //max 8 per menu

	menu.AddItem("#rdm#", "The player is RDM-ing");
	menu.AddItem("#spam#", "Spamming microphone");
	menu.AddItem("#racism#", "The player is racist");
	menu.AddItem("#cheating#", "The player is hacking");
	menu.AddItem("#clwo#", "The player is breaking CLWO community rules");

	menu.Display(client, MENU_TIME_FOREVER);
}

public int SelectReasonForPlayer_Callback(Menu menu, MenuAction action, int param1, int param2) {
	int client = param1;
	if(!IsValidClient(client))
		return;

	switch(action) {
		case MenuAction_Select: {
			//get selected item
			char info[32];
			menu.GetItem(param2, info, sizeof(info));

			//Show confirm panel
			BuildFinalPanel(client, g_iClientIsReporting[client], info);
		}

		case MenuAction_End: {
			delete menu;
		}
	}
}

public void BuildFinalPanel(int client, int target, const char[] cReason) {
	//Build confirm panel
	Panel panel = new Panel();
	panel.SetTitle("Please confirm the following:"); 
	panel.DrawItem("",ITEMDRAW_SPACER_NOSLOT);
	panel.DrawText("I understand that any abuse or unnecessary use of this system will lead to a week ban.");
	panel.DrawText("You are requesting a staff member to join the server for the following reason:");
	panel.DrawItem("",ITEMDRAW_SPACER_NOSLOT);
	
	//Format the reason string, based on call type
	switch(g_iClientCallType[client])
	{
		case CallType_none:
		{
			panel.DrawText("No reason was given");
			Format(g_cCharReason[client], 512, "No reason was given");
		}
		case CallType_mb:
		{
			char cTemp[512];
			TranslateRequestReason(cReason, cTemp, sizeof(cTemp));
			if(IsValidClient(target))
			{
				int AccountID = GetSteamAccountID(target, true);
				Format(g_cCharReason[client], 512, "Reporting %N [acc: %i] for [%s]",target, AccountID, cTemp);
			}
			else
			{
				Format(g_cCharReason[client], 512, "Reporting multiple people for [%s]", cTemp);
			}
			panel.DrawText(g_cCharReason[client]);
			
		}
		case CallType_nostaff:
		{
			Format(g_cCharReason[client], 512, "General chaos on the server, definitely need staff");
			panel.DrawText("General chaos on the server, definitely need staff");
		}
		case CallType_other:
		{
			panel.DrawText(cReason);
			Format(g_cCharReason[client], 512, cReason);
		}
	}

	panel.DrawItem("", ITEMDRAW_SPACER_NOSLOT);
	
	//Add two buttons
	panel.DrawItem("Yes (Call staff)", ITEMDRAW_CONTROL);
	panel.DrawItem("No (I'm not so sure)", ITEMDRAW_CONTROL);

	//Send panel to client
	panel.Send(client, RequestPanel_Callback, MENU_TIME_FOREVER);

	delete panel;
}

public int RequestPanel_Callback(Menu menu, MenuAction action, int param1, int param2) {
	switch(action) {
		case MenuAction_Select: {
			int client = param1;
			if(!IsValidClient(client))
				return;

			//Check if selected is yes
			if(param2 == 1) {
				AskSlackForStaff(client);
			} else {
				//Cancel the calladmin
				g_iClientIsReporting[client] = -1;
				g_bClientIsTypingReason[client] = false;
				PrintToChat(client, "[SM] Aborting staff call");
			}
		}

		case MenuAction_End: {
			delete menu;
		}
	}
}

public void AskSlackForStaff(int client) {
	//Get client account id
	int AccountID = GetSteamAccountID(client, true);
	if(AccountID == 0)
		return;

	//Get map name
	char cMap[255];
	GetCurrentMap(cMap, sizeof(cMap));

	//Escape the strings to save the formatting in slack
	char cReason[512];
	db.Escape(cMap, cMap, sizeof(cMap));
	db.Escape(g_cCharReason[client], cReason, sizeof(cReason));

	//Get max players
	char cMaxPlayers[8];
	if(sv_visiblemaxplayers != null)
	{
		if(sv_visiblemaxplayers.IntValue == -1)
		{
			Format(cMaxPlayers, sizeof(cMaxPlayers), "%i", GetMaxHumanPlayers());
		}
		else
		{
			sv_visiblemaxplayers.GetString(cMaxPlayers, sizeof(cMaxPlayers));
		}
	}

	//Get connected players
	char cClientCount[8];
	int connected = 0;
	for (int i = 1; i <= MaxClients; i++) 
	{
		if(IsValidClient(i))
		{
			connected++;
		}
	}
	Format(cClientCount, sizeof(cClientCount), "%i", connected);

	//Format complete calladmin string
	char cPrint[1028];
	Format(cPrint, sizeof(cPrint), "*%N* [%i] is requesting staff on the server.\nMap[%s] Players[%s/%s] Score[CT: %i - %i :T]\n`%s`", client, AccountID, cMap, cClientCount, cMaxPlayers, GetTeamScore(CS_TEAM_CT), GetTeamScore(CS_TEAM_CT), cReason);
	
	//grab latest messages.
	char cChatHistory[2048];
	char cTemp[128];
	Format(cChatHistory, sizeof(cChatHistory), "```");
	for(int i = 0; i < g_aLastChatMessages.Length ; i++ )
	{
		g_aLastChatMessages.GetString(i, cTemp, sizeof(cTemp));
		Format(cChatHistory, sizeof(cChatHistory), "%s\n%s", cChatHistory, cTemp);
	}
	Format(cChatHistory, sizeof(cChatHistory), "%s ```", cChatHistory);

	//Format join link
	char cJoinMessage[512];
	Format(cJoinMessage, sizeof(cJoinMessage), "*join server ->* steam://connect/ttt.clwo.eu");
	db.Escape(cJoinMessage, cJoinMessage, sizeof(cJoinMessage));

	//Format complete message that will get send to slack
	char cMessage[4096];
	Format(cMessage, sizeof(cMessage), "%s\n%s\n%s", cPrint, cChatHistory, cJoinMessage);

	//Get client steamid for the db
	char steamid[32]; 
	GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));

	//Make the call to nilos api, to push it to slack
	Handle hHTTP_request = SteamWorks_CreateHTTPRequest(k_EHTTPMethodGET, "https://trclwo.inilo.net/relay.php");
	if(hHTTP_request != null)
	{
		SteamWorks_SetHTTPRequestGetOrPostParameter(hHTTP_request, "to", "ttt"); //To channel
		SteamWorks_SetHTTPRequestGetOrPostParameter(hHTTP_request, "from", "Call Admin"); //From username
		SteamWorks_SetHTTPRequestGetOrPostParameter(hHTTP_request, "text", cMessage); //Text to post
		SteamWorks_SetHTTPRequestGetOrPostParameter(hHTTP_request, "icon_emoji", ":rotating_light:"); //Emoji profile pic
	}
	else
	{
		LogError("Send Msg failed to setup a handle for HTTP requests");
	}

	//Check if everything worked	
	if (!hHTTP_request || !SteamWorks_SetHTTPCallbacks(hHTTP_request, Slack_Callback) || !SteamWorks_SendHTTPRequest(hHTTP_request))
	{
		delete hHTTP_request;
	}

	//Tell client it worked aswell
	PrintToChat(client, "\x01[\x02CallAdmin\x01] Admins have been notified");

	//Prevent them from calling again for 1 min
	g_bClientCalledAdmin[client] = true;
	CreateTimer(60.0, Timer_Resetcalladmin, client);
}

//Function to translate reason to a formatted message
public void TranslateRequestReason(const char[] cInput, char[] output, int maxsize)
{

	if(StrEqual(cInput, "#fk#"))
	{
		Format(output, maxsize, "%s", "Freekilling");
	}
	if(StrEqual(cInput, "#rdm#"))
	{
		Format(output, maxsize, "%s", "RDM-ing");
	}
	if(StrEqual(cInput, "#spam#"))
	{
		Format(output, maxsize, "%s", "Spamming microphone");
	}
	if(StrEqual(cInput, "#racism#"))
	{
		Format(output, maxsize, "%s", "The player is racist");
	}
	if(StrEqual(cInput, "#cheating#"))
	{
		Format(output, maxsize, "%s", "The player is hacking");
	}
	if(StrEqual(cInput, "#clwo#"))
	{
		Format(output, maxsize, "%s", "The player is breaking CLWO community rules");
	}
}

////////
//Timers
////////

//Timer to reset if client has called admin
public Action Timer_Resetcalladmin(Handle timer, any client)
{
	g_bClientCalledAdmin[client] = false;
}

///////////////
//HTTP callback
///////////////
public void Slack_Callback(Handle hRequest, bool bFailure, bool bRequestSuccessful, EHTTPStatusCode eStatusCode) {
	if(bFailure) {
		LogError("[Slack_CallAdmin] request failed, status code: %i", view_as<int>(eStatusCode));
	}
}

///////////////
//SQL CALLBACKS
///////////////
public void T_Connect(Database database, const char[] error, any data) {
	if (database == null) {
		LogError("[Calladmin] Error connecting with database (%s)", error);

		return;
	}

	PrintToServer("[Calladmin] Succesfully connected to database");
	db = database;

	return;
}

////////
//stocks
////////
stock void trimArray(ArrayList array, int size) {
	int asize = array.Length;

	if(asize <= size) {
		return;
	}

	for(int i = 0; i < asize-size; i++) {
		array.Erase(i);
	}
}

public int Handler_DoNothing(Menu menu, MenuAction action, int param1, int param2)
{
	//do nothing
}
