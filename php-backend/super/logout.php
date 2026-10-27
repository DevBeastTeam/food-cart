<?php
// Backward compatibility: redirect /super/logout.php to /admin/logout.php
header('Location: /admin/logout.php', true, 301);
exit;
