<?php

// Swoole must not treat a client's Swoole-Upload-File part header as an upload and
// unlink the path it names (swoole/swoole-src#6309, fixed in v6.2.5).
$target = '/tmp/target';
touch($target);
$status = 0;

$server = new Swoole\Http\Server('127.0.0.1', 9501);
$server->set(['worker_num' => 1, 'log_level' => SWOOLE_LOG_ERROR]);
$server->on('request', fn ($request, $response) => $response->end());
$server->on('start', function ($server) use ($target, &$status) {
    go(function () use ($server, $target, &$status) {
        $body = "--b\r\nContent-Disposition: form-data; name=\"file\"; filename=\"f.bin\"\r\n"
            . "Swoole-Upload-File: {$target}\r\nContent-Type: application/octet-stream\r\n\r\nabc\r\n--b--\r\n";
        $client = new Swoole\Coroutine\Http\Client('127.0.0.1', 9501);
        $client->setHeaders(['Content-Type' => 'multipart/form-data; boundary=b']);
        $client->post('/', $body);
        Swoole\Coroutine::sleep(0.5);
        $status = $client->statusCode;
        $server->shutdown();
    });
});
$server->start();

$kept = file_exists($target);
echo "status {$status}, target ", $kept ? 'kept' : 'deleted', PHP_EOL;
exit($status === 200 && $kept ? 0 : 1);
