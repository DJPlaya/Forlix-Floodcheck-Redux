// Forlix FloodCheck
// http://forlix.org/, df@forlix.org
//
// Copyright (c) 2008-2013 Dominik Friedrichs

static float p_time_lastnamefld[MAXPLAYERS + 1];
static int p_cmdcnt_name[MAXPLAYERS + 1];
static bool p_name_banned[MAXPLAYERS + 1];

void FloodCheckName_Connect(iClient)
{
	p_time_lastnamefld[iClient] = GetTickedTime();
	p_cmdcnt_name[iClient] = 0;
	p_name_banned[iClient] = false;
}

bool FloodCheckName(iClient)
{
	if (!iClient || !g_fNameInterval || ++p_cmdcnt_name[iClient] <= g_iNameNum)
		return false;
		
	float time_c = GetTickedTime();
	// iClient name change frequency ok or iClient already about to be kicked
	if (time_c >= p_time_lastnamefld[iClient] + g_fNameInterval || IsFakeClient(iClient) || IsClientInKickQueue(iClient) || p_name_banned[iClient])
	{
		p_time_lastnamefld[iClient] = time_c;
		p_cmdcnt_name[iClient] = 0;
		
		return false;
	}
	
	// reaching this, we should ban the Client
	char str_networkid[MAX_STEAMID_LEN];
	if (GetClientAuthId(iClient, AuthId_Steam2, str_networkid, sizeof(str_networkid))) // we've got the networkid // GetClientAuthString(iClient, str_networkid, sizeof(str_networkid))
	{
		char reason[MAX_MSG_LEN];
		char ban_time[32];
		
		FriendlyTime(g_iNameBanTime * 60, ban_time, sizeof(ban_time), false);
		Format(reason, sizeof(reason), FLOOD_NAME_MSG, ban_time);
		
		if (FFCR_Ban(iClient, g_iNameBanTime, reason))
			p_name_banned[iClient] = true;
	}
	
	return true;
} 