### PHP LDAP Admin Panel - Detect (phpldapadmin-panel) found on phpldapadmin

----
**Details**: **phpldapadmin-panel** matched at phpldapadmin

**Protocol**: HTTP

**Full URL**: http://phpldapadmin:80

**Timestamp**: Thu Oct 15 05:25:29 +0000 UTC 2026

**Template Information**

| Key | Value |
| --- | --- |
| Name | PHP LDAP Admin Panel - Detect |
| Authors | ritikchaddha, dhiyaneshdk |
| Tags | php, phpldapadmin, panel, detect, discovery |
| Severity | info |
| CVSS-Score | 0.00 |
| vendor | phpldapadmin_project |
| product | phpldapadmin |
| shodan-query | title:"phpLDAPadmin" |

**Request**
```http
GET / HTTP/1.1
Host: phpldapadmin
User-Agent: Mozilla/5.0 (Windows NT 10.0: Win64: x64: rv:140.0) Gecko/20100101 Firefox/140.0
Accept: */*
Accept-Language: en
Accept-Encoding: gzip


```

**Response**
```http
HTTP/1.1 200 OK
Cache-Control: private
Content-Type: text/html; charset="UTF-8"
Date: Thu, 15 Oct 2026 05:25:29 GMT
Expires: Thu, 19 Nov 1981 08:52:00 GMT
Pragma: no-cache
Server: Apache
Set-Cookie: ***
Vary: Accept-Encoding,User-Agent
X-Content-Type-Options: nosniff
X-Frame-Options: SAMEORIGIN
X-Xss-Protection: 1; mode=block

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="auto">

<head><meta http-equiv="Content-Type" content="text/html; charset=utf-8" /><title>phpLDAPadmin (1.2.5) - </title><link rel="shortcut icon" href="images/favicon.ico" type="image/vnd.microsoft.icon" /><link type="text/css" rel="stylesheet" href="css/default/style.css" /><link type="text/css" rel="stylesheet" media="all" href="js/jscalendar/calendar-blue.css" title="blue" />
<script type="text/javascript" src="js/ajax_functions.js"></script><script type="text/javascript" src="js/jscalendar/calendar.js"></script>
</head>
<body>
<table class="page" border="0" width="100%"><tr class="pagehead"><td colspan="3"><div id="ajHEAD"><table width="100%" border="0"><tr><td style="text-align: left;"><a href="" onclick="target='_blank';"><img src="images/default/logo-small.png" alt="Logo" class="logo" /></a></td><td class="imagetop"><a href="https://stackoverflow.com/questions/tagged/phpldapadmin" title="Forum" onclick="target='_blank';"><img src="images/default/forum-big.png" alt="Forum" /></a> <a href="https://github.com/leenooks/phpLDAPadmin/issues" title="Request feature" onclick="target='_blank';"><img src="images/default/request-feature-big.png" alt="Request feature" /></a> <a href="https://github.com/leenooks/phpLDAPadmin/issues" title="Report a bug" onclick="target='_blank';"><img src="images/default/bug-big.png" alt="Report a bug" /></a> <a href="https://sourceforge.net/donate/index.php?group_id=61828" title="Donate" onclick="target='_blank';"><img src="images/default/smile-big.png" alt="Donate" /></a> <a href="http://phpldapadmin.sourceforge.net/Documentation" title="Help" onclick="target='_blank';"><img src="images/default/help-big.png" alt="Help" /></a></td></tr></table></div></td></tr>
<tr class="control"><td colspan="3"><div id="ajCONTROL"><table class="control" width="100%" border="0"><tr><td><a href="index.php" title="Home">Home</a> | <a href="cmd.php?cmd=purge_cache" onclick="return ajDISPLAY('BODY','cmd=purge_cache','Clearing cache');" title="Purge caches">Purge caches</a></td></tr></table></div></td></tr>
<tr><td class="tree" colspan="2"><acronym title="Hide/Unhide the tree"><img src="images/default/plus.png" alt="" style="float: right;" onclick="if (document.getElementById('ajTREE').style.display == 'none') { document.getElementById('ajTREE').style.display = 'block' } else { document.getElementById('ajTREE').style.display = 'none' };"/></acronym><div id="ajTREE"><div id="ajSID_1" style="display: block"><table class="tree" border="0"><tr class="server"><td class="icon"><img src="images/default/server.png" alt="Server" /></td><td class="name" colspan="2">openldap</td></tr><tr class="option"><td class="spacer"></td><td class="icon"><a href="cmd.php?cmd=login_form&amp;server_id=1" onclick="return ajDISPLAY('BODY','cmd=login_form&amp;server_id=1','Loading Login');" title="Login to openldap"><img src="images/default/login.png" alt="login" /></a></td><td class="logged_in" colspan="1"><a href="cmd.php?cmd=login_form&amp;server_id=1" onclick="return ajDISPLAY('BODY','cmd=login_form&amp;server_id=1','Loading Login');" title="Login to openldap">login</a></td></tr><tr><td class="blank" colspan="3">&nbsp;</td></tr><tr><td class="blank" colspan="3">&nbsp;</td></tr></table>

<script type="text/javascript" src="js/layersmenu-browser_detection.js"></script><script type="text/javascript" src="js/ajax_tree.js"></script></div>

</div></td><td class="body" style="width: 80%;"><div id="ajBODY">
<table class="body"><tr><td><div style="text-align: center;"><br /><br /><img src="images/default/logo.png" title="phpLDAPadmin logo" alt="phpLDAPadmin logo" /><br /><br />Use the menu to the left to navigate<br /><br /><a href="http://phpldapadmin.sourceforge.net/Credits" onclick="target='_blank';">Credits</a> | <a href="http://phpldapadmin.sourceforge.net/Documentation" onclick="target='_blank';">Documentation</a> | <a href="https://sourceforge.net/donate/index.php?group_id=61828" onclick="target='_blank';">Donate</a><br /><br /></div></td></tr></table></div></td></tr>
<tr class="foot"><td><small>&nbsp;</small></td><td colspan="2"><div id="ajFOOT">1.2.5</div>&nbsp;</td></tr></table></body></html>
```

**Extra Information**

**Extracted results:**

- 1.2.5



**CURL command**
```sh
curl -X 'GET' -d '' -H 'Accept: */*' -H 'Accept-Language: en' -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0: Win64: x64: rv:140.0) Gecko/20100101 Firefox/140.0' 'http://phpldapadmin:80'
```

----

Generated by [Nuclei v3.11.1](https://github.com/projectdiscovery/nuclei)