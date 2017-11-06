/* {{ ansible_managed }} */
/* syntax 4 compatible */ 
vcl 4.0;

/* définition du backend par defaut (et de ses probes) */
backend default {
	.host = "127.0.0.1";
	.port = "80";
	.connect_timeout = 1s;
	.first_byte_timeout = 30s;
	.probe = {
		.url = "/";
		.timeout  = 2s;
		.interval = 3s;
		.window    = 5;
		.threshold = 2;
	}
}
sub vcl_recv {
	/* Utilisation du backend default */
	set req.backend_hint = default ;
        
	/* Ajout des IP sources et intermédiaires dans l'entete HTTP de la requete (X-Forwarded-For) */
	if (req.restarts == 0) {
		if (req.http.x-forwarded-for) {
			set req.http.X-Forwarded-For = req.http.X-Forwarded-For + ", " + client.ip;
		} else {
			set req.http.X-Forwarded-For = client.ip;
		}
	}

        /* Pipe directement au backend pour les méthodes non standard */ 
        if (req.method != "GET" &&
                req.method != "HEAD" &&
                req.method != "PUT" &&
                req.method != "POST" &&
                req.method != "TRACE" &&
                req.method != "OPTIONS" &&
                req.method != "DELETE") {
                return (pipe);
        }
        /* Ne pas chercher dans le cache quand la méthode est différentes de GET ou HEAD  */
        if (req.method != "GET" && req.method != "HEAD") {
                return (pass);
        }

        /* a expliquer */
	if (req.url ~ "\.(jpeg|jpg|png|gif|ico|swf|js|css|gz|rar|txt|bzip|pdf)$") {
		unset req.http.Cookie;
		return (hash);
	}
        
	/* Ne pas cacher pour les requêtes avec header d'authentification (session personnalisée) */
	if (req.http.Authorization) {
		return (pass);
	}

	 # Skip the Varnish cache for install, update, and cron.
	if (req.url ~ "install\.php|update\.php|cron\.php") {
		return (pass);
	} 

	if (req.url ~ "^/server-status$") {
		return (pass);
	} 

	return (hash);
}

sub vcl_hash {
	/* définition du hash utilisé pour le lookup */
	hash_data(req.url);
	if (req.http.host) {
		hash_data(req.http.host);
	} else {
		hash_data(server.ip);
	}
	if (req.http.Cookie) {
		hash_data(req.http.Cookie);
	}
	return(lookup);
}

sub vcl_pass {
	/* On ajoute le header de status dans la requête à destination du backend */
	set req.http.X-marker = "pass" ;
}

sub vcl_backend_response {
        /* compression Gzip des objets */
        if ( ! beresp.http.Content-Encoding ~ "gzip" ) {
                set beresp.do_gzip = true;
        }

        /* Efface le set-cookie sur les medias */
	if (bereq.url ~ "\.(jpeg|jpg|png|gif|ico|swf|js|css|gz|rar|bzip|pdf)$") {
		unset beresp.http.set-cookie;
	}

	/* Cache des redirections si le code est 3* et pendant 10 mn( durée arbitraires ) */
	if (beresp.ttl > 0s ) {
		if (beresp.status >= 300 && beresp.status <= 399) {
			set beresp.ttl = 10m;
		}
		/* si le code est superieur a 400, 403, 404 par ex, on ne cache pas */	
		if (beresp.status >= 399) {
			set beresp.ttl = 0s;
		}
	}

	/*  On efface le set-cookie sur les pages de blocage et d'erreur */ 
	if (beresp.status >= 399) {
		unset beresp.http.set-cookie;
	}

        /* le TTL par defaut est de 24h */
	if (beresp.ttl > 86400s) {
		set beresp.ttl = 86400s;
	}

	/* A definir */
	if (bereq.http.X-marker == "pass" ) {
		unset bereq.http.X-marker;
		set beresp.http.X-marker = "pass";
		set beresp.ttl = 0s ;
	}

        /* Ne pas cacher la réponse du backend si celui-ci positionne un cookie (set Cookie) */
	if (beresp.ttl > 0s && beresp.http.set-cookie) {
		set beresp.ttl = 0s ;
	}
}
sub vcl_deliver {
	/* Ajout d'un header sur le resultat du caching */
        if (obj.hits > 0){
                set resp.http.X-Varnish-Cache = "HIT";
        } else {
                set resp.http.X-Varnish-Cache = "MISS";
        }
	/* On suprimme le header X-marker */
        if (resp.http.X-marker == "pass" ) {
                unset resp.http.X-marker;
                set resp.http.X-Varnish-Cache = "PASS";
        }
        
	/* On conserve ces entêtes pour le troubleshooting */
	/* unset resp.http.Via;
	unset resp.http.X-Varnish;
	unset resp.http.Server;
	unset resp.http.X-Powered-By; */

	/* FOURNISSEUR troubleshooting */
	/* On ajoute le nom backend dans la réponse au client */ 
	set resp.http.X-varnishID = server.hostname;
}
sub vcl_synth {
	/* on redémarre 5 fois le traitement si le code retour du backend est > 5) */
        if (resp.status >= 500 && req.restarts < 4) {
                return (restart);
        }
}
