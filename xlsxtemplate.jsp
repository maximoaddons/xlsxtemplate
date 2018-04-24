<%@ page contentType="text/html;charset=UTF-8" buffer="none" import="org.w3c.dom.*,psdi.util.*,java.util.*,psdi.webclient.system.controller.*,psdi.webclient.system.session.*,psdi.webclient.system.runtime.*,psdi.webclient.system.beans.*,psdi.mbo.*" %>
<%
	WebClientSession wcs = WebClientRuntime.getWebClientRuntime().getWebClientSession(request);
	String servletBase = wcs.getMaximoRequestContextURL();
	AppInstance app = wcs.getCurrentApp();
	DataBean appBean = app.getAppBean();
	MboRemote mainMbo = appBean.getMbo();
	MboSetRemote mainMboSet = mainMbo.getThisMboSet();
	String mainMboName = mainMbo.getName();
	String whereClause = mainMboSet.getQbeWhere();
	String controlId = request.getParameter("controlId");
	
	if (controlId != null) {
		controlId = HTML.securitySafeWithHTMLEncoding(controlId);
	}
	
	ControlInstance xlsxTemplateControl = wcs.getControlInstance(controlId);
	String pageId = xlsxTemplateControl.getPage().getId();
%>
<!-- inject:html -->
<!DOCTYPE html>
<html>
	<head>
		<meta http-equiv="X-UA-Compatible" content="IE=EDGE"/>
		<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
		<meta http-equiv="Cache-control" content="no-cache, no-store, must-revalidate">
		<meta http-equiv="Pragma" content="no-cache">
		<meta http-equiv="Expires" content="-1">
		<!-- inject:css -->
		<link rel="stylesheet" href="<%=servletBase%>/webclient/utility/css/xlsxtemplate.min.css">
		<!-- endinject -->
		<!-- inject:js -->
		<script src="<%=servletBase%>/webclient/utility/js/xlsxtemplate.min.js"></script>
		<!-- endinject -->
	</head>
	<body>
		<div class="empty">
			<div class="card">
				<div class="card-header">
					<div class="card-title h5">Report form</div>
					<div class="card-subtitle text-gray">Upload XLSX template</div>
				</div>
				<div class="card-body">
					<input class="form-input" id="xlsx-input" type="file">
				</div>
				<div class="card-footer">
					<div class="btn-group btn-group-block">
						<button class="btn btn-primary" id="generate-report-btn">Generate</button>
						<button class="btn" id="cancel-btn">Cancel</button>
					</div>
				</div>
			</div>
		</div>
		<div id="hidden-data" style="display:none;">
			<div id="servletBase"><%=servletBase%></div>
			<div id="mainMboName"><%=mainMboName%></div>
			<div id="whereClause"><%=whereClause%></div>
		</div>
		<script type="text/javascript">
			function getInnerHTML(id) {
				return document.getElementById(id).innerHTML;
			}
			
			function getHiddenData() {
				return {
					baseUrl: getInnerHTML('servletBase'),
					mainMboName: getInnerHTML('mainMboName'),
					mainMboSetWhere: getInnerHTML('whereClause')
				};
			}
			
			function requestData(placeholders, cb) {
				var hiddenData = getHiddenData();
				var xhr = new XMLHttpRequest();
				var url = hiddenData.baseUrl + '/webclient/utility/xlsxtemplatedata.jsp';
				xhr.open('POST', url, true);
				xhr.setRequestHeader('Content-type', 'application/json');
				xhr.onreadystatechange = function() {
					var responseText = null;
					
					if (xhr.readyState === 4 && xhr.status === 200) {
						responseText = xhr.responseText;
					}

					if (responseText.indexOf('errMessage') != -1) {
						var parsedJson = JSON.parse(responseText);
						alert('Error occured while fetching data: \n\n' + parsedJson.errMessage);
					} else {
						cb(responseText);
					}
				};
				var data = JSON.stringify({
					mbo: hiddenData.mainMboName, 
					where: hiddenData.mainMboSetWhere,
					placeholders: placeholders
				});
				xhr.send(data);
			}
			
			function getPlaceholders(cb) {
				var file = document.querySelector('input[type=file]').files[0];
				var processor = new XLSXProcessor();
				processor.readFile(file, function(workbook) {
					var placeholders = null;
					
					if (workbook != null) {
						placeholders = processor.getPlaceholders(workbook);
					}
					
					cb(workbook, placeholders);
				});
			}
			
			document.getElementById('generate-report-btn').onclick = function() {
				getPlaceholders(function(workbook, placeholders) {
					requestData(placeholders, function(responseText) {
						var timestamp = (new Date).getTime();
						var processor = new XLSXProcessor();
						var replacedWorkbook = processor.replacePlaceholders(workbook, responseText);
						processor.saveFile(replacedWorkbook, 'report_' + timestamp + '.xlsx');
					});
				});
			}
			
			document.getElementById('cancel-btn').onclick = function() {
				parent.sendEvent("dialogok", "<%=pageId%>", "");
			}
		</script>
	</body>
</html>
<!-- endinject -->