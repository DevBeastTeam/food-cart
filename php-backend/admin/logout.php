<?php
// php-backend/super/logout.php
session_start();
unset($_SESSION['super_admin']);
header('Location: login.php');
exit;
