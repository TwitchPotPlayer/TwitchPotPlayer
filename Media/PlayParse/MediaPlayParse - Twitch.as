/*
	This is the source code of Twitch media parse extension.
	Copyright github.com/23rd, 2018-2019.
*/	

//	string GetTitle() 									-> get title for UI
//	string GetVersion									-> get version for manage
//	string GetDesc()									-> get detail information
//	string GetLoginTitle()								-> get title for login dialog
//	string GetLoginDesc()								-> get desc for login dialog
//	string ServerCheck(string User, string Pass) 		-> server check
//	string ServerLogin(string User, string Pass) 		-> login
//	void ServerLogout() 								-> logout
// 	bool PlayitemCheck(const string &in)				-> check playitem
//	array<dictionary> PlayitemParse(const string &in)	-> parse playitem
// 	bool PlaylistCheck(const string &in)				-> check playlist
//	array<dictionary> PlaylistParse(const string &in)	-> parse playlist

string GetTitle() {
	return "Twitch";
}

string GetVersion() {
	return "1.2";
}

string GetDesc() {
	return "https://twitch.tv/";
}

class QualityListItem {
	string url;
	string quality;
	string qualityDetail;
	string resolution;
	string bitrate;
	string format;
	int itag = 0;
	double fps = 0.0;
	int type3D = 0; // 1:sbs, 2:t&b
	bool is360 = false;

	dictionary toDictionary() {
		dictionary ret;
		
		ret["url"] = url;
		ret["quality"] = quality;
		ret["qualityDetail"] = qualityDetail;
		ret["resolution"] = resolution;
		ret["bitrate"] = bitrate;
		ret["format"] = format;
		ret["itag"] = itag;
		ret["fps"] = fps;
		ret["type3D"] = type3D;
		ret["is360"] = is360;
		return ret;
	}	
};

class Config {
	string fullConfig;
	string clientID;
	string oauthToken;
	bool showBitrate = false;
	bool showFPS = true;

	bool isTrue(string option) {
		return (HostRegExpParse(fullConfig, option + "=([0-1])") == "1");
	}

	string setClientID() {
		string c = HostRegExpParse(fullConfig, "clientID=([-a-zA-Z0-9_]+)");
		if (c == "") {
			c = "1dviqtp3q3aq68tyvj116mezs3zfdml";
		}
		return c;
	}
};

string audioOnlyRaw = "audio_only";
string audioOnlyRawVod = "Audio Only";
string audioOnlyGood = "— Audio Only";

Config ReadConfigFile() {
	Config config;
	config.fullConfig = HostFileRead(HostFileOpen("Extention\\Media\\PlayParse\\config.ini"), 500);
	config.showBitrate = config.isTrue("showBitrate");
	config.showFPS = config.isTrue("showFPS");
	config.clientID = config.setClientID();
	config.oauthToken = HostRegExpParse(config.fullConfig, "oauthToken=oauth:([-a-zA-Z0-9_]+)");
	return config;
}

int GetITag(const string &in qualityName) {
	array<string> qualities = {audioOnlyGood, "160p", "360p", "480p", "720p", "720p60", "1080p", "1080p60"};
	qualities.reverse();
	if (qualityName.find("(source)") > 0) {
		return 1;
	}
	int indexQuality = qualities.find(qualityName);
	if (indexQuality > 0) {
		return indexQuality + 2;
	} else {
		return -1;
	}
}

bool PlayitemCheck(const string &in path) {
	return HostRegExpParse(path, "twitch.tv/([-a-zA-Z0-9_]+)") != "";
}

string ClipsParse(const string &in path, dictionary &MetaData, array<dictionary> &QualityList, const string &in headerClientId) {
	string clipId = HostRegExpParse(path, "clips.twitch.tv/([-a-zA-Z0-9_]+)");
	// If ID from old url type is empty, find ID from new url type.
	if (clipId.length() == 0) {
		clipId = HostRegExpParse(path, "/clip/([-a-zA-Z0-9_]+)");
	}
	string clipApi = "https://clips.twitch.tv/api/v2/clips/" + clipId + "/status";
	string clipStatusApi = "https://api.twitch.tv/helix/clips?id=" + clipId;

	string jsonClip = HostUrlGetString(clipApi, "", "");
	string jsonStatusClip = HostUrlGetString(clipStatusApi, "", headerClientId);

	HostPrintUTF8(jsonStatusClip);
	JsonReader ClipReader;
	JsonValue ClipRoot;

	string srcBestUrl = "";
	if (ClipReader.parse(jsonClip, ClipRoot) && ClipRoot.isObject()) {
		JsonValue qualityArray;
		if (ClipRoot["quality_options"].isArray()) {
			qualityArray = ClipRoot["quality_options"];
		} else {
			return "";
		}

		srcBestUrl = qualityArray[0]["source"].asString();

		if (@QualityList !is null) {
			for (int k = 0; k < qualityArray.size(); k++) {
				string currentQualityUrl = qualityArray[k]["source"].asString();
				string qualityName = qualityArray[k]["quality"].asString() + "p";

				QualityListItem qualityItem;
				qualityItem.itag = k;
				qualityItem.quality = qualityName;
				qualityItem.qualityDetail = qualityName;
				qualityItem.url = currentQualityUrl;
				QualityList.insertLast(qualityItem.toDictionary());
			}
		}
	}

	string titleClip;
	string displayName;
	string views;
	string createdAt;
	JsonReader StatusClipReader;
	JsonValue StatusClipRoot;
	if (StatusClipReader.parse(jsonStatusClip, StatusClipRoot) && StatusClipRoot.isObject()) {
		JsonValue item = StatusClipRoot["data"][0];
		titleClip = item["title"].asString();
		views = "Views: " + item["view_count"].asString();
		createdAt = HostRegExpParse(item["created_at"].asString(), "([0-9-]+)T");
		displayName = item["broadcaster_name"].asString();
	}

	MetaData["title"] = titleClip;
	MetaData["content"] = titleClip + " | " + displayName + " | " + views + " | " + createdAt;

	return srcBestUrl;
}

string PlayitemParse(const string &in path, dictionary &MetaData, array<dictionary> &QualityList) {
	// HostOpenConsole();
	Config ConfigData = ReadConfigFile();

	// Any twitch API demands client id in header.
	string headerClientId = "Client-ID: " + ConfigData.clientID;

	bool isVod = path.find("twitch.tv/videos/") > 0;
	if (path.find("clips.twitch.tv") >= 0 ||
		HostRegExpParse(path, "/clip/([-a-zA-Z0-9_]+)").length() > 0) {
		return ClipsParse(path, MetaData, QualityList, headerClientId);
	}

	string nickname = HostRegExpParse(path, "twitch.tv/([-a-zA-Z0-9_]+)");
	nickname.MakeLower();

	string vodId = "";
	if (isVod) {
		vodId = HostRegExpParse(path, "twitch.tv/videos/([0-9]+)");
	}
	HostPrintUTF8(vodId);
// 	https://usher.ttvnw.net/vod/
//  https://api.twitch.tv/api/vods/

	// Firstly we need to request for api to get pretty weirdly token and sig.
	string tokenApi = "https://api.twitch.tv/api/channels/" + nickname + "/access_token?need_https=true";
	if (isVod) {
		string oauth = ConfigData.oauthToken;
		oauth.replace("oauth:", "");
		if (oauth.length() > 0) {
			oauth = "&oauth_token=" + oauth;
		}
		tokenApi = "https://api.twitch.tv/api/vods/" + vodId + "/access_token?need_https=true" + oauth;
	}
	// Parameter p should be random number.
	string m3u8Api = (isVod
		? "https://usher.ttvnw.net/vod/" + vodId
		: "https://usher.ttvnw.net/api/channel/hls/" + nickname)
	+ ".m3u8?allow_source=true&p=7278365player_backend=mediaplayer&playlist_include_framerate=true&allow_audio_only=true";
	// &sig={token_sig}&token={token}
	string jsonToken = HostUrlGetString(tokenApi, "", headerClientId);

	// Get information of current stream.
	// string idChannel = HostRegExpParse(jsonToken, ":([0-9]+)");
	string jsonChannelStatus = HostUrlGetString(
		"https://api.twitch.tv/helix/" + (!isVod
			? "streams?user_login=" + nickname
			: "videos?id=" + vodId),
		"",
		headerClientId);
	string titleStream;
	string displayName;
	string views = "";
	JsonReader StatusChannelReader;
	JsonValue StatusChannelRoot;
	if (StatusChannelReader.parse(jsonChannelStatus, StatusChannelRoot) && StatusChannelRoot.isObject()) {
		JsonValue item = StatusChannelRoot["data"][0];
		titleStream = item["title"].asString();
		displayName = item["user_name"].asString();
		views = item[isVod ? "view_count" : "viewer_count"].asString();
	}

	// Read weird token and sig.
	string sig;
	string token;
	JsonReader TokenReader;
	JsonValue TokenRoot;
	if (TokenReader.parse(jsonToken, TokenRoot) && TokenRoot.isObject()) {
		sig = "&sig=" + TokenRoot["sig"].asString();
		token = "&token=" + TokenRoot["token"].asString();
	}

	// Second request to get list of *.m3u8 urls.
	string jsonM3u8 = HostUrlGetString(m3u8Api + sig + token, "", headerClientId);
	jsonM3u8.replace('"', "");

	string m3 = ".m3u8";

	string sourceQualityUrl = "https://" + HostRegExpParse(jsonM3u8, "https://([a-zA-Z-_.0-9/]+)" + m3) + m3;

	if (@QualityList !is null) {
		array<string> arrayOfM3u8 = jsonM3u8.split("#EXT-X-MEDIA:");
		for (int k = 1, len = arrayOfM3u8.size(); k < len; k++) {
			string currentM3u8 = arrayOfM3u8[k];
			string currentQuality = HostRegExpParse(currentM3u8, "NAME=([a-zA-Z-_.0-9/ ()]+)");
			string currentResolution = HostRegExpParse(currentM3u8, "RESOLUTION=([a-zA-Z-_.0-9/ ()]+)");
			string currentFPS = HostRegExpParse(currentM3u8, "FRAME-RATE=([a-zA-Z-_.0-9/ ()]+)");
			string currentBitrate = HostRegExpParse(currentM3u8, "BANDWIDTH=([a-zA-Z-_.0-9/ ()]+)");
			string currentQualityUrl = "https://" + HostRegExpParse(currentM3u8, "https://([a-zA-Z-_.0-9/]+)" + m3) + m3;

			// Dash allows us to move an "audio_only" element to the end.
			currentQuality.replace(audioOnlyRawVod, audioOnlyGood);
			currentQuality.replace(audioOnlyRaw, audioOnlyGood);

			QualityListItem qualityItem;
			qualityItem.itag = GetITag(currentQuality);
			qualityItem.quality = currentQuality;
			qualityItem.fps = ConfigData.showFPS ? parseFloat(currentFPS) : 0.0;
			qualityItem.bitrate = parseInt(currentBitrate) / 1000 + "k";
			qualityItem.resolution = currentResolution;
			qualityItem.qualityDetail = currentQuality;
			if (ConfigData.showBitrate) {
				qualityItem.qualityDetail += ", bitrate " + qualityItem.bitrate;
			}
			qualityItem.url = currentQualityUrl;
			QualityList.insertLast(qualityItem.toDictionary());
		}
	}


	MetaData["title"] = titleStream;
	MetaData["content"] = "— " + titleStream;
	MetaData["viewCount"] = views;
	MetaData["author"] = displayName;
	return sourceQualityUrl;
}