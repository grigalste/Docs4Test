# Docs4Test


git clone https://github.com/grigalste/Docs4Test.git && cd ./Docs4Test
cp docsinstall.sh /usr/local/bin/docsinstall && chmod a+x /usr/local/bin/docsinstall
### Init:
```sh
bash docsinstall.sh -init true -domain domain.name -email mail@domain.name
```
or
```sh
docsinstall -init true -domain domain.name -email mail@domain.name
```
### Recreate certificate:
```sh
bash docsinstall.sh -cert true -domain domain.name -email mail@domain.name
```
### Add DS:
```sh
bash docsinstall.sh -add true --documentversion 7.5.1.1
```
```sh
bash docsinstall.sh -add true --documentversion 7.5.1.1 --jwtenabled true --jwtheader AuthorizationJwt --jwtsecret JWTforTest --wopi true
```
```sh
bash docsinstall.sh -add true --documentversion 8.0.1.1 -log DEBUG
```
```sh
bash docsinstall.sh -add true --documentversion 8.1.0.93 --documenttype 4testing-documentserver-de
```
### Del DS:
```sh
bash docsinstall.sh -del true --documentname documentserver-8.0.1.1
```

### Start container
```sh
docker run -i -t -d --restart=always --net onlyoffice --name documentserver-${DOCUMENT_VERSION} \
 -v $BASE_DIR/DocumentServer/logs/documentserver-${DOCUMENT_VERSION}:/var/log/onlyoffice \
 -v $BASE_DIR/DocumentServer/data/:/var/www/onlyoffice/Data/ \
 -v $BASE_DIR/DocumentServer/fonts:/usr/share/fonts/custom \
 -v $BASE_DIR/DocumentServer/forgotten:/var/lib/$PRODUCT/documentserver/App_Data/cache/files/forgotten \
 -e DS_LOG_LEVEL=${DS_LOG_LEVEL} \
 -e JWT_ENABLED=${JWT_ENABLED} -e JWT_HEADER=${JWT_HEADER} -e JWT_SECRET=${JWT_SECRET} -e JWT_IN_BODY=${JWT_IN_BODY} \
 -e WOPI_ENABLED=${WOPI_ENABLED} ${DOCUMENT_IMAGE_NAME}:${DOCUMENT_VERSION})
 ```
