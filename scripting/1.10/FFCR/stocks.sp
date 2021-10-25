// Forlix FloodCheck
// http://forlix.org/, df@forlix.org
//
// Copyright (c) 2008-2013 Dominik Friedrichs

/*
* Performs and SB++-, SB-, Material Admin or Server-Ban
* 
* @param iClient	Client UID.
* @param iTime		Bantime in Minutes, 0 = Forever.
* @param cReason	The Ban Reason.
* @param ...		Variable Number of Format Parameters.
* @return			True if the Ban was succesfull, False if not
*/
bool FFCR_Ban(const iClient, iTime, const char[] cReason, any...)
{
	char cReason2[256];
	VFormat(cReason2, sizeof(cReason2), cReason, 4);
	
	if (iTime < 5) // Do not send Bans under 5min to SB // TODO: Add Cvar
	{
		if (g_bSBMaterialAdmin)
		{
			char cSteamID[16], cName[32], cIP[MAX_IPPORT_LEN];
			GetClientAuthId(iClient, AuthId_Steam3, cSteamID, 16);
			GetClientIP(iClient, cIP, MAX_IPPORT_LEN); // No Port
			GetClientName(iClient, cName, 32);
			if(!MAOffBanPlayer(0, MA_BAN_STEAM, cSteamID, cIP, cName, iTime, cReason2))
			{
				LogError("[Error] Failed to add an SB Material Admin Offline Ban for '%L'", iClient);
				MALog(MA_LogAction, "[Error][FFCR] Failed to add an Offline Ban for '%L'", iClient);
				if (!BanClient(iClient, iTime, BANFLAG_AUTHID, cReason2, cReason2, "FFCR"))
				{
					LogError("[Error] Failed to Server Ban Client '%L' after an SB Material Admin Offline Ban also failed", iClient);
					return false;
				}
			}
		}
		
		else
			if (!BanClient(iClient, iTime, BANFLAG_AUTHID, cReason2, cReason2, "FFCR"))
			{
				LogError("[Error] Failed to Server Ban Client '%L'", iClient);
				return false;
			}
	}
	
	if (g_bSourceBansPP)
	{
		SBPP_BanPlayer(0, iClient, iTime, cReason2); // Admin 0 is the Server in SBPP, this ID CAN be edited manually in the Database to show Name "Server" on the Webpanel
		return true;
	}
	
	else if (g_bSBMaterialAdmin)
	{
		if(!MABanPlayer(0, iClient, MA_BAN_STEAM, iTime, cReason2))
		{
			LogError("[Error] Failed to add an SB Material Admin Offline Ban for '%L'", iClient);
			MALog(MA_LogAction, "[Error][FFCR] Failed to add an Offline Ban for '%L'", iClient);
			if (!BanClient(iClient, iTime, BANFLAG_AUTHID, cReason2, cReason2, "FFCR"))
			{
				LogError("[Error] Failed to Server Ban Client '%L' after an SB Material Admin Ban also failed", iClient);
				return false;
			}
		}
	}
	
	else if (g_bSourceBans)
	{
		SBBanPlayer(0, iClient, iTime, cReason2);
		return true;
	}
	
	else
		if (!BanClient(iClient, iTime, BANFLAG_AUTHID, cReason2, cReason2, "FFCR"))
		{
			LogError("[Error] Failed to Server Ban Client '%L'", iClient);
			return false;
		}
		
	return false;
}

bool FriendlyTime(time_s, char[] str_ftime, str_ftime_len, bool compact = true)
{
	char days_pf[16], hrs_pf[16], mins_pf[16], secs_pf[16];
	
	if (compact)
	{
		days_pf = "d";
		hrs_pf = "h";
		mins_pf = "m";
		secs_pf = "s";
	}
	
	else
	{
		days_pf = " days";
		hrs_pf = " hours";
		mins_pf = " minutes";
		secs_pf = " seconds";
	}
	
	if (time_s < 0)
	{
		str_ftime[0] = '\0';
		return false;
	}
	
	int days = time_s / 86400;
	int hrs = (time_s / 3600) % 24;
	int mins = (time_s / 60) % 60;
	int secs = time_s % 60;
	
	if (time_s < 60)
		Format(str_ftime, str_ftime_len, "%u%s", secs, secs_pf);
		
	else if (time_s < 3600)
		Format(str_ftime, str_ftime_len, "%u%s %u%s", mins, mins_pf, secs, secs_pf);
		
	else if (time_s < 86400)
		Format(str_ftime, str_ftime_len, "%u%s %u%s", hrs, hrs_pf, mins, mins_pf);
		
	else
		Format(str_ftime, str_ftime_len, "%u%s %u%s", days, days_pf, hrs, hrs_pf);
		
	return true;
}

bool IsClientNameAllowed(client)
{
	char name[MAX_NAME_LEN];
	name[0] = '\0';
	
	GetClientName(client, name, sizeof(name));
	int len = strlen(name);
	
	if (name[0] == '&' && len >= 2 && name[len - 1] == '&') // those &names& cause clientside glitches
		return false;
		
	if (FindCharInString(name, '%') >= 0) // also disallow any % just in case
		return false;
		
	// finally test against general string restrictions
	return !MakeStringPrintable(name, sizeof(name), "");
}

bool MakeStringPrintable(char[] str, str_len_max, const char[] empty)
{
	// replaces sequences of \n and \t with space if
	// surrounded by non-space printable characters.
	// removes all other control characters, and if
	// the resulting string has zero-length or contains
	// only spaces, replaces it with the empty-string.
	
	int r, w;
	bool modified, nonspace, addspace;
	
	if (str[0])
	{
		do
		{
			if (str[r] < '\x20')
			{
				modified = true;
				
				if ((str[r] == '\n' || str[r] == '\t') && w > 0 && str[w - 1] != '\x20')
					addspace = true;
			}
			
			else
			{
				if (str[r] != '\x20')
				{
					nonspace = true;
					
					if (addspace)
						str[w++] = '\x20';
				}
				
				addspace = false;
				str[w++] = str[r];
			}
		}
		while (str[++r]);
		
		str[w] = '\0';
	}
	
	if (!nonspace)
	{
		modified = true;
		strcopy(str, str_len_max, empty);
	}
	
	return modified;
}

bool TruncateString(char[] str, str_len, truncate_to)
{
	if (str_len <= truncate_to)
		return false;
		
	if (truncate_to < 3)
		truncate_to = 3;
		
	str[truncate_to - 3] = '.';
	str[truncate_to - 2] = '.';
	str[truncate_to - 1] = '.';
	str[truncate_to] = '\0';
	
	return true;
} 