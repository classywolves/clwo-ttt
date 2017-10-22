
public void spectate_OnPluginStart()
{
	spectate_RegisterCmds();
	//teamban_RegisterCvars();
	spectate_HookEvents();

	spectate_PostPluginStart();
}

public void spectate_PostPluginStart()
{

}



public void spectate_HookEvents()
{

}

public void spectate_RegisterCmds()
{
	RegConsoleCmd("sm_spec", Command_Spec, "Chooses a player who you want to spectate and switch you to spectators");
}




public Action Command_Spec(int client, int args)
{
	if(IsValidPlayer(client))
	{
		ReplyToCommand(client," [SM] You cannot specate people when you are alive");
		return Plugin_Handled;
	}
	if (args < 1)
	{
		
		Handle menu = CreateMenu(Command_SpecCallback);
		SetMenuTitle(menu, "What player do you want to specate");
		int count;
		for (int i = 1; i <= MaxClients; i++)
		{
			if(IsValidPlayer(i))
			{
				char name[32];
				char targetid[3];
				IntToString(i, targetid, sizeof(targetid));
				GetClientName(i, name, sizeof(name));
				AddMenuItem(menu, targetid, name);
				count++;
			}
		}
		if(count == 0)
		{
			AddMenuItem(menu, "","No players online",ITEMDRAW_DISABLED);
		}
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
		return Plugin_Handled;
	}


	char arg[65];
	GetCmdArg(1, arg, sizeof(arg));
	int target = FindTarget(client,arg,true,false);
	if(target != -1)
	{
		specate_Spec(client,target);

	}
	else
	{
		ReplyToCommand(client, " [SM] That target does not exist");
	}
	return Plugin_Handled;
					
}

public void specate_Spec(int client,int target)
{
	if(IsValidPlayer(client) || !IsValidPlayer(target))
		return;
	PrintToChat(client," [SM] You started specating '%N'",target);
	//ChangeClientTeam(client, CS_TEAM_SPECTATOR);
	SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", target);
	SetEntProp(client, Prop_Send, "m_iObserverMode", 4);
}

//This is called after selecting a name.
public int Command_SpecCallback(Menu menu, MenuAction action,int param1,int param2)
{
	/* If an option was selected, tell the client about the item. */
	new client = param1;
	if (action == MenuAction_Select)
	{


		char info[512];
		bool found = menu.GetItem(param2, info, sizeof(info));
		//PrintToChat(param1, "You selected item: %d (found? %d info: %s)", param2, found, info);

		int target = StringToInt(info); //disconnected player
		if(IsValidClient(target))
		{
			specate_Spec(client,target);
		}
		



	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}