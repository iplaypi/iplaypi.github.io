<?php
// 生产环境 web 目录
$target = '/site/iplaypi.github.io';
// 密钥,验证 GitHub 的请求
$secret = "test666";
// 获取 GitHub 发送的内容,解析
$json = file_get_contents('php://input');
$content = json_decode($json, true);
// GitHub发送过来的签名,一定要大写,虽然http请求里面是驼峰法命名的
$signature = $_SERVER['HTTP_X_HUB_SIGNATURE'];
if (!$signature) {
   return http_response_code(404);
}
// 使用等号分割,得到算法和签名
list($algo, $hash) = explode('=', $signature, 2);
// 在本机计算签名
$payloadHash = hash_hmac($algo, $json, $secret);
// 获取分支名字
$branch = $content['ref'];
// 日志内容
$logMessage = '[' . $content['head_commit']['committer']['name'] . ']在[' . date('Y-m-d H:i:s') . ']向项目[' . $content['repository']['name'] . ']的分支[' . $content['ref'] . ']push了[' . count($content['commits']) . ']个commit' . PHP_EOL;
$logMessage .= 'ret:[' . $content['ref'] . '],payloadHash:[' . $payloadHash . ']' . PHP_EOL;
// 判断签名是否匹配,分支是否匹配
if ($hash === $payloadHash && 'refs/heads/master' === $branch) {
    // 增加执行脚本日志重定向输出到文件
    $cmd = "cd $target && git pull";
    $res = shell_exec($cmd);
    $res_log = 'Success:' . PHP_EOL;
    $res_log .= $logMessage;
    $res_log .= $res . PHP_EOL;
    $res_log .= '======================================================================='.PHP_EOL;
    echo $res_log;
} else {
    $res_log  = 'Error:' . PHP_EOL;
    $res_log .= $logMessage;
    $res_log .= '密钥不正确或者分支不是master,不能pull' . PHP_EOL;
    $res_log .= '======================================================================='.PHP_EOL;
    echo $res_log;
}
?>