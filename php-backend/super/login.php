<?php
// Backward compatibility: redirect /super/login.php to /admin/login.php
header('Location: /admin/login.php', true, 301);
exit;
