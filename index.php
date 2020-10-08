<?php
echo nl2br("\r\nWelcome\r\nThis is Temp  HTML document\r\n", false);
$server_ip = gethostbyname($_SERVER['SERVER_ADDR']);
echo nl2br("Below is your server IP.\r\n", false);
echo nl2br($server_ip);
$exip = file_get_contents('/opt/ipwatch/oldip.txt', true);
$vpnip = file_get_contents('/var/www/html/vpn', FALSE, NULL, 1, 22);
/* get disk space free (in bytes) */
$df = disk_free_space("/drive/1");
$df2 = disk_free_space("/drive/2");
/* and get disk space total (in bytes)  */
$dt = disk_total_space("/drive/1");
$dt2 = disk_total_space("/drive/2");
/* now we calculate the disk space used (in bytes) */
$du = $dt - $df;
$du2 = $dt2 - $df2;
/* percentage of disk used - this will be used to also set the width % of the progress bar */
$dp = sprintf('%.2f',($du / $dt) * 100);
$dp2 = sprintf('%.2f',($du2 / $dt2) * 100);
/* and we formate the size from bytes to MB, GB, etc. */
$df = formatSize($df);
$du = formatSize($du);
$dt = formatSize($dt);
$df2 = formatSize($df2);
$du2 = formatSize($du2);
$dt2 = formatSize($dt2);
function formatSize( $bytes )
{
        $types = array( 'B', 'KB', 'MB', 'GB', 'TB' );
        for( $i = 0; $bytes >= 1024 && $i < ( count( $types ) -1 ); $bytes /= 1024, $i++ );
                return( round( $bytes, 2 ) . " " . $types[$i] );
}
?>
<br>
Internal Links<br>
<html lang="en">
    <head>
        <meta charset="UTF-8">
        <title>Your Server Link Page</title>
        <meta name="description" contents="Just a start page">
        <link rel="stylesheet" href="css/style.css" type="text/css">
    </head>
    <body bgcolor="#E6E6FA">
        <header>
            <nav id="main-navigation">
                <ul>
                    <li><a href="index.php">Home</a></li>
                    <li><a href="http://<?php echo $server_ip; ?>:32400/web" target="_blank">Plex</a></li>
                    <li><a href="http://<?php echo $server_ip; ?>:8989" target="_blank">Sonarr</a></li>
                    <li><a href="http://<?php echo $server_ip; ?>:7878" target="_blank">Radarr</a></li>
                    <li><a href="http://<?php echo $server_ip; ?>:9117" target="_blank">Jackett</a></li>
                    <li><a href="http://<?php echo $server_ip; ?>:9091" target="_blank">Transmission</a></li>
                    <li><a href="http://<?php echo $server_ip; ?>:5000" target="_blank">YouTubeDL</a></li>
                    </ul>
            </nav>
        </header>
External Links if outside your home network<br>
Your current "ip" <?php echo $exip; ?><br>
Below is vpn  ip (Note shouldn't match external IP or vpn is down !)<br>
VPN <?php echo $vpnip; ?>

<header>
            <nav id="ext-navigation">
                  <ul>
                    <li><a href="index.php">Home</a></li>
                    <li><a href="http://<?php echo $exip; ?>:8000" target="_blank">CloudCmd</a></li>
                    <li><a href="http://<?php echo $exip; ?>:32400/web" target="_blank">Plex</a></li>
                    <li><a href="http://<?php echo $exip; ?>:8989" target="_blank">Sonarr</a></li>
                    <li><a href="http://<?php echo $exip; ?>:7878" target="_blank">Radarr</a></li>
                    <li><a href="http://<?php echo $exip; ?>:9117" target="_blank">Jackett</a></li>
                    <li><a href="http://<?php echo $exip; ?>/transmission" target="_blank">Transmission</a></li>
                    <li><a href="http://<?php echo $exip; ?>:5000" target="_blank">YouTubeDL</a></li>
                    </ul>
            </nav>
        </header>

       <div id="main-contents"><br>
           <br>
            This is a Helper index page<br><br>

            It is here to retrieve info about your server  and allow you <br>
            to start setting up all the media server options. Leaving it <br>
            here is a risk.<br>
<br>

        </div>
        <footer>
             Do your research to setup the apps as required. <br>
          Note: this server doesn't mount any other drives after install and must be configure
by you!!
<style type='text/css'>

.progress {
        border: 2px solid #5E96E4;
        height: 32px;
        width: 540px;
        margin: 30px auto;
}
.progress .prgbar {
        background: #A7C6FF;
        width: <?php echo $dp; ?>%;
        position: relative;
        height: 32px;
        z-index: 999;
}
.progress .prgtext {
        color: #286692;
        text-align: center;
        font-size: 13px;
        padding: 9px 0 0;
        width: 540px;
        position: absolute;
        z-index: 1000;
}
.progress .prginfo {
        margin: 3px 0;
}

</style>
</style>
<div class='progress'>
        <div class='prgtext'><?php echo $dp; ?>% Disk Used On Storage Drive 1  Movies & TV </div>
        <div class='prgbar'></div>
        <div class='prginfo'>
                <span style='float: left;'><?php echo "$du of $dt used"; ?></span>
                <span style='float: right;'><?php echo "$df of $dt free"; ?></span>
                <span style='clear: both;'></span>
        </div>
</div>
<style type='text/css'>

.progress {
        border: 2px solid #5E96E4;
        height: 32px;
        width: 540px;
        margin: 30px auto;
}
.progress .prgbar {
        background: #A7C6FF;
        width: <?php echo $dp2; ?>%;
        position: relative;
        height: 32px;
        z-index: 999;
}
.progress .prgtext {
        color: #286692;
        text-align: center;
        font-size: 13px;
        padding: 9px 0 0;
        width: 540px;
        position: absolute;
        z-index: 1000;
}
.progress .prginfo {
        margin: 3px 0;
}

</style>
</style>
<div class='progress'>
        <div class='prgtext'><?php echo $dp2; ?>% Disk Used On Storage Drive 2 Temp Downloads</div>
        <div class='prgbar'></div>
        <div class='prginfo'>
                <span style='float: left;'><?php echo "$du2 of $dt2 used"; ?></span>
                <span style='float: right;'><?php echo "$df2 of $dt2 free"; ?></span>
                <span style='clear: both;'></span>
        </div>
</div>
  </footer>
    </body>
</html>
