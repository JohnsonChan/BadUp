<?php
class Database {
    private static $instance = null;
    private $pdo;

    private function __construct() {
        $host = "hdm33422916.my3w.com";
        $dbname = "badup";
        $user = "hdm33422916";
        $pass = "1991wsdrE45";

        try {
            $this->pdo = new PDO(
                "mysql:host=$host;dbname=$dbname;charset=utf8",
                $user,
                $pass,
                [
                    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                    PDO::ATTR_PERSISTENT => true
                ]
            );
        } catch (PDOException $e) {
            die("DataBase connect fail: " . $e->getMessage());
        }
    }

    public static function getPdoInstance() {
        if (self::$instance === null) {
            self::$instance = new Database();
        }
        return self::$instance->pdo;
    }

    public static function getInstance() {
        if (self::$instance === null) {
            self::$instance = new Database();
        }
        return self::$instance;
    }
}
?>
