Ниже приведены основные моменты, на которые стоит обратить внимание при настройке проксирования GeoServer (и смежных сервисов) через Nginx, а также набор рекомендаций для упрощения конфигурации и избежания дальнейших сложностей.

1. Анализ возможных причин конфликтов
1.1 Дублирующиеся/конкурирующие правила
В разных фрагментах конфигурации могут встречаться похожие, но немного отличающиеся блоки location. Например:

location /geoserver-vector и location /geoserver-vector/
Ручные переадресации (rewrite, proxy_redirect) и блоки proxy_cookie_path / proxy_cookie_domain, которые делают фактически одно и то же, но по-разному.
Чрезмерное количество правил переписывания (rewrite) и редиректов (proxy_redirect) усложняет логику. Если в одном блоке написано rewrite ^/geoserver-vector$ /geoserver-vector/ permanent;, а в другом proxy_pass http://.../geoserver/;, могут возникать циклические редиректы или некорректные пути к ресурсам (например, двойные слэши).

Рекомендация:
Стараться объединять логику в единый блок location /geoserver-vector/, вместо написания нескольких похожих блоков. Так проще контролировать, как идут запросы. Аналогично для geoserver-ecw/ и geonetwork/.

1.2 Некорректная работа с cookie и путями
GeoServer (и аналогичные Java-сервисы) могут устанавливать куки с путями типа /geoserver или доменами вроде corporate-gis-geoserver-vector-1. При проксировании эти пути или домены нужно корректно переписывать.

Директива proxy_cookie_path /geoserver /geoserver-vector; заменяет путь внутри Set-Cookie (например, Path=/geoserver; -> Path=/geoserver-vector;),
А proxy_cookie_domain original_domain new_domain; переписывает домен в куках.
Если в разных блоках location указываются противоречивые proxy_cookie_path / proxy_cookie_domain, может получиться, что часть запросов идёт по старым путям.

Рекомендация:
В каждом проксируемом блоке использовать одинаковую логику cookie, чтобы не было расхождений. Для упрощения лучше везде явно указывать:

nginx
Копировать
proxy_cookie_path /geoserver /geoserver-vector;
proxy_cookie_domain corporate-gis-geoserver-vector-1 $host;
Либо, если сервис внутри Docker-сети у вас называется geoserver_vector, тогда:

nginx
Копировать
proxy_cookie_domain geoserver_vector $host;
1.3 Смешение rewrite, proxy_redirect и return
Часто достаточно либо использовать rewrite, либо proxy_redirect, либо return, а не всё вместе. Когда все эти директивы комбинируются, увеличивается шанс “зациклить” запрос.

rewrite ^/something$ /something/ permanent; даёт 301-редирект на /something/
proxy_redirect меняет заголовки Location: и Refresh: в ответах сервера.
Если внутри одного блока задействовать и rewrite, и proxy_redirect, то можно легко получить двойное перенаправление.

Рекомендация:

Для простых случаев (добавить завершающий слэш) можно использовать try_files или отдельный location = /endpoint.
Стараться сводить к минимуму количество rewrite.
Если нужно вернуть код 301 с добавлением слэша, делать это в отдельном месте:
nginx
Копировать
location = /geoserver-vector {
    return 301 /geoserver-vector/;
}
location /geoserver-vector/ {
    proxy_pass ...
    ...
}
Для корректировки путей в ответах сервера (HTTP-заголовки Location:) использовать proxy_redirect.
2. Рекомендации по упрощению конфигурации
Ниже общий пример логики для GeoServer Vector, который можно переиспользовать и для GeoServer ECW, изменив лишь имена upstream и пути.

2.1 Использовать upstream и единый блок location
Допустим, у нас есть upstream:

nginx
Копировать
upstream geoserver_vector {
    server corporate-gis-geoserver-vector-1:8080;
}
Теперь единый блок:

nginx
Копировать
location /geoserver-vector/ {
    # Указываем внутренний адрес, куда проксируем
    proxy_pass http://geoserver_vector/geoserver/;

    # Переписываем домен в Set-Cookie, если требуется
    proxy_cookie_domain corporate-gis-geoserver-vector-1 $host;
    # Переписываем путь в Set-Cookie (Path=/geoserver -> Path=/geoserver-vector)
    proxy_cookie_path /geoserver /geoserver-vector;

    # Меняем Location: http://geoserver_vector/geoserver -> /geoserver-vector
    # С точки зрения URL, если GeoServer возвращает Location: http://geoserver_vector/geoserver/
    proxy_redirect http://geoserver_vector/geoserver/ /geoserver-vector/;

    # Общие заголовки
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
}
Важно: добавлять завершающий слэш в location /geoserver-vector/ { ... }, чтобы запрос /geoserver-vector/web/ корректно проксировался далее.

2.2 Чёткий return 301 для пути без слэша
Чтобы не плодить несколько rewrite, можно сделать так:

nginx
Копировать
location = /geoserver-vector {
    return 301 /geoserver-vector/;
}
А всё остальное проксируется через /geoserver-vector/.

2.3 Убрать лишние промежуточные блоки
Если необходимо проксировать авторизацию j_spring_security_check или WMS/WFS/OWS, и это всё уходит в тот же контекст /geoserver-vector/, не всегда нужно делать отдельные location блоки. Можно проксировать всё единообразно через /geoserver-vector/. GeoServer внутри сам разрулит пути /wms, /wfs и т.д.

Если хотите отделить логику (например, особые заголовки для авторизации), то можно оставить отдельные location, но проследить, чтобы они не конфликтовали с основным:

nginx
Копировать
location /geoserver-vector/j_spring_security_check {
   proxy_pass http://geoserver_vector/geoserver/j_spring_security_check;
   ...
}
И так же указать cookie/domain/path-редиректы.

3. Правила, которых стоит придерживаться
Единая стратегия пути
Решите, как будет выглядеть конечный URL. Например:

/geoserver-vector/ → внутренний /geoserver/
/geoserver-ecw/ → внутренний /geoserver/
/geonetwork/ → внутренний /geonetwork/
Минимизация rewrite
Использовать rewrite только там, где действительно нужно (например, добавление завершающего / на чистый /geoserver-vector). Всё остальное делать через proxy_redirect и proxy_cookie_*.

Одинаковая логика cookie
Если есть много подобных сервисов (GeoServer Vector, ECW и т.д.), старайтесь для каждого копировать шаблон, меняя только название upstream и префикса. Так снизится риск “не дописали” или “переименовали не везде”.

Локальная проверка

Запустите nginx -t перед перезапуском, чтобы проверить синтаксис.
Включите debug-логирование на этапе отладки, но после отладки снизьте уровень, чтобы не захламлять логи.
Проверяйте curl -I http://localhost/geoserver-vector/ и смотрите Location: заголовки при редиректах.
Версионирование конфигурации

Храните конфиги Nginx в Git (или другом VCS), помечайте каждый коммит.
Перед внесением изменений (например, новая ветка), чтобы можно было быстро откатиться.
Документация

Напишите небольшое README (или комментарии внутри nginx.conf) о том, как именно работают эти префиксы.
Если у вас меняется имя контейнера или upstream, обновляйте конфиг.
Выделение тестовой среды

Если возможно, поднимайте тестовый Nginx (или тестовый docker-compose) и проверяйте правила на тестовых запросах. Только потом выкатывайте на боевой сервер.
4. Как избежать подобных сложностей в будущем
Шаблонная конфигурация
Создайте один “эталонный” блок для проксирования GeoServer (либо похожего сервиса) и копируйте его для остальных сервисов, меняя лишь имена upstream/пути. Благодаря этому ошибки, связанные с опечатками, будут сведены к минимуму.

Чёткая схема URL до написания конфига
Сначала на бумаге (или в markdown) описать: “Путь /geoserver-vector/ на публичном интерфейсе → переходит на http://geoserver_vector:8080/geoserver/. Нужно переписать cookie-domain и path.”. Аналогично для /geoserver-ecw/.
Когда есть понятная карта, не приходится “на лету” выдумывать rewrite.

Единый стиль именования сервисов
Если в Docker-сети контейнер называется geoserver_ecw, а в Nginx upstream — geoserver-ecw, убедитесь, что эти имена не путают вас. Соблюдайте единый стиль (например, везде через дефис).

Ограничить слишком подробные debug-логи
Часто конфигурация “разрастается”, когда пытаются ловить ошибки, добавляя много костылей. Лучше один раз грамотно настроить логи (debug), посмотреть, где происходит лишний редирект, и поправить логику.

Избегать двойной обработки
Если нужно, чтобы GeoServer отдавал статические файлы (например, стили, шейпы), не нужно дублировать это в Nginx через try_files. Можно просто проксировать всё, что после /geoserver-vector/, на внутренний сервис.

Заключение
Основные проблемы в таких конфигурациях обычно сводятся к тому, что:

Слишком много рассинхронизированных блоков (location ...) для одного и того же сервиса, каждый пытается что-то по-своему редиректить.
Непоследовательное использование rewrite / proxy_redirect / proxy_cookie_ директив*, порождающее конфликт.
Отсутствие чёткой структуры URL (где-то люди пишут http://.../geoserver/, где-то /geoserver-vector/, где-то /something без слэша).
Если упростить логику до пары строк — “всё, что начинается на /geoserver-vector/, уходит в internal-geoserver:8080/geoserver/, куки и пути переписываются”, то конфигурация становится гораздо чище.

Совет:

Начните с одного сервиса (например, GeoServer Vector). Настройте location /geoserver-vector/ так, чтобы все запросы (web UI, wms, wfs, авторизация) шли через один location. Убедитесь, что он работает корректно.
Аналогично скопируйте блок для GeoServer ECW, поменяв только имя upstream и пути cookie.
И только потом добавляйте более узкие блоки (например, location /geoserver-vector/wms) только если это действительно нужно (разные заголовки, кэширование и т.п.).
Таким образом вы получите поддерживаемую и понятную систему проксирования, легко расширяемую на новые сервисы.



советы от сеседней нейросети 
1. Проверить имена сервисов и их соответствие
У вас указаны сервисы:

yaml
Копировать
services:
  geoserver-ecw:
    # ...
  geoserver-vector:
    # ...
  nginx:
    # ...
и в depends_on для nginx прописано:

yaml
Копировать
depends_on:
  - geoserver-ecw
  - geoserver-vector
  - geonetwork
Это хорошо — значит Nginx действительно “знает” про эти сервисы. Внутри Docker сети имя хоста для GeoServer Vector будет geoserver-vector, а порт — 8080 (по умолчанию внутри контейнера).
Таким образом, в конфигурации Nginx (в upstream) нужно указывать:

nginx
Копировать
upstream geoserver_vector {
    server geoserver-vector:8080; 
}
и далее использовать его:

nginx
Копировать
location /geoserver-vector/ {
    proxy_pass http://geoserver_vector/geoserver/;
    ...
}
Обязательно проследите, чтобы имя geoserver-vector (или geoserver-ecw) внутри Nginx совпадало с названием сервиса в docker-compose.yml.

2. Убедиться, что все сервисы в одной сети
В конце файла у вас объявлена сеть:

yaml
Копировать
networks:
  gis_network:
    driver: bridge
    ipam:
      config:
        - subnet: 192.168.100.0/24
и каждый сервис (включая nginx, geoserver-vector, geoserver-ecw) подключён к gis_network.
Например:

yaml
Копировать
geoserver-vector:
  networks:
    - gis_network

nginx:
  networks:
    - gis_network
Благодаря этому Nginx внутри контейнера сможет резолвить имя geoserver-vector и подключаться к порту 8080.

3. Открытие портов vs внутренние порты
Вы прописали:

yaml
Копировать
geoserver-ecw:
  ports:
    - "8081:8080"

geoserver-vector:
  ports:
    - "8082:8080"
Это значит, что с хостовой машины вы сможете обратиться к GeoServer ECW по http://localhost:8081/ и к GeoServer Vector по http://localhost:8082/.
Однако для Nginx внутри сети достаточно обращаться к http://geoserver-ecw:8080 и http://geoserver-vector:8080, минуя внешние порты. Факт, что вы открыли 8081 и 8082, больше нужен для отладки или прямого доступа к GeoServer без Nginx.

4. Проверить конфигурацию Nginx
У вас подключены файлы конфигурации:

yaml
Копировать
nginx:
  build:
    context: ./docker/nginx
    dockerfile: Dockerfile
  ports:
    - "80:80"
  volumes:
    - ./docker/nginx/conf:/etc/nginx/conf.d:ro
Убедитесь, что в ./docker/nginx/conf (или основном nginx.conf) у вас есть корректный блок:

nginx
Копировать
upstream geoserver_vector {
    server geoserver-vector:8080;
}

server {
    listen 80;
    server_name localhost;

    location /geoserver-vector/ {
        proxy_pass http://geoserver_vector/geoserver/;

        # Если нужно переписывать пути к cookie:
        proxy_cookie_path /geoserver /geoserver-vector;
        proxy_cookie_domain geoserver-vector $host;

        proxy_redirect http://geoserver_vector/geoserver/ /geoserver-vector/;

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Перенаправлять /geoserver-vector без слэша:
    location = /geoserver-vector {
        return 301 /geoserver-vector/;
    }
}
После этого:

Выполните docker-compose build nginx (если меняли Dockerfile) и docker-compose up -d --force-recreate nginx, чтобы Nginx пересобрался/перезапустился.
docker-compose logs -f nginx — посмотрите, нет ли там ошибок при старте.
Важный момент: если в конфиге есть root /dev/null; или rewrite ^..., они могут мешать проксированию и порождать 404. Для начала лучше оставить самый минимум (см. выше).

5. Убедиться, что GeoServer действительно запустился
Запустите в терминале:

bash
Копировать
docker-compose ps
Убедитесь, что geoserver-vector и geoserver-ecw находятся в состоянии Up. При необходимости посмотрите логи:

bash
Копировать
docker-compose logs -f geoserver-vector
Иногда GeoServer долго стартует, и если вы делаете запрос слишком рано, можно получить ошибку.

6. Тестирование внутри контейнера Nginx
Зайдите в контейнер Nginx:
bash
Копировать
docker-compose exec nginx sh
Попробуйте:
bash
Копировать
ping geoserver-vector
curl -I http://geoserver-vector:8080/geoserver/
Если DNS-имя geoserver-vector не резолвится, значит либо сервис назван иначе, либо есть проблемы с сетью.
Если резолвится, но вы получаете Connection refused, возможно GeoServer не успел подняться или сервис слушает другой порт.
7. Учитывайте переменные CATALINA_OPTS
В geoserver-vector вы указываете:

yaml
Копировать
- CATALINA_OPTS=-Dorg.geoserver.web.proxy.base=http://localhost/geoserver
Это может привести к тому, что GeoServer внутри может “думать”, что он доступен по http://localhost/geoserver, и генерировать ссылки именно такого вида (например, в интерфейсе).
Когда вы проксируете на http://localhost/geoserver-vector/, эти ссылки могут некорректно вести на localhost/geoserver.

Совет:
Лучше прописать более точный адрес, например:

yaml
Копировать
CATALINA_OPTS=-Dorg.geoserver.web.proxy.base=http://localhost/geoserver-vector
или какое-то внешнее доменное имя (если у вас в планах использовать не “localhost” на боевой машине).

8. Итог
Все сервисы (Nginx, GeoServer-ECW, GeoServer-Vector, GeoNetwork и т.д.) подключены к одной сети (gis_network).
Имена сервисов совпадают с теми, что вы используете в upstream server geoserver-vector:8080;.
Порты: снаружи (на хосте) Nginx доступен по 80:80, GeoServer Vector при желании — по 8082:8080.
Конфигурация Nginx: минимальный блок location /geoserver-vector/ { proxy_pass ... }, без лишних root и rewrite.
CATALINA_OPTS: убедитесь, что org.geoserver.web.proxy.base указывает на тот URL, по которому вы реально планируете заходить.
Если всё соблюдено — обращение к http://localhost/geoserver-vector/web/ (или /ows, /wms и т.д.) должно корректно проксировать запросы к внутреннему контейнеру geoserver-vector.

. Общий обзор вашего конфига
Вы проксируете три сервиса — GeoServer Vector, GeoServer ECW и GeoNetwork — каждая пара “location” + “proxy_pass” указывает на отдельный контейнер. При обращении к:

http://localhost/geoserver-vector/... → перенаправляется на corporate-gis-geoserver-vector-1:8080/geoserver/...
http://localhost/geoserver-ecw/... → перенаправляется на corporate-gis-geoserver-ecw-1:8080/geoserver/...
http://localhost/geonetwork/... → перенаправляется на corporate-gis-geonetwork-1:8080/geonetwork/...
Конфигурация в целом логичная, но есть несколько моментов, на которые стоит обратить внимание.

2. Проверка реальных имён контейнеров
У вас в конфиге фигурируют хосты:

corporate-gis-geoserver-vector-1
corporate-gis-geoserver-ecw-1
corporate-gis-geonetwork-1
Убедитесь, что в Docker Compose (или в вашей инфраструктуре) сервисы действительно имеют точно такие имена внутри Docker сети. Например, если в docker-compose.yml блок выглядит так:

yaml
Копировать
services:
  geoserver-vector:
    container_name: corporate-gis-geoserver-vector-1
    # ...
или Docker сам генерирует имя corporate-gis-geoserver-vector-1 (например, если Compose файл называется corporate-gis, а сервис geoserver-vector).

Важно: если реальное сетевое имя (DNS) сервиса другое — Nginx не сможет достучаться до него. Самый надёжный способ узнать имя — выполнить:

bash
Копировать
docker-compose ps
и посмотреть в столбце Name — это имя контейнера, но DNS-имя может отличаться, если вы явно не указали container_name: или hostname:.

Внутри контейнера Nginx можно проверить доступность так:

bash
Копировать
docker-compose exec nginx sh
ping corporate-gis-geoserver-vector-1
curl -I http://corporate-gis-geoserver-vector-1:8080/geoserver/
Если ping/curl не проходит, значит имя не совпадает.

3. Директивы proxy_redirect
Вы используете:

nginx
Копировать
proxy_redirect default;
proxy_redirect http://corporate-gis-geoserver-vector-1:8080/geoserver/ /geoserver-vector/;
proxy_redirect http://$host:$server_port/geoserver/ /geoserver-vector/;
При этом proxy_redirect default; включает «автоматические» правила для переписывания заголовков Location: и Refresh:.
Потом вы вручную добавляете ещё несколько proxy_redirect.
В некоторых случаях это может порождать дублирование правил.

Если GeoServer внутри возвращает Location: http://corporate-gis-geoserver-vector-1:8080/geoserver/..., то ваша вторая директива всё правильно перепишет на /geoserver-vector/....
Но если внутри GeoServer (через CATALINA_OPTS) прописано org.geoserver.web.proxy.base=http://$host:$server_port/geoserver, тогда третья директива будет нужна.
Иногда бывает проще не использовать proxy_redirect default;, а перечислить только нужные явные правила.

Совет: Начните с чего-то такого:

nginx
Копировать
proxy_redirect off;
proxy_redirect http://corporate-gis-geoserver-vector-1:8080/geoserver/ /geoserver-vector/;
и посмотрите, всё ли работает. Если внутри GeoServer формирует ссылки вида http://$host:$server_port/geoserver, тогда добавьте отдельное правило.

4. Заголовок Host $host:$server_port
Когда вы используете:

nginx
Копировать
proxy_set_header Host $host:$server_port;
proxy_set_header X-Forwarded-Host $host:$server_port;
на самом деле в большинстве случаев достаточно:

nginx
Копировать
proxy_set_header Host $host;
proxy_set_header X-Forwarded-Host $host;
Порт обычно не требуется, если ваш GeoServer внутри не ожидает, что Host будет содержать порт (например, для виртуальных хостов).

Иногда, если вы реально слушаете на порту 8080 извне, а хотите чтобы GeoServer “думал”, что всё идёт по :8080, можно оставить $host:$server_port. Но если у вас localhost:80 — смысла нет.

Совет: Попробуйте упростить до proxy_set_header Host $host; и только если что-то пойдёт не так (GeoServer не понимает адрес, на который пришли), возвращайте $server_port.

5. Лишнее или противоречивое в проксировании cookie
Вы применяете:

nginx
Копировать
proxy_cookie_path /geoserver /geoserver-vector;
proxy_cookie_domain corporate-gis-geoserver-vector-1 $host;
Это корректно, если GeoServer ставит куку с Path=/geoserver и Domain=corporate-gis-geoserver-vector-1. Тогда Nginx автоматически перепишет их в Path=/geoserver-vector и Domain=$host.

Убедитесь, что сам GeoServer действительно проставляет куки с Domain=corporate-gis-geoserver-vector-1. Если нет, данная директива не сработает.

Если у вас нет логики сессий/авторизации (например, вы используете GeoServer в анонимном доступе), может быть, куки и не нужны. Тогда эти директивы не будут влиять, но и не навредят.

6. Проверка кода редиректов в логах
Раз вы включили error_log /var/log/nginx/error.log debug;, стоит понаблюдать:

При запросе curl -v http://localhost/geoserver-vector/ → посмотрите, какой Location: возвращает Nginx (или GeoServer).
В error.log в режиме debug будет видно, как Nginx обрабатывает proxy_redirect, куда он подставляет $host, $server_port и т.д.
Так можно быстро отследить, корректно ли ваши правила «подправляют» заголовки.

7. Итоговые рекомендации
Проверить Docker Compose: реально ли контейнеры называются corporate-gis-geoserver-vector-1, -ecw-1, -geonetwork-1. И убедиться, что Nginx может достучаться до них (командой docker-compose exec nginx sh → curl -I http://corporate-gis-geoserver-vector-1:8080/geoserver/).

Упростить proxy_redirect. Если вы используете proxy_redirect default;, внимательно проверяйте, не дублируют ли ваши ручные proxy_redirect в ту же сторону. Иногда достаточно только одного:

nginx
Копировать
proxy_redirect http://corporate-gis-geoserver-vector-1:8080/geoserver/ /geoserver-vector/;
и proxy_redirect off; вместо default;.

Заголовки Host. По умолчанию достаточно:

nginx
Копировать
proxy_set_header Host $host;
proxy_set_header X-Forwarded-Host $host;
Если хотите явно прокидывать порт, убедитесь, что GeoServer настроен на такой порт.

Проверяйте логи. С debug-уровнем вы увидите много подробностей о том, почему Nginx редиректит или пытается искать локальные файлы.

Проверьте CATALINA_OPTS в GeoServer. Если внутри GeoServer (через org.geoserver.web.proxy.base) прописан другой адрес (например, http://localhost/geoserver), могут возникать коллизии. Иногда лучше указать http://localhost/geoserver-vector или оставить пустым, если вы всё делаете через Nginx.

Заключение
В общем и целом, ваш конфиг выглядит почти готовым к работе. Основные потенциальные проблемы — это:

Совпадает ли реальное имя Docker-контейнеров с corporate-gis-geoserver-vector-1 и т.д.?
Не конфликтует ли proxy_redirect default; с ручными правилами?
Нужно ли включать порт в заголовок Host?
Упростите эти моменты, проверьте доступность по curl -v, и всё должно работать корректно.