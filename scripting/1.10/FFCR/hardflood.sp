// Forlix FloodCheck
// http://forlix.org/, df@forlix.org
//
// Copyright (c) 2008-2013 Dominik Friedrichs

static float p_time_lasthardfld[MAXPLAYERS + 1];
static p_cmdcnt_hard[MAXPLAYERS + 1];
static bool p_hard_banned[MAXPLAYERS + 1];

void FloodCheckHard_Connect(client)
{
	p_time_lasthardfld[client] = 0.0;
	p_cmdcnt_hard[client] = 0;
	p_hard_banned[client] = false;
}

bool FloodCheckHard(iClient)
{
	if (!iClient || !g_fHardInterval || ++p_cmdcnt_hard[iClient] <= g_iHardNum)
		return false;
		
	float time_c = GetTickedTime();
	
	// client command frequency ok
	// or client already about to be kicked
	if (time_c >= p_time_lasthardfld[iClient] + g_fHardInterval || IsFakeClient(iClient) || IsClientInKickQueue(iClient) || p_hard_banned[iClient])
	{
		p_time_lasthardfld[iClient] = time_c;
		p_cmdcnt_hard[iClient] = 0;
		
		return false;
	}
	
	// reaching this, we should ban the client
	char str_networkid[MAX_STEAMID_LEN];
	
	if (GetClientAuthId(iClient, AuthId_Steam2, str_networkid, sizeof(str_networkid))) // we've got the networkid
	{
		char reason[MAX_MSG_LEN], ban_time[32];
		
		FriendlyTime(g_iHardBanTime * 60, ban_time, sizeof(ban_time), false);
		Format(reason, sizeof(reason), FLOOD_HARD_MSG, ban_time);
		
		if (FFCR_Ban(iClient, g_iHardBanTime, reason))
			p_hard_banned[iClient] = true;
	}
	
	return true;
} 