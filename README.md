# Docs4Test

### Init:
```sh
bash docsinstall.sh -init true -domain domain.name -email mail@domain.name
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
