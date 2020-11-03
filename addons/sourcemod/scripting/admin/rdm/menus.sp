int MenuHandler_RDM(Menu menu, MenuAction action, int client, int data) {
    switch (action) {
        case MenuAction_Select: {
            char info[8];
            menu.GetItem(data, info, 8);
            g_playerData[client].currentDeath = StringToInt(info);

            Menu punishMenu = new Menu(MenuHandler_PunishChoice);
            punishMenu.SetTitle("Would you like you killer to be?");
            punishMenu.AddItem("", "Slain next round");
            punishMenu.AddItem("", "Warned");

            punishMenu.Display(client, 240);
        }
        case MenuAction_End:
        {
            delete menu;
        }
    }
}

int MenuHandler_PunishChoice(Menu menu, MenuAction action, int client, int choice)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            CaseChoice punishment = CaseChoice_None;
            if (choice == 0)
            {
                punishment = CaseChoice_Slay;
            }
            else if (choice == 1)
            {
                punishment = CaseChoice_Warn;
            }

            Db_InsertReport(client, g_playerData[client].currentDeath, punishment);
        }
        case MenuAction_End:
        {
            delete menu;
        }
    }
}

int MenuHandler_Verdict(Menu menu, MenuAction action, int client, int choice)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            CaseVerdict verdict = CaseVerdict_None;
            if (choice == 0)
            {
                verdict = CaseVerdict_Innocent;
            }
            else if (choice == 1)
            {
                verdict = CaseVerdict_Guilty;
            }

            Db_UpdateVerdict(client, g_playerData[client].currentCase, verdict);
        }
        case MenuAction_End:
        {
            delete menu;
        }
    }
}
