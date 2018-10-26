// Forlix FloodCheck
// http://forlix.org/, df@forlix.org
//
// Copyright (c) 2008-2013 Dominik Friedrichs

static float p_time_lastnamefld[MAXPLAYERS + 1];
static p_cmdcnt_name[MAXPLAYERS + 1];
static bool p_name_banned[MAXPLAYERS + 1];

FloodCheckName_Connect(client)
{
	p_time_lastnamefld[client] = GetTickedTime();
	p_cmdcnt_name[client] = 0;
	p_name_banned[client] = false;
	
	return;
}

bool FloodCheckName(client)
{
	if(!client || !name_interval || ++p_cmdcnt_name[client] <= name_num)
		return false;
		
	float time_c = GetTickedTime();
	
	// client name change frequency ok
	// or client already about to be kicked
	if(time_c >= p_time_lastnamefld[client] + name_interval || IsFakeClient(client) || IsClientInKickQueue(client) || p_name_banned[client])
	{
		p_time_lastnamefld[client] = time_c;
		p_cmdcnt_name[client] = 0;
		
		return false;
	}
	
	// reaching this, we should ban the client
	char str_networkid[MAX_STEAMID_LEN];
	
	if(GetClientAuthId(client, AuthId_Steam2, str_networkid, sizeof(str_networkid))) // we've got the networkid // GetClientAuthString(client, str_networkid, sizeof(str_networkid))
	{
		char reason[MAX_MSG_LEN];
		char ban_time[32];
		
		FriendlyTime(name_ban_time * 60, ban_time, sizeof(ban_time), false);
		Format(reason, sizeof(reason), FLOOD_NAME_MSG, ban_time);
		
		BanClient(client, name_ban_time, BANFLAG_AUTO, reason, reason, "Name-flooding");
		p_name_banned[client] = true;
	}
	
	return true;
}