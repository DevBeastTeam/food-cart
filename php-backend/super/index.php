<?php
// Backward compatibility: redirect /super/ to /admin/
header('Location: /admin/', true, 301);
exit;
