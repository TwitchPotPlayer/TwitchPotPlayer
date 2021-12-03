/*
	This is the source code of Twitch media parse extension.
	Copyright github.com/23rd, 2018-2020.
*/

//  bool OpenConsole()									-> if debug is true, HostOpenConsole()
//	string GetTitle() 									-> get title for UI
//	string GetVersion									-> get version for manage
//	string GetDesc()									-> get detail information
//	string ConvertBooleanToString(bool value)			-> convert a boolean to either "true" or "false"
//	string GetLoginTitle()								-> get title for login dialog
//	string GetLoginDesc()								-> get desc for login dialog
//	string ServerCheck(string User, string Pass) 		-> server check
//	string ServerLogin(string User, string Pass) 		-> login
//	void ServerLogout() 								-> logout
// 	bool PlayitemCheck(const string &in)				-> check playitem
//	array<dictionary> PlayitemParse(const string &in)	-> parse playitem
// 	bool PlaylistCheck(const string &in)				-> check playlist
//	array<dictionary> PlaylistParse(const string &in)	-> parse playlist

bool debug = false; /// open console to view debug output
bool showSensitiveInfo = false; /// Output info containing your tokens and secrets
bool verbose = false;

/// END OF USER VARIABLES

bool OpenConsole() {
	if (debug) HostOpenConsole();
	return debug;
}

string GetTitle() {
	return "Twitch";
}

string GetVersion() {
	return "1.4.0";
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

string ConvertBooleanToString(bool value) {
	return value ? "true" : "false";
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
	bool useOwnCredentials = false;

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
	string path = "Extension\\Media\\PlayParse\\config.ini";
	config.fullConfig = HostFileRead(HostFileOpen(path), 500);
	config.showBitrate = config.isTrue("showBitrate");
	config.showFPS = config.isTrue("showFPS");
	config.gameInTitle = config.isTrue("gameInTitle");
	config.gameInContent = config.isTrue("gameInContent");
	config.clientID = config.parse("clientID=");
	config.clientSecret = config.parse("clientSecret=");
	config.oauthToken = config.parse("oauthToken=oauth:");
	config.useOwnCredentials = config.isTrue("useOwnCredentials");
	// This ClientID is used only for getting the m3u8 playlist.
	config.clientID_M3U8 = "jzkbprff40iqj646a697cyrvl0zt2m6";

	if (config.clientID != "" && config.useOwnCredentials == true)
	{
		config.clientID_M3U8 = config.clientID;
	}

	return config;
}

string GetAppAccessToken() {
	HostPrintUTF8("#### <GetAppAccessToken> ####");
	string debug_msg = "";
	/// TODO: string value = "";

	if (!ConfigData.useOwnCredentials) {
		ConfigData.clientID = "g5zg0400k4vhrx2g6xi4hgveruamlv";

		debug_msg = ""
		+ "## useOwnCredentials is False. Default to and return value of default clientId starting with 65zg0400.\n" // todo: truncate value of clientID
		+ "#### </GetAppAccessToken> ####";
		HostPrintUTF8(debug_msg);

		return "6jftlp4naa4e7esxe3favcmjfno2qw";
	}

	if (ConfigData.clientID == "" || ConfigData.clientSecret == "") {
		debug_msg = ""
		+ "## clientID or clientSecret are null. Return null value.\n"
		+ "#### </GetAppAccessToken> ####";
		HostPrintUTF8(debug_msg);

		return "";
	}

	string uri = "https://id.twitch.tv/oauth2/token";
	string postData = '{"grant_type":"client_credentials",';
	postData += '"client_id":"' + ConfigData.clientID + '",';
	postData += '"client_secret":"' + ConfigData.clientSecret + '"}';

	HostPrintUTF8("Getting Authorization token...");
	string json = HostUrlGetString(
		uri,
		"",
		"Content-Type: application/json",
		postData);

	/// DEBUG OUTPUT
	string debug_postData = postData;
	string debug_json = json;
	if (!showSensitiveInfo) {
		debug_postData.replace(ConfigData.clientID, "(hidden)");
		debug_postData.replace(ConfigData.clientSecret, "(hidden)");
		debug_json = "(hidden)"; /// json value is parsed later
	}
	debug_msg = ""
	+ "## uri: " + uri + "\n"
	+ "## postData:\n" + debug_postData + "\n"
	+ "## json: " + debug_json + "\n";
	HostPrintUTF8(debug_msg);


	if (json == "")
	{
		debug_msg = "## Authorization Error. No response from " + uri;
		HostPrintUTF8(debug_msg);
		// throw new Exception(debug_msg);
		// catch exception and show in message box.
		// Somehow shove the message into the "pins" that PotPlayer suggests investigating.
	}

	JsonReader twitchJsonReader;
	JsonValue twitchValueRoot;
	bool twitchJsonIsValid = twitchJsonReader.parse(json, twitchValueRoot);
	bool twitchValueRootIsObject = twitchValueRoot.isObject();
	debug_msg = ""
	+ "## twitchJsonIsValid: " + ConvertBooleanToString(twitchJsonIsValid) + "\n"
	+ "## twitchValueRootIsObject: " + ConvertBooleanToString(twitchValueRootIsObject) + "\n";

	if (twitchJsonIsValid && twitchValueRootIsObject) {
		string access_token = twitchValueRoot["access_token"].asString();
		string debug_access_token = access_token;
		if (!showSensitiveInfo) debug_access_token = "(hidden)";
		debug_msg += "## access_token: " + debug_access_token + "\n";
		HostPrintUTF8(debug_msg + "#### </GetAppAccessToken> ####");
		return access_token;
	}

	HostPrintUTF8(debug_msg + "#### </GetAppAccessToken> ####");
	return "";
}

string DebugConfig() {
	string debug_msg = "#### <DebugConfig> ####\n";

	/// DEBUG OUTPUT
	string debug_clientID = (showSensitiveInfo) ? ConfigData.clientID : "(hidden)";
	string debug_clientID_M3U8 = (showSensitiveInfo) ? ConfigData.clientID_M3U8 : "(hidden)";
	string debug_clientSecret = (showSensitiveInfo) ? ConfigData.clientSecret : "(hidden)";
	string debug_oauthToken = (showSensitiveInfo) ? ConfigData.oauthToken : "(hidden)";
	string debug_auth = (showSensitiveInfo) ? Authorization : "(hidden)";

	if (verbose && showSensitiveInfo) {
		debug_msg += ""
		+ "## ConfigData.fullConfig:\n"
		+ ConfigData.fullConfig + '\n';
	}

	debug_msg += ""
	+ "## ConfigData.clientID         : " + debug_clientID + '\n'
	+ "## ConfigData.clientID_M3U8    : " + debug_clientID_M3U8 + '\n'
	+ "## ConfigData.clientSecret     : " + debug_clientSecret + '\n'
	+ "## ConfigData.oauthToken       : " + debug_oauthToken + '\n'
	+ "## ConfigData.showBitrate      : " + ConfigData.showBitrate + '\n'
	+ "## ConfigData.showFPS          : " + ConfigData.showFPS + '\n'
	+ "## ConfigData.gameInTitle      : " + ConfigData.gameInTitle + '\n'
	+ "## ConfigData.gameInContent    : " + ConfigData.gameInContent + '\n'
	+ "## ConfigData.useOwnCredentials: " + ConfigData.useOwnCredentials + '\n'
	+ "## Authorization: " + debug_auth + "\n"
	+ "## IsTwitch: " + IsTwitch + "\n"
	+ "#### </DebugConfig> ####";

	HostPrintUTF8(debug_msg);

	return debug_msg;
}

bool ConsoleOpened = OpenConsole();

Config ConfigData = ReadConfigFile();
string Authorization = GetAppAccessToken();
bool IsTwitch = (Authorization != "");
string ApiBase = getApiBase();

string _debugConfig = DebugConfig();

JsonValue ParseJsonFromRequest(string json) {
	HostPrintUTF8 ("#### <ParseJsonFromRequest> ####");
	JsonReader twitchJsonReader;
	JsonValue twitchValueRoot;
	if (twitchJsonReader.parse(json, twitchValueRoot) && twitchValueRoot.isObject()) {
		if (twitchValueRoot["data"].isArray()) {
			/// DEBUG OUTPUT
			string debug_msg = ""
			+ "## isArray: " + twitchValueRoot["data"].isArray() + "\n"
			+ "## size: " + twitchValueRoot["data"].getKeys().size() + "\n";
			HostPrintUTF8(debug_msg + "#### </ParseJsonFromRequest> ####");

			return twitchValueRoot["data"];
		}
	}
	HostPrintUTF8("#### </ParseJsonFromRequest> ####");
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

	/// DEBUG OUTPUT
	string debug_helix = helix;
	if (!showSensitiveInfo) debug_helix.replace(Authorization, "(hidden)");
	string debug_header = "Client-ID: " + ConfigData.clientID + v5 + debug_helix;
	if (!showSensitiveInfo) debug_header.replace(ConfigData.clientID, "(hidden)");
	string debug_json = json; /// TODO: check for sensitive info
	string debug_msg = ""
	+ "#### <SendTwitchAPIRequest> ####\n"
	+ "## request: " + request + "\n"
	+ "## v5: (next line)" + v5 + "\n"
	+ "## helix: (next line)" + debug_helix + "\n"
	+ "## header: (next line)\n" + debug_header + "\n"
	+ "## json: " + debug_json + "\n"
	+ "#### </SendTwitchAPIRequest> ####";
	HostPrintUTF8(debug_msg);

	return ParseJsonFromRequest(json);
}

JsonValue SendGraphQLRequest(string request) {
	string headers = "";
	headers += "Client-ID: " + ConfigData.clientID_M3U8;
	headers += "\nContent-Type: application/json";

	string oauth = ConfigData.oauthToken;
	if (oauth.length() > 0) {
		oauth.replace("oauth:", "");
		headers += "\nAuthorization: OAuth " + oauth;
	}

	string json = HostUrlGetString(
		"https://gql.twitch.tv/gql",
		"",
		headers,
		request);

	/// DEBUG OUTPUT
	string debug_oauth = oauth;
	string debug_headers = headers;
	string debug_json = json; /// TODO: check for sensitive info
	if (!showSensitiveInfo) {
		debug_oauth = "(hidden)";
		debug_headers.replace(ConfigData.clientID_M3U8, "(hidden)");
		debug_headers.replace(oauth, "(hidden)");
	}
	string debug_msg = ""
	+ "#### <SendGraphQLRequest> ####" + "\n"
	+ "## request:\n" + request + "\n"
	+ "## oauth: " + debug_oauth + "\n"
	+ "## header:\n" + debug_headers + "\n"
	+ "## json: " + debug_json + "\n"
	+ "#### </SendGraphQLRequest ####";
	HostPrintUTF8(debug_msg);

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

string PlaybackTokenBodyRequest(string function, string firstParameter) {
	string s = "";
	s += '{';
	s += '    "query": "{';
	s += '        ' + function + '(';
	s += '                ' + firstParameter + ',';
	s += '                params: {';
	s += '                    platform: \\"web\\",';
	s += '                    playerBackend: \\"mediaplayer\\",';
	s += '                    playerType: \\"site\\"';
	s += '                }) {';
	s += '            value';
	s += '            signature';
	s += '        }';
	s += '    }"';
	s += '}';

	/// DEBUG OUTPUT
	string debug_msg = ""
	+ "#### <PlaybackTokenBodyRequest> ####\n"
	+ "## s:\n" + s + "\n"
	+ "#### </PlaybackTokenBodyRequest> ####";
	HostPrintUTF8(debug_msg);


	return s;
}

JsonValue LiveTokenRequest(string nickname) {
	string function = "streamPlaybackAccessToken";
	HostPrintUTF8("#### <LiveTokenRequest> ####");
	JsonValue value = SendGraphQLRequest(PlaybackTokenBodyRequest(
		function,
		'channelName: \\"' + nickname + '\\"'))[function];
	HostPrintUTF8("#### </LiveTokenRequest> ####");
	return value;
}

JsonValue VodTokenRequest(string vodId) {
	string function = "videoPlaybackAccessToken";
	HostPrintUTF8("#### <VodTokenRequest> ####");
	JsonValue value = SendGraphQLRequest(PlaybackTokenBodyRequest(
		function,
		'id: \\"' + vodId + '\\"'))[function];
	HostPrintUTF8("#### </VodTokenRequest> ####");
	return value;
}

string GetGameFromId(string id) {
	string debug_msg = ""
	+ "#### <GetGameFromId> ####\n"
	+ "Getting game data...";
	HostPrintUTF8(debug_msg);
	JsonValue game = SendTwitchAPIRequest(ApiBase + "/helix/games?id=" + id);
	string value = "";
	bool gameIsArray = game.isArray();

	if (gameIsArray) {
		value = " | " + game[0]["name"].asString();
	}

	/// DEBUG OUTPUT
	debug_msg = ""
	+ "## gameIsArray: " + ConvertBooleanToString(gameIsArray) + "\n"
	+ "#### </GetGameFromId> ####";
	HostPrintUTF8(debug_msg);
	return value;
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
	HostPrintUTF8("#### <PlayItemCheck> ####");
	bool value = HostRegExpParse(path, "twitch.tv/" + getReg()) != "";
	string debug_msg = ""
	+ "## value: " + ConvertBooleanToString(value) + "\n"
	+ "#### </PlayItemCheck> ####";
	HostPrintUTF8(debug_msg);
	return value;
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
	HostPrintUTF8("#### <PlayItemParse> ####");
	string value = "";
	string debug_msg = "";

	// Any twitch API demands client id in header.
	string headerClientId = "Client-ID: " + ConfigData.clientID_M3U8;
	string debug_headerClientId = headerClientId;
	if (!showSensitiveInfo) debug_headerClientId.replace(ConfigData.clientID_M3U8, "(hidden)");

	bool isVod = path.find("twitch.tv/videos/") > 0;
	bool pathContainsClipsSubdomain = path.find("clips.twitch.tv") >= 0;
	bool pathContainsClipSubdirectory = HostRegExpParse(path, "/clip/" + getReg()).length() > 0;
	bool isClip = (pathContainsClipsSubdomain || pathContainsClipSubdirectory);
	if (isClip) {
		/// DEBUG OUTPUT
		debug_msg = ""
		+ "## headerClientId: " + debug_headerClientId + "\n"
		+ "## isVod: " + ConvertBooleanToString(isVod);
		HostPrintUTF8(debug_msg);

		value = ClipsParse(path, MetaData, QualityList, headerClientId);

		HostPrintUTF8("#### </PlayItemParse> ####");
		return value;
	}

	string nickname = HostRegExpParse(path, "twitch.tv/" + getReg());
	nickname.MakeLower();

	string vodId = "";
	if (isVod) {
		vodId = HostRegExpParse(path, "twitch.tv/videos/([0-9]+)");
	}

	// 	https://usher.ttvnw.net/vod/
	//  https://api.twitch.tv/api/vods/
	// Parameter p should be random number.
	string m3u8Api = (isVod
		? "https://usher.ttvnw.net/vod/" + vodId
		: "https://usher.ttvnw.net/api/channel/hls/" + nickname)
	+ ".m3u8?"
	+ "allow_source=true&"
	+ "p=7278465&"
	+ "player_backend=mediaplayer&"
	+ "playlist_include_framerate=true&"
	+ "allow_audio_only=true&"
	+ "reassignments_supported=true&"
	+ "supported_codecs=avc1";
	// &sig={token_sig}&token={token}

	/// DEBUG OUTPUT
	debug_msg = ""
	+ "## headerClientId: " + debug_headerClientId + "\n"
	+ "## isVod: " + ConvertBooleanToString(isVod) + "\n"
	+ "## m3u8Api: " + m3u8Api + "\n"
	+ "## ApiBase: " + ApiBase + "\n"
	+ "## nickname: " + nickname + "\n"
	+ "## vodId: " + vodId + "\n"
	+ "## urlSuffix: " + (!isVod ? "/helix/streams?user_login=" + nickname : "/kraken/videos/v" + vodId) + "\n"
	+ "## Getting stream information via SendTwitchAPIRequest...";
	HostPrintUTF8(debug_msg);

	// Get information of current stream.
	// string idChannel = HostRegExpParse(jsonToken, ":([0-9]+)");
	JsonValue stream = SendTwitchAPIRequest(ApiBase + (!isVod
		? "/helix/streams?user_login=" + nickname
		: "/kraken/videos/v" + vodId));
		// Helix API can't give to us game_id from video_id.
		//: "videos?id=" + vodId));
	bool streamIsArray = stream.isArray();
	bool streamIsLegacyVod = ( !stream.isArray() && stream.isObject());
	string titleStream;
	string displayName;
	string views = "";
	string gameId;
	string game;
	if (streamIsArray) {
		JsonValue item = stream[0];
		titleStream = item["title"].asString();
		displayName = item["user_name"].asString();
		gameId = item["game_id"].asString();
		views = item[isVod ? "view_count" : "viewer_count"].asString();
	} else if (streamIsLegacyVod) { // This is legacy VOD.
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

	/// DEBUG OUTPUT
	debug_msg = ""
	+ "## streamIsArray: " + ConvertBooleanToString(streamIsArray) + "\n"
	+ "## streamIsLegacyVod: " + ConvertBooleanToString(streamIsLegacyVod) + "\n"
	+ "## stream: " + stream.asString() + "\n"
	+ "## titleStream: " + titleStream + "\n"
	+ "## displayName: " + displayName + "\n"
	+ "## views: " + views + "\n"
	+ "## gameId: " + gameId + "\n"
	+ "## game: " + game + "\n"
	+ "## Geting stream token...";
	HostPrintUTF8(debug_msg);

	// Firstly we need to request for api to get pretty weirdly token and sig.
	JsonValue weirdToken = isVod
		? VodTokenRequest(vodId)
		: LiveTokenRequest(nickname);

	string sig = "&sig=" + weirdToken["signature"].asString();
	string token = "&token=" + HostUrlEncode(weirdToken["value"].asString());

	/// DEBUG OUTPUT
	debug_msg = ""
	+ "## tokenRequestResponse: " + weirdToken.asString() + "\n"
	+ "## tokenType: " + (isVod ? "VodToken" : "LiveToken") + "\n"
	+ "## sig: " + sig + "\n"
	+ "## token: " + token + "\n"
	+ "## Getting list of M3U8 URLs...";
	HostPrintUTF8(debug_msg);

	// Second request to get list of *.m3u8 urls.
	string jsonM3u8 = HostUrlGetString(m3u8Api + sig + token, "", headerClientId);
	jsonM3u8.replace('"', "");

	string m3 = ".m3u8";
	string sourceQualityUrl = "https://" + HostRegExpParse(jsonM3u8, "https://([a-zA-Z-_.0-9/]+)" + m3) + m3;
	array<string> arrayOfM3u8 = {"list is empty"};

	/// TODO: verbose output of array
	if (@QualityList !is null) {
		arrayOfM3u8 = jsonM3u8.split("#EXT-X-MEDIA:");
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

	/// DEBUG OUTPUT
	debug_msg = ""
	+ "## jsonM3u8: " + jsonM3u8 + "\n"
	+ "## sourceQualityUrl: " + sourceQualityUrl + "\n"
	/// If not null, then false; If null, then true.
	+ "## QualityListIsNull: " + ((@QualityList !is null) ? "false" : "true") + "\n"
	/// Need DictionaryToString
	//+ "## MetaData[\"title\"]: " + MetaData["title"].asString() + "\n"
	//+ "## MetaData[\"content\"]: " + MetaData["content"] + "\n"
	//+ "## MetaData[\"viewCount\"]: " + MetaData["viewCount"] + "\n"
	//+ "## MetaData[\"author\"]: " + MetaData["author"] + "\n"
	+ "## Returning string 'sourceQualityUrl'...";
	HostPrintUTF8(debug_msg);

	HostPrintUTF8("#### </PlayItemParse> ####");
	return sourceQualityUrl;
}
