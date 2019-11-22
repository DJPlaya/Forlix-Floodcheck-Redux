// Forlix FloodCheck
// http://forlix.org/, df@forlix.org
//
// Copyright (c) 2008-2013 Dominik Friedrichs

static float game_chat_deadtime, game_radio_deadtime;
static float p_time_lastchatmsg[MAXPLAYERS + 1];
static int p_cmdcnt_chat[MAXPLAYERS + 1];
static bool p_floodstate[MAXPLAYERS + 1];

void FloodCheckChat_Connect(iClient)
{
	p_time_lastchatmsg[iClient] = 0.0;
	p_cmdcnt_chat[iClient] = 0;
	p_floodstate[iClient] = false;
}

public Action FloodCheckChat(iClient, args)
{
	if(!iClient)
		return Plugin_Continue;
		
	if(!IsClientInGame(iClient))
		return Plugin_Handled;
		
	bool bExcl;
	
	if(IsChatTrigger())
		bExcl = g_bExcludeChatTriggers;
		
	else
		FloodCheckHard(iClient);
		
	if(FloodDeadtime(iClient, game_chat_deadtime))
		return Plugin_Handled;
		
	if(!bExcl && FloodCheck(iClient))
		return Plugin_Handled;
		
	if(FilterChat(iClient))
		return Plugin_Handled;
		
	return Plugin_Continue;
}

public Action FloodCheckRadio(iClient, args)
{
	if(!iClient)
		return Plugin_Continue;
		
	if(!IsClientInGame(iClient) || GetClientListeningFlags(iClient) & VOICE_MUTED)
		return Plugin_Handled;
		
	if(FloodDeadtime(iClient, game_radio_deadtime))
		return Plugin_Handled;
		
	if(IsPlayerAlive(iClient) && FloodCheck(iClient))
		return Plugin_Handled;
		
	return Plugin_Continue;
}

bool FloodDeadtime(iClient, float deadtime)
{
	static float time_nc[MAXPLAYERS + 1];
	float time_c = GetTickedTime();
	
	// ignore and swallow calls within this deadtime
	// this is built into the engine as well
	if (time_c < time_nc[iClient])
		return true;
		
	time_nc[iClient] = time_c + deadtime;
	return false;
}

static bool FloodCheck(iClient)
{
	if(!iClient || !g_fChatInterval)
		return false;
		
	float time_c = GetTickedTime();
	
	if(time_c < p_time_lastchatmsg[iClient] + g_fChatInterval) // iClient has undershot the chat msg interval
	{
		p_time_lastchatmsg[iClient] = time_c;
		
		if(p_cmdcnt_chat[iClient] < g_iChatNum) // add a flood token
			p_cmdcnt_chat[iClient]++;
			
		// maximum tokens accumulated
		// Client is now flooding
		if(p_cmdcnt_chat[iClient] >= g_iChatNum)
		{
			p_floodstate[iClient] = true;
			return true;
		}
	}
	
	else // Clients chat msg frequency is below the maximum
	{
		p_time_lastchatmsg[iClient] = time_c;
		
		if(p_cmdcnt_chat[iClient] > 0) // remove a flood token
			p_cmdcnt_chat[iClient]--;
			
		if(p_cmdcnt_chat[iClient] < 0) // level out at zero
			p_cmdcnt_chat[iClient] = 0;
	}
	
	p_floodstate[iClient] = false;
	return false;
}

static bool FilterChat(iClient)
{
	char text[MAX_MSG_LEN + 2];
	text[0] = '\0';
	
	GetCmdArgString(text, sizeof(text));
	StripQuotes(text);
	
	if(MakeStringPrintable(text, sizeof(text), "")) // something had to be modified - not conform
	{
		PrintToChat(iClient, MALFORMED_MESSAGE_MSG);
		return true;
	}
	
	return false;
}

SetupChatDetection_cstrike()
{
	RegConsoleCmd("coverme", FloodCheckRadio);
	RegConsoleCmd("enemydown", FloodCheckRadio);
	RegConsoleCmd("enemyspot", FloodCheckRadio);
	RegConsoleCmd("fallback", FloodCheckRadio);
	RegConsoleCmd("followme", FloodCheckRadio);
	RegConsoleCmd("getinpos", FloodCheckRadio);
	RegConsoleCmd("getout", FloodCheckRadio);
	RegConsoleCmd("go", FloodCheckRadio);
	RegConsoleCmd("holdpos", FloodCheckRadio);
	RegConsoleCmd("inposition", FloodCheckRadio);
	RegConsoleCmd("needbackup", FloodCheckRadio);
	RegConsoleCmd("negative", FloodCheckRadio);
	RegConsoleCmd("regroup", FloodCheckRadio);
	RegConsoleCmd("report", FloodCheckRadio);
	RegConsoleCmd("reportingin", FloodCheckRadio);
	RegConsoleCmd("roger", FloodCheckRadio);
	RegConsoleCmd("sectorclear", FloodCheckRadio);
	RegConsoleCmd("sticktog", FloodCheckRadio);
	RegConsoleCmd("stormfront", FloodCheckRadio);
	RegConsoleCmd("takepoint", FloodCheckRadio);
	RegConsoleCmd("takingfire", FloodCheckRadio);
	
	game_chat_deadtime = 0.75;
	game_radio_deadtime = 1.5;
	
	return;
}

SetupChatDetection_dod()
{
	RegConsoleCmd("voice_areaclear", FloodCheckRadio);
	RegConsoleCmd("voice_attack", FloodCheckRadio);
	RegConsoleCmd("voice_backup", FloodCheckRadio);
	RegConsoleCmd("voice_bazookaspotted", FloodCheckRadio);
	RegConsoleCmd("voice_ceasefire", FloodCheckRadio);
	RegConsoleCmd("voice_cover", FloodCheckRadio);
	RegConsoleCmd("voice_coverflanks", FloodCheckRadio);
	RegConsoleCmd("voice_displace", FloodCheckRadio);
	RegConsoleCmd("voice_dropweapons", FloodCheckRadio);
	RegConsoleCmd("voice_enemyahead", FloodCheckRadio);
	RegConsoleCmd("voice_enemybehind", FloodCheckRadio);
	RegConsoleCmd("voice_fallback", FloodCheckRadio);
	RegConsoleCmd("voice_fireinhole", FloodCheckRadio);
	RegConsoleCmd("voice_fireleft", FloodCheckRadio);
	RegConsoleCmd("voice_fireright", FloodCheckRadio);
	RegConsoleCmd("voice_gogogo", FloodCheckRadio);
	RegConsoleCmd("voice_grenade", FloodCheckRadio);
	RegConsoleCmd("voice_hold", FloodCheckRadio);
	RegConsoleCmd("voice_left", FloodCheckRadio);
	RegConsoleCmd("voice_medic", FloodCheckRadio);
	RegConsoleCmd("voice_mgahead", FloodCheckRadio);
	RegConsoleCmd("voice_moveupmg", FloodCheckRadio);
	RegConsoleCmd("voice_needammo", FloodCheckRadio);
	RegConsoleCmd("voice_negative", FloodCheckRadio);
	RegConsoleCmd("voice_niceshot", FloodCheckRadio);
	RegConsoleCmd("voice_right", FloodCheckRadio);
	RegConsoleCmd("voice_sniper", FloodCheckRadio);
	RegConsoleCmd("voice_sticktogether", FloodCheckRadio);
	RegConsoleCmd("voice_takeammo", FloodCheckRadio);
	RegConsoleCmd("voice_thanks", FloodCheckRadio);
	RegConsoleCmd("voice_usebazooka", FloodCheckRadio);
	RegConsoleCmd("voice_usegrens", FloodCheckRadio);
	RegConsoleCmd("voice_usesmoke", FloodCheckRadio);
	RegConsoleCmd("voice_wegothim", FloodCheckRadio);
	RegConsoleCmd("voice_wtf", FloodCheckRadio);
	RegConsoleCmd("voice_yessir", FloodCheckRadio);
	
	game_chat_deadtime = 0.75;
	game_radio_deadtime = 2.5;
	
	return;
}

SetupChatDetection_tf()
{
	// no radio spam detection for tf (built in already)
	game_chat_deadtime = 0.75;
	game_radio_deadtime = 0.0;
	
	return;
}

SetupChatDetection_misc()
{
	// default values for misc games
	// and no radio detection
	
	game_chat_deadtime = 0.75;
	game_radio_deadtime = 0.0;
	
	return;
}

public Native_IsClientFlooding(Handle plugin, numParams)
{
	return _:p_floodstate[GetNativeCell(1)];
}