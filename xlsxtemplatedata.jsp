<%@ page contentType="text/html;charset=UTF-8" buffer="none" import="psdi.util.*,java.io.*,java.util.*,psdi.webclient.system.controller.*,psdi.webclient.system.session.*,psdi.webclient.system.runtime.*,psdi.webclient.system.beans.*,psdi.mbo.*,psdi.server.*, com.google.gson.*" %>
<%
	BufferedReader br = request.getReader();
	String json = "";
	for (String line; (line = br.readLine()) != null; json += line);

	JsonParser parser = new JsonParser();
	JsonElement element = parser.parse(json);
	String mboName = null;
	String whereClause = null;
	JsonArray placeholders = null;
	
	if (element.isJsonObject()) {
		JsonObject root = element.getAsJsonObject();
		mboName = root.get("mbo").getAsString();
		whereClause = root.get("where").getAsString();	
		placeholders = root.getAsJsonArray("placeholders");
	}
	
	JsonObject dataJson = new JsonObject();
	
	if (mboName != null && whereClause != null) {
		MXSession mxSession = WebClientRuntime.getMXSession(session);
		MboSetRemote dataMboSet = MXServer.getMXServer().getMboSet(mboName, mxSession.getUserInfo());
		dataMboSet.setWhere(whereClause);
		dataMboSet.reset();
		
		if (dataMboSet.count() == 1) {
			MboRemote mainMbo = dataMboSet.moveFirst();
			
			for (int i = 0; i < placeholders.size(); i++) {
				String placeholder = placeholders.get(i).getAsString();
				String data = "";
				
				try {
					data = mainMbo.getString(placeholder);
				} catch (Exception e) {
					dataJson.addProperty("errMessage", e.getMessage());
				}
				
				dataJson.addProperty(placeholder, data);
			}
		}
		
		dataMboSet.close();
	}
%>
<%=dataJson.toString()%>