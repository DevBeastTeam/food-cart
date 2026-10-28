<?php
require_once __DIR__ . '/../php-backend/config/database.php';
$pdo = getDb();

$tables = ["settings", "content", "categories", "restaurants", "food_items", "daig_items", "banners", "deals", "orders", "users"];

$sql = "-- =============================================================================\n";
$sql .= "-- FoodCourt & Pakwan — External SQLite3 Dummy Seed Dataset\n";
$sql .= "-- Location: Root / External (Can be modified outside without altering PHP code)\n";
$sql .= "-- Generated: " . date("Y-m-d H:i:s") . "\n";
$sql .= "-- =============================================================================\n\n";

$jsonData = [];

foreach ($tables as $table) {
    $rows = $pdo->query("SELECT * FROM \"$table\"")->fetchAll(PDO::FETCH_ASSOC);
    $jsonData[$table] = $rows;

    $sql .= "-- -----------------------------------------------------------------------------\n";
    $sql .= "-- Table: $table (" . count($rows) . " records)\n";
    $sql .= "-- -----------------------------------------------------------------------------\n";
    if (empty($rows)) {
        $sql .= "\n";
        continue;
    }

    $cols = array_keys($rows[0]);
    $colsStr = implode(", ", array_map(function($c) { return '"' . $c . '"'; }, $cols));

    foreach ($rows as $row) {
        $vals = [];
        foreach ($cols as $col) {
            $val = $row[$col];
            if ($val === null) {
                $vals[] = 'NULL';
            } elseif (is_numeric($val) && !preg_match('/^0[0-9]+/', (string)$val)) {
                $vals[] = $val;
            } else {
                $vals[] = "'" . str_replace("'", "''", (string)$val) . "'";
            }
        }
        $valsStr = implode(', ', $vals);
        $sql .= "INSERT OR REPLACE INTO \"$table\" ($colsStr) VALUES ($valsStr);\n";
    }
    $sql .= "\n";
}

file_put_contents(__DIR__ . '/../php-backend/seed_data.sql', $sql);
file_put_contents(__DIR__ . '/../seed_data.sql', $sql);

$jsonFormatted = json_encode($jsonData, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);
file_put_contents(__DIR__ . '/../php-backend/seed_data.json', $jsonFormatted);
file_put_contents(__DIR__ . '/../seed_data.json', $jsonFormatted);

echo "Successfully exported seed_data.sql (" . strlen($sql) . " bytes)\n";
echo "Successfully exported seed_data.json (" . strlen($jsonFormatted) . " bytes)\n";
