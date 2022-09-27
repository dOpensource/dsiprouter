upstream fusionpbx {
	##SERVERLIST##
}


# handle the https requests
server {
    # by default we listen on all interfaces
    listen 443 ssl http2 so_keepalive=on; 
    listen [::]:443 ssl http2 so_keepalive=on;  
    server_name _;

    ssl_certificate /etc/dsiprouter/certs/dsiprouter-cert.pem;
    ssl_certificate_key /etc/dsiprouter/certs/dsiprouter-key.pem;

    location ~^(\/app\/provision\/|\/provision\/) {
            proxy_pass https://fusionpbx;
            proxy_redirect off;
	    proxy_set_header Host $host;
            proxy_next_upstream error timeout http_404 http_403 http_500 http_502 http_503 http_504 non_idempotent;
    }
	
    location / {

        error_page 404  /404.html;

    }

    location /images/ {
	alias /etc/nginx/html/images/;
    }

    # enable the access log for debugging
    # it doesn't log data between nginx and the upstream FusionPBX servers
    # it only logs data between the phone and nginx
    #access_log /var/log/nginx/dsiprouter-provisioner-access.log;
}
