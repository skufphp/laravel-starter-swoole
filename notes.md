## **Node.js** — ближайший аналог

Swoole по архитектуре ближе всего к **Node.js**, но с элементами **Go**.

## Сравнение архитектур

| Концепция | Swoole (PHP) | Node.js | Go |
|-----------|--------------|---------|-----|
| Event Loop | ✅ Да | ✅ Да | ❌ Нет (goroutines) |
| Асинхронный I/O | ✅ Да | ✅ Да | ✅ Да |
| Корутины | ✅ Coroutines | ❌ Callbacks/Promises | ✅ Goroutines |
| Резидентная память | ✅ Да | ✅ Да | ✅ Да |
| Многопоточность | ✅ Worker processes | ❌ Single-threaded | ✅ Native threads |

## Что изучать и в каком порядке

### 1. **Node.js** — для понимания базовых концепций (70% сходства)

- Event Loop и неблокирующий I/O
- Резидентное приложение (сервер не умирает после запроса)
- Утечки памяти и их диагностика
- Проблемы с глобальным состоянием

```javascript
// Node.js — сервер живёт постоянно
const http = require('http');
let counter = 0; // ⚠️ Состояние между запросами!

http.createServer((req, res) => {
    counter++;
    res.end(`Request #${counter}`);
}).listen(3000);
```


```php
// Swoole — та же идея
$server = new Swoole\Http\Server('0.0.0.0', 9501);
$counter = 0; // ⚠️ Состояние между запросами!

$server->on('request', function ($request, $response) use (&$counter) {
    $counter++;
    $response->end("Request #{$counter}");
});
$server->start();
```


### 2. **Go** — для понимания корутин (30% сходства)

Swoole Coroutines очень похожи на goroutines:

```textmate
// Go — goroutines
go func() {
    result := fetchFromDB() // блокирует только эту goroutine
    fmt.Println(result)
}()
```


```php
// Swoole — coroutines
go(function () {
    $result = $db->query('SELECT ...'); // блокирует только эту корутину
    echo $result;
});
```


## Ключевые концепции, которые нужно усвоить

### 1. **Резидентная память** (от Node.js)
```php
// ❌ ОПАСНО — утечка памяти
class SomeService {
    private array $cache = [];
    
    public function process($data) {
        $this->cache[] = $data; // Растёт бесконечно!
    }
}

// ✅ Правильно — очистка или ограничение
public function process($data) {
    if (count($this->cache) > 1000) {
        $this->cache = array_slice($this->cache, -500);
    }
    $this->cache[] = $data;
}
```


### 2. **Изоляция состояния запросов** (от Node.js)
```php
// ❌ ОПАСНО — данные пользователя A попадут к пользователю B
$currentUser = null;

$server->on('request', function ($req, $res) use (&$currentUser) {
    $currentUser = User::find($req->get['user_id']);
    // ... async операция ...
    $res->end($currentUser->name); // Может быть уже другой пользователь!
});

// ✅ Правильно — Context или Coroutine::getContext()
$server->on('request', function ($req, $res) {
    $context = Coroutine::getContext();
    $context['user'] = User::find($req->get['user_id']);
    // ... async операция ...
    $res->end($context['user']->name);
});
```


### 3. **Конкурентность без параллелизма** (от Node.js + Go)
```php
// Параллельные запросы в одном процессе
$wg = new Swoole\Coroutine\WaitGroup();

$results = [];

$wg->add();
go(function () use ($wg, &$results) {
    $results['users'] = Http::get('/api/users');
    $wg->done();
});

$wg->add();
go(function () use ($wg, &$results) {
    $results['orders'] = Http::get('/api/orders');
    $wg->done();
});

$wg->wait(); // Оба запроса выполнились параллельно
```


## Рекомендуемый план обучения

| Этап | Что изучать | Ресурс |
|------|-------------|--------|
| 1 | Event Loop в Node.js | [Node.js Event Loop](https://nodejs.org/en/learn/asynchronous-work/event-loop-timers-and-nexttick) |
| 2 | Async/Await в Node.js | Любой курс по Node.js |
| 3 | Goroutines в Go | [Go by Example: Goroutines](https://gobyexample.com/goroutines) |
| 4 | Channels в Go | [Go by Example: Channels](https://gobyexample.com/channels) |
| 5 | Swoole Coroutines | [Официальная документация Swoole](https://wiki.swoole.com/) |

## Главные «ловушки» при переходе с классического PHP

1. **Singleton = зло** — он будет жить между запросами
2. **Статические переменные = зло** — то же самое
3. **Глобальные переменные = зло** — данные «протекут» между пользователями
4. **`exit()` / `die()` = убьёт воркер**, а не просто запрос

---

**Итог:** Начните с Node.js курса (event loop, async/await, memory leaks), затем посмотрите базу Go (goroutines, channels). После этого Swoole станет интуитивно понятным.