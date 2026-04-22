<?php
// 数据库连接封装。
// 服务器 PHP 版本是 5.5，代码保持 PDO + 短数组写法，不使用新版本 PHP 特性。
class Database {
    private static $instance = null;
    private $pdo;

    private function __construct() {
        // 数据库配置集中放在这里；部署到其它服务器时只改这一组配置。
        $host = "hdm33422916.my3w.com";
        $dbname = "hdm33422916_db";
        $user = "hdm33422916";
        $pass = "1991wsdrE45";

        try {
            // 使用异常模式，接口层 catch 后统一返回 JSON 错误。
            $this->pdo = new PDO(
                "mysql:host=$host;dbname=$dbname;charset=utf8",
                $user,
                $pass,
                [
                    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC
                ]
            );
        } catch (PDOException $e) {
            die("DataBase connect fail: " . $e->getMessage());
        }
    }

    // 返回 PDO 实例，供接口文件执行 prepare/execute。
    public static function getPdoInstance() {
        if (self::$instance === null) {
            self::$instance = new Database();
        }
        return self::$instance->pdo;
    }

    // 保留完整 Database 单例，后续如果要扩展其它方法可以使用。
    public static function getInstance() {
        if (self::$instance === null) {
            self::$instance = new Database();
        }
        return self::$instance;
    }
}
?>
