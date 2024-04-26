# Docs4Test
Docs4Test

Init:
bash docsinstall.sh -init true -domain docker.office24.site

Add DS:
bash docsinstall.sh -add true --documentversion 7.5.1.1
bash docsinstall.sh -add true --documentversion 8.0.1.1 -log DEBUG
bash docsinstall.sh -add true --documentversion 8.1.0.91 --documenttype 4testing-documentserver-de

Del DS:
bash docsinstall.sh -del true --documentname documentserver-8.0.1.1
