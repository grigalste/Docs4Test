#!/bin/bash

PRODUCT="onlyoffice";
BASE_DIR="/app/$PRODUCT";
NETWORK="$PRODUCT";

while [ "$1" != "" ]; do
	case $1 in

		-add | --add )
			if [ "$2" != "" ]; then
				ADD_CONTAINER="true"
				shift
			fi
		;;

		-del | --del )
			if [ "$2" != "" ]; then
				DEL_CONTAINER="true"
				shift
			fi
		;;

		-init | --init )
			if [ "$2" != "" ]; then
				INIT_SYSTEM="true"
				shift
			fi
		;;

		-cert | --certrenew )
			if [ "$2" != "" ]; then
				CERT_RENEW="true"
				shift
			fi
		;;

		-domain | --domain )
			if [ "$2" != "" ]; then
				DOMAIN=$2
				shift
			fi
		;;

		-email | --email )
			if [ "$2" != "" ]; then
				EMAIL=$2
				shift
			fi
		;;

		-dt | --documenttype )
			if [ "$2" != "" ]; then
				DOCUMENT_IMAGE_TYPE=$2
				shift
			fi
		;;

		-dv | --documentversion )
			if [ "$2" != "" ]; then
				DOCUMENT_VERSION=$2
				shift
			fi
		;;

		-dn | --documentname )
			if [ "$2" != "" ]; then
				DOCUMENT_CONT_NAME=$2
				shift
			fi
		;;

		-je | --jwtenabled )
			if [ "$2" != "" ]; then
				JWT_ENABLED=$2
				shift
			fi
		;;

		-jh | --jwtheader )
			if [ "$2" != "" ]; then
				JWT_HEADER=$2
				shift
			fi
		;;

		-js | --jwtsecret )
			if [ "$2" != "" ]; then
				JWT_SECRET=$2
				shift
			fi
		;;

		-jib | --jwtinbody )
			if [ "$2" != "" ]; then
				JWT_IN_BODY=$2
				shift
			fi
		;;

		-log | --dsloglevel )
			if [ "$2" != "" ]; then
				DS_LOG_LEVEL=$2
				shift
			fi
		;;

		* )
			echo "Unknown parameter $1" 1>&2
			exit 1
		;;
	esac
	shift
done

DOCUMENT_IMAGE_TYPE=${DOCUMENT_IMAGE_TYPE:-documentserver-de}
DOCUMENT_IMAGE_NAME="${PRODUCT}/${DOCUMENT_IMAGE_TYPE}";
DOCUMENT_VERSION=${DOCUMENT_VERSION:-latest}

JWT_ENABLED=${JWT_ENABLED:-true}
JWT_HEADER=${JWT_HEADER:-AuthorizationJwt}
JWT_SECRET=${JWT_SECRET:-JWTforTest}
JWT_IN_BODY=${JWT_IN_BODY:-false}

WOPI_ENABLED=${WOPI_ENABLED:-true}

DS_LOG_LEVEL=${DS_LOG_LEVEL:-WARN}

if [ "$DOMAIN" == "" ] ; then
	echo "The domain name is not specified";
else
	EMAIL=${EMAIL:-support@$DOMAIN}
fi

command_exists () {
    type "$1" &> /dev/null;
}

install_docker_using_script () {
	if ! command_exists curl ; then
		apt-get -y -q install curl
	fi

	curl -fsSL https://get.docker.com -o get-docker.sh
	sh get-docker.sh
	rm get-docker.sh
	
	systemctl enable --now docker
}

if [ "$INIT_SYSTEM" == "true" ] ; then

	apt update;
	apt install curl snapd -y ;
	snap install --classic certbot;
	ln -s /snap/bin/certbot /usr/bin/certbot;
	
	if command_exists docker ; then
		systemctl enable --now docker
	else
		install_docker_using_script
	fi

	mkdir -p "$BASE_DIR/DocumentServer/data/";
	mkdir -p "$BASE_DIR/DocumentServer/logs";
	mkdir -p "$BASE_DIR/DocumentServer/fonts";
	mkdir -p "$BASE_DIR/DocumentServer/forgotten";
	mkdir -p "$BASE_DIR/DocumentServer/logs/" ;
	mkdir -p /app/nginx/{include,www,ssl}/ ;
	
	cp index.html /app/nginx/www/index.html 
	cp letsencrypt.conf /app/nginx/include/letsencrypt.conf
	cp nginx.conf /app/nginx/nginx.conf
	
	docker run --rm --name certbot -p 80:80 -v "/etc/letsencrypt:/etc/letsencrypt" -v "/lib/letsencrypt:/var/lib/letsencrypt" -v "/app/nginx/www:/app/nginx/www" certbot/certbot certonly --webroot -v --cert-name $DOMAIN -w /app/nginx/www --noninteractive --agree-tos --email $EMAIL -d $DOMAIN
	CHECK_STATUS=$?;

	if [ "$CHECK_STATUS" == "0" ] ; then
		echo "Done"
		echo "Certificates have been created!"
	else
		echo "Error create certificates";
		exit 1;	
	fi
	
	###Create cronjob certbot renew
	SLEEPTIME=$(awk 'BEGIN{srand(); print int(rand()*(3600+1))}');
	echo "0 0,12 * * * root sleep $SLEEPTIME && certbot renew -q" | sudo tee -a /etc/crontab > /dev/null


	docker network create --driver bridge onlyoffice 2> /dev/null
	
	docker run -i -t -d -p 80:80 -p 443:443 --net onlyoffice --restart=always --name=nginx-server \
    -v /app/nginx/nginx.conf:/etc/nginx/nginx.conf \
    -v /app/nginx/include:/etc/nginx/include \
    -v /etc/letsencrypt/live/$DOMAIN:/etc/nginx/ssl \
    -v /etc/letsencrypt/live/$DOMAIN:/etc/nginx/ssl \
    -v /app/nginx/www:/usr/share/nginx/html:ro nginx

	echo "Sleeeep...";
	sleep 2s

fi

if [ "$CERT_RENEW" == "true" ] ; then

	RESULT=$(docker ps | grep nginx-server);
	CHECK_STATUS=$?;

	if [ "$CHECK_STATUS" == "0" ] ; then
		docker run --rm --name certbot -v "/etc/letsencrypt:/etc/letsencrypt" -v "/lib/letsencrypt:/var/lib/letsencrypt" -v "/app/nginx/www:/app/nginx/www" certbot/certbot certonly --webroot -v --cert-name $DOMAIN -w /app/nginx/www --noninteractive --agree-tos --email $EMAIL -d $DOMAIN
	else
		echo "Container NGINX is not running";
		exit 1;	
	fi
		
fi

if [ "$DEL_CONTAINER" == "true" ] ; then

	DOCUMENT_VERSION=$(echo $DOCUMENT_CONT_NAME | cut -d- -f2);
	
	docker rm -f $DOCUMENT_CONT_NAME ;
	CHECK_STATUS=$?;

	if [ "$CHECK_STATUS" == "0" ] ; then
		echo "Done"
		echo "The container has been deleted!"
	else
		echo "Error";
		exit 1;	
	fi
	
	rm $BASE_DIR/DocumentServer/logs/documentserver-${DOCUMENT_VERSION};

	rm /app/nginx/include/${DOCUMENT_VERSION}.conf
	docker exec nginx-server service nginx reload

	sed -i '/<li><a href="\/'${DOCUMENT_VERSION}'\/">'${DOCUMENT_VERSION}' - /d' /app/nginx/www/index.html

fi


if [ "$ADD_CONTAINER" == "true" ] ; then

### Create container
RESULT=$(docker run -i -t -d --restart=always --net onlyoffice --name documentserver-${DOCUMENT_VERSION} \
 -v $BASE_DIR/DocumentServer/logs/documentserver-${DOCUMENT_VERSION}:/var/log/onlyoffice \
 -v $BASE_DIR/DocumentServer/data/:/var/www/onlyoffice/Data/ \
 -v $BASE_DIR/DocumentServer/fonts:/usr/share/fonts/custom \
 -v $BASE_DIR/DocumentServer/forgotten:/var/lib/$PRODUCT/documentserver/App_Data/cache/files/forgotten \
 -e DS_LOG_LEVEL=${DS_LOG_LEVEL} \
 -e JWT_ENABLED=${JWT_ENABLED} -e JWT_HEADER=${JWT_HEADER} -e JWT_SECRET=${JWT_SECRET} -e JWT_IN_BODY=${JWT_IN_BODY} \
 -e WOPI_ENABLED=${WOPI_ENABLED} ${DOCUMENT_IMAGE_NAME}:${DOCUMENT_VERSION})

CHECK_STATUS=$?;

	if [ "$CHECK_STATUS" == "0" ] ; then
		echo "Done"
		echo "Wait for the container to start!"
	else
		echo "Error";
		exit 1;	
	fi

###Getting a container ID
ID_CONTEINER=$(echo $RESULT | head -c 9)

###Add NGINX config
cat <<EOF > /app/nginx/include/${DOCUMENT_VERSION}.conf
        location ~* ^/${DOCUMENT_VERSION}/ {
                rewrite /${DOCUMENT_VERSION}/(.*) /\$1  break;
                proxy_pass http://documentserver-${DOCUMENT_VERSION};
                proxy_redirect     off;

                client_max_body_size 100m;

                proxy_http_version 1.1;
                proxy_set_header Upgrade \$http_upgrade;
                proxy_set_header Connection "upgrade";

                proxy_set_header Host \$http_host;
                proxy_set_header X-Real-IP \$remote_addr;
                proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
                proxy_set_header X-Forwarded-Host \$the_host/${DOCUMENT_VERSION};
                proxy_set_header X-Forwarded-Proto \$the_scheme;
        }
        
        
EOF

###Add new link
sed -i '/<!-- ##PASTHERE -->/a <li><a href="/'${DOCUMENT_VERSION}'/" target="_blank">'${DOCUMENT_VERSION}' - '${DOCUMENT_IMAGE_TYPE}'</a></li>' /app/nginx/www/index.html

###Fix EXAMPLE config
docker exec ${ID_CONTEINER} bash -c 'cat <<EOF > /etc/onlyoffice/documentserver-example/local-production-linux.json
{
  "server": {
    "apiUrl": "'${DOCUMENT_VERSION}'/web-apps/apps/api/documents/api.js",
    "preloaderUrl": "'${DOCUMENT_VERSION}'/web-apps/apps/api/documents/cache-scripts.html"
    }
}

EOF'

echo "Sleeeep...";
sleep 2s

###Start/Reload services
docker exec nginx-server service nginx reload
docker exec ${ID_CONTEINER} supervisorctl start ds:example
docker exec ${ID_CONTEINER} sed 's,autostart=false,autostart=true,' -i /etc/supervisor/conf.d/ds-example.conf

fi

docker ps -a;

