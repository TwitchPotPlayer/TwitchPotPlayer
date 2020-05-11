/*
	This is the source code of Twitch media parse extension.
	Copyright github.com/23rd, 2018-2020.
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
	return "1.4";
}

string GetDesc() {
	return "https://twitch.tv/";
}

string getReg() {
	return "([-a-zA-Z0-9_]+)";
}

string getApiBase() {
	if (!IsTwitch) {
		return "https://potplayer.herokuapp.com";
	}
	return "https://api.twitch.tv";
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
	string clientID_M3U8;
	string clientSecret;
	string oauthToken;
	bool showBitrate = false;
	bool showFPS = true;
	bool gameInTitle = false;
	bool gameInContent = true;

	bool isTrue(string option) {
		return (HostRegExpParse(fullConfig, option + "=([0-1])") == "1");
	}

	string parse(string s) {
		return HostRegExpParse(fullConfig, s + getReg());
	}

};

string audioOnlyRaw = "audio_only";
string audioOnlyRawVod = "Audio Only";
string audioOnlyGood = "— Audio Only";

Config ReadConfigFile() {
	Config config;
	config.fullConfig = HostFileRead(HostFileOpen("Extension\\Media\\PlayParse\\config.ini"), 500);
	config.showBitrate = config.isTrue("showBitrate");
	config.showFPS = config.isTrue("showFPS");
	config.gameInTitle = config.isTrue("gameInTitle");
	config.gameInContent = config.isTrue("gameInContent");
	config.clientID = config.parse("clientID=");
	config.clientSecret = config.parse("clientSecret=");
	config.oauthToken = config.parse("oauthToken=oauth:");
	// This ClientID is used only for getting the m3u8 playlist.
	config.clientID_M3U8 = "jzkbprff40iqj646a697cyrvl0zt2m6";
	return config;
}

string GetAppAccessToken() {
	if (ConfigData.clientID == "" || ConfigData.clientSecret == "") {
		return "";
	}
	string postData = '{"grant_type":"client_credentials",';
	postData += '"client_id":"' + ConfigData.clientID + '",';
	postData += '"client_secret":"' + ConfigData.clientSecret + '"}';

	string json = HostUrlGetString(
		"https://id.twitch.tv/oauth2/token",
		"",
		"Content-Type: application/json",
		postData);

	JsonReader twitchJsonReader;
	JsonValue twitchValueRoot;

	if (twitchJsonReader.parse(json, twitchValueRoot) &&
		twitchValueRoot.isObject()) {
		return twitchValueRoot["access_token"].asString();
	}
	return "";
}

Config ConfigData = ReadConfigFile();
string Authorization = GetAppAccessToken();
bool IsTwitch = (Authorization != "");
string ApiBase = getApiBase();

JsonValue ParseJsonFromRequest(string json) {
	JsonReader twitchJsonReader;
	JsonValue twitchValueRoot;

	if (twitchJsonReader.parse(json, twitchValueRoot) && twitchValueRoot.isObject()) {
		if (twitchValueRoot["data"].isArray()) {
			return twitchValueRoot["data"];
		}
	}
	return twitchValueRoot;
}

JsonValue SendTwitchAPIRequest(string request) {
	string v5 = (request.find("kraken") > 0) ? "\naccept: application/vnd.twitchtv.v5+json" : "";
	string helix = (request.find("helix") > 0) ? "\nAuthorization: Bearer " + Authorization : "";
	string header = "Client-ID: " + ConfigData.clientID + v5 + helix;
	if (!IsTwitch) {
		header = "";
	}
	string json = HostUrlGetString(request, "", header);
	return ParseJsonFromRequest(json);
}

JsonValue SendGraphQLRequest(string request) {
	string json = HostUrlGetString(
		"https://gql.twitch.tv/gql",
		"",
		"Client-ID: " + ConfigData.clientID + "\nContent-Type: application/json",
		request);
	HostPrintUTF8("JSON");
	HostPrintUTF8(json);
	return ParseJsonFromRequest(json)["data"];
}

string ClipsBodyRequest(string clipId) {
	// Multiline strings are not allowed in this application.
	string s = "";
	s += '{"query": "{';
	s += '  clip(slug: \\"' + clipId + '\\") {';
	s += '    broadcaster {';
	s += '      displayName';
	s += '    }';
	s += '    createdAt';
	s += '    curator {';
	s += '      displayName';
	// s += '      id';
	s += '    }';
	// s += '    durationSeconds';
	// s += '    id';
	s += '    game {';
	s += '      name';
	// s += '      id';
	s += '    }';
	// s += '    tiny: thumbnailURL(width: 86, height: 45)';
	// s += '    small: thumbnailURL(width: 260, height: 147)';
	// s += '    medium: thumbnailURL(width: 480, height: 272)';
	s += '    title';
	s += '    viewCount';
	s += '    videoQualities {';
	s += '      frameRate';
	s += '      quality';
	s += '      sourceURL';
	s += '    }';
	s += '  }';
	s += '}"}';
	return s;
}

string GetGameFromId(string id) {
	JsonValue game = SendTwitchAPIRequest(ApiBase + "/helix/games?id=" + id);
	if (game.isArray()) {
		return " | " + game[0]["name"].asString();
	}
	return "";
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
	return HostRegExpParse(path, "twitch.tv/" + getReg()) != "";
}

string ClipsParse(const string &in path, dictionary &MetaData, array<dictionary> &QualityList, const string &in headerClientId) {
	string clipId = HostRegExpParse(path, "clips.twitch.tv/" + getReg());
	// If ID from old url type is empty, find ID from new url type.
	if (clipId.length() == 0) {
		clipId = HostRegExpParse(path, "/clip/" + getReg());
	}

	JsonValue clipRoot = SendGraphQLRequest(ClipsBodyRequest(clipId))["clip"];
	string srcBestUrl = "";
	if (!clipRoot.isObject()) {
		return "";
	}

	JsonValue qualityArray;
	if (clipRoot["videoQualities"].isArray()) {
		qualityArray = clipRoot["videoQualities"];
	} else {
		return "";
	}

	srcBestUrl = qualityArray[0]["sourceURL"].asString();

	if (@QualityList !is null) {
		for (int k = 0; k < qualityArray.size(); k++) {
			string currentQualityUrl = qualityArray[k]["sourceURL"].asString();
			string qualityName = qualityArray[k]["quality"].asString() + "p";

			QualityListItem qualityItem;
			qualityItem.itag = k;
			qualityItem.quality = qualityName;
			qualityItem.qualityDetail = qualityName;
			qualityItem.url = currentQualityUrl;
			qualityItem.fps = qualityArray[k]["frameRate"].asDouble();
			QualityList.insertLast(qualityItem.toDictionary());
		}
	}

	string titleClip = clipRoot["title"].asString();
	string displayName = clipRoot["broadcaster"]["displayName"].asString();
	string creatorName = clipRoot["curator"]["displayName"].asString();
	string views = "Views: " + clipRoot["viewCount"].asString();
	string game = clipRoot["game"]["name"].asString();
	string createdAt = clipRoot["createdAt"].asString();
	createdAt.replace("T", " ");
	createdAt.replace("Z", " ");

	MetaData["title"] = titleClip;
	MetaData["content"] = titleClip + " | " + game + " | " + displayName + " | " + createdAt;
	MetaData["viewCount"] = views;
	MetaData["author"] = creatorName;

	return srcBestUrl;
}

string PlayitemParse(const string &in path, dictionary &MetaData, array<dictionary> &QualityList) {
	// HostOpenConsole();

	// Any twitch API demands client id in header.
	string headerClientId = "Client-ID: " + ConfigData.clientID_M3U8;

	bool isVod = path.find("twitch.tv/videos/") > 0;
	if (path.find("clips.twitch.tv") >= 0 ||
		HostRegExpParse(path, "/clip/" + getReg()).length() > 0) {
		return ClipsParse(path, MetaData, QualityList, headerClientId);
	}

	string nickname = HostRegExpParse(path, "twitch.tv/" + getReg());
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
	JsonValue stream = SendTwitchAPIRequest(ApiBase + (!isVod
		? "/helix/streams?user_login=" + nickname
		: "/kraken/videos/v" + vodId));
		// Helix API can't give to us game_id from video_id.
		//: "videos?id=" + vodId));
	string titleStream;
	string displayName;
	string views = "";
	string gameId;
	string game;
	if (stream.isArray()) {
		JsonValue item = stream[0];
		titleStream = item["title"].asString();
		displayName = item["user_name"].asString();
		gameId = item["game_id"].asString();
		HostPrintUTF8(gameId);
		views = item[isVod ? "view_count" : "viewer_count"].asString();
	} else if (stream.isObject()) { // This is legacy VOD.
		titleStream = stream["title"].asString();
		views = stream["views"].asString();
		displayName = stream["channel"]["display_name"].asString();
		game = " | " + stream["game"].asString();
	}
	if (ConfigData.gameInTitle || ConfigData.gameInContent) {
		if (game == "") {
			game = GetGameFromId(gameId);
		}
	}

	// Read weird token and sig.
	string sig;
	string token;
	JsonReader TokenReader;
	JsonValue TokenRoot;
	if (TokenReader.parse(jsonToken, TokenRoot) && TokenRoot.isObject()) {
		sig = "&sig=" + TokenRoot["sig"].asString();
		token = "&token=" + HostUrlEncode(TokenRoot["token"].asString());
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


	MetaData["title"] = titleStream + (ConfigData.gameInTitle ? game : "");
	MetaData["content"] = "— " + titleStream + (ConfigData.gameInContent ? game : "");
	MetaData["viewCount"] = views;
	MetaData["author"] = displayName;
	return sourceQualityUrl;
}