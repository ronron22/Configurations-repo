
## Munin cgi vs Nginx

## Recette de cuisine à base de fcgi et supervisord
 https://gist.github.com/informationsea/2ee950dfc01d1658c7c4

## Recette de cuisine à base de fcgi et systemd

### Configuration Nginx 

Configurer fastcgi pour attaquer le socket Unix du process spawn-fcgi

```
        location /munin {
                alias /var/cache/munin/www;
                index index.html;
                access_log   off;
                allow   127.0.0.1;
                allow   277.256.110.0/24;
                deny all;
        }

        location ^~ /munin-cgi/munin-cgi-graph/ {
                access_log off;
                fastcgi_split_path_info ^(/munin-cgi/munin-cgi-graph)(.*);
                fastcgi_param PATH_INFO $fastcgi_path_info;
                fastcgi_pass unix:/var/run/munin/fcgi-munin-graph.sock;
                include fastcgi_params;
        }
```

### spawn-fcgi
```
        apt install spawn-fcgi
```

débugger spawn-fcgi :

```
        spawn-fcgi -n -s /var/run/munin/spawn-fcgi-munin-graph.sock \
        -U www-data -u munin -g munin /usr/lib/munin/cgi/munin-cgi-graph
```        
        
spawn-fcgi et systemd

```
        cat  /etc/systemd/system/fastcgi-munin.service
        [Unit]
        Description=FastCGI spawner for Munin cgi

        [Service]
        User=munin
        Group=www-data
        StandardError=syslog
        Type=forking
        Restart=on-abort
        SyslogIdentifier=fastcgi-munin
        ExecStartPre=/bin/rm -f /var/run/fastcgi-munin.pid
        ExecStartPre=/bin/rm -f /var/run/munin/fcgi-munin-graph.sock
        ExecStart=/usr/bin/spawn-fcgi -s /var/run/munin/fcgi-munin-graph.sock -U www-data -u munin -g munin /usr/lib/munin/cgi/munin-cgi-graph -M 0770

        [Install]
        WantedBy=multi-user.target
```
