# http://blog.jeremm.fr/?tag=varnish-2 && personnalisation Ecritel Install 
# configuration simple mono-backend

backend default {
	.host = "127.0.0.1";
	.port = "80";
	.connect_timeout = 1s;
	.first_byte_timeout = 30s;
	/* On met une probe pour utiliser les fonctions d'etat des probes ex backend.list sur Varnish 3* avec nos check */ 
	.probe = {
        	.url = "/";
        	.timeout  = 15s;
        	.interval = 15s;
        	.window    = 5;
        	.threshold = 2;
    	}
}
 
sub vcl_recv {
	/* a confirmer */ 
	set req.grace = 300s;

	/* on defini le backend tres tot */
   	set req.backend = default ;

	/* Gestion du X-Forwarded-For */
   	if (req.restarts == 0) {
		/* Si l'entete existe on l'incremente */
      		if (req.http.x-forwarded-for) {
          		set req.http.X-Forwarded-For = req.http.X-Forwarded-For + ", " + client.ip;
      		} else {
			/* sinon on le cree */
	          	set req.http.X-Forwarded-For = client.ip;
      		}
   	}

	/* on ne "deal" pas avec les methodes exotiques non RFC */ 
	if (req.request != "GET" &&
	req.request != "HEAD" &&
	req.request != "PUT" &&
	req.request != "POST" &&
	req.request != "TRACE" &&
	req.request != "OPTIONS" &&
	req.request != "DELETE") {
        	return (pipe);
	}

	/* On ne cachera que les methodes GET ou HEAD (la derniere n'est que l'entete */
	if (req.request != "GET" && req.request != "HEAD") {
		return (pass);
	}
	/* on retire de possibles cookies sur les elements suivants ca sert a rien */	
	/* il s'agit des cookie renvoye par le navigateur (voir section vcl_fetch) */
	if (req.url ~ ".(jpeg|jpg|png|gif|ico|swf|js|css|gz|rar|txt|bzip|pdf)$") {
		unset req.http.Cookie;
		return (lookup);
	}
	/* les authentification HTTP ne sont pas cachees */
	if (req.http.Authorization) {
		return (pass);
	}
	/* On ne cache pas les url d'execution de tache longues */
	if (req.url ~ "cron\.php|crontab\.php|update\.php") {
		return (pass);
	}	

	/* specifique check ecritel */
	if (req.http.X-Ecritel-Check) {
		return(pass);
	}
  
   return (lookup);
}
 
/* a confirmer */ 
sub vcl_hash {
        hash_data(req.url);
        if (req.http.host) {
                hash_data(req.http.host);
        } else {
                hash_data(server.ip);
        }
	return (hash);
}

sub vcl_pass {
	/* on autorise un temps d'executioin de 300s pour certaines UR */ 
	if (req.url ~ "cron(tab)?\.php|update(s)?\.php") {
        	set bereq.first_byte_timeout = 300s;
        }
}
sub vcl_fetch {

	/* on ajoute un entete contenant le nom du serveur varnish (attention, il s'agit d'une variable) */   
	set beresp.http.X-Varnish-Server = server.hostname; 

	/* on retire de possibles cookies sur les elements suivants car ca sert a rien */	
	/* il s'agit des cookie cree par le serveur */
        if (req.url ~ ".(jpeg|jpg|png|gif|ico|swf|js|css|gz|rar|txt|bzip|pdf)$") {
                unset beresp.http.Set-Cookie;
        }
}
 
sub vcl_deliver {
        if (obj.hits > 0){
		/* On ajoute cette entete si HIT il y a */ 
                set resp.http.X-Varnish-Cache = "HIT";
        }else{
		/* On ajoute cette entete si MISSS il y a */ 
                set resp.http.X-Varnish-Cache = "MISS";
        }
	/* par securite on nettoie la reponse en degageant les entetes suivants */ 
        remove resp.http.Via; /* utilise par les proxy (Varnish par ex) */
        remove resp.http.X-Varnish; 
        remove resp.http.Server;  
        remove resp.http.X-Powered-By; /* On nettoie les signatures ASP et PHP */
}
 
sub vcl_error {
	/* apparemment, a confirmer , si le code retour est > a 500 et que le nb de tentative de 
	connexion au backend est inferieur a 4, une nouvelle tentative est initialiser */
        if (obj.status >= 500 && req.restarts < 4) {
                return (restart);
        }
}
