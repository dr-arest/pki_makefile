######################################################################
#
#	Make file to be installed in /etc/raddb/certs to enable
#	the easy creation of certificates.
#
#	See the README file in this directory for more information.
#
#	$Id: 16447a023d2cdce2d16d39cf31bcde4dba600df5 $
#
######################################################################

root		= ../root-ca/root-ca
sub		= ../sub-ca/sub-ca
SUB		= ../sub-ca
BASE		= 
PKCS11PIN	= 3128443
PKCS11MASTERPIN	= Perekatipole
PKCS11_MODULE = /usr/lib/librtpkcs11ecp.so
#PKCS11_MODULE = /usr/lib/libeTPkcs11.so
SUBPASS		= PerekatipoleSubJOZEPH
ROOTPASS	= PerekatipoleRootJOZEPH
SAN="DNS:arest-home.pp.ua,DNS:*.arest-home.pp.ua,DNS:arest-home.loc,DNS:*.arest-home.loc,IP:193.93.219.55,IP:192.168.51.65,IP:192.168.51.70"
INSTALL		= install

TARGET-CRT	= clt.crt clt.pem
TARGET-KEY	= clt.key clt.p12
TARGET-CA	= sub-ca-chain.pem
DESTCERTDIR	= /etc/ssl 
DESTPKIDIR	= /var/www/pki
DESTKEYDIR	= /etc/ssl/private 
DESTPKIKEYDIR	= /var/www/pki/private

EXPECTHELPER	= expect /etc/ssl/build_link.expect

source_dirs = . ../root-ca ../sub-ca
DH_KEY_SIZE	= 2048
OPENSSL		= openssl
PKCS11TOOL	= pkcs11-tool --module $(PKCS11_MODULE)
PKCS15TOOL	= pkcs15-init
SSHKEYGEN	= ssh-keygen
EXTERNAL_CA	= $(wildcard external_ca.*)

#ifneq "$(EXTERNAL_CA)" ""
#PARTIAL		= -partial_chain
#endif

PARTIAL		= -partial_chain

##
##  Set the passwords
#
include passwords.mk

######################################################################
#
#
######################################################################
.PHONY: all # Make everything
all: clt 

.PHONY: clt # Make Sub CA infrastructure
clt: clt.der clt.key.der clt.pub.der clt.ssh.pub clt.vrfy

.PHONY: verify  # Verify server and client certficates
verify: clt.vrfy

.PHONY: revoke # Verify server and client certficates
revoke: clt.revoke

.PHONY: clean-pkcs11 # Clean PKCS11 token (be careful!)
clean-pkcs11: 
	@$(PKCS11TOOL) --init-token --label "Arest ruToken" --so-pin $(PKCS11MASTERPIN)
	@$(PKCS11TOOL) --init-pin --login --pin $(PKCS11PIN) --so-pin $(PKCS11MASTERPIN)
	@$(PKCS15TOOL) --erase-card -p rutoken_ecp -l "Arest ruToken" 
	@$(PKCS15TOOL) --create-pkcs15 --so-pin $(PKCS11MASTERPIN) --so-puk ""
	@$(PKCS15TOOL) --store-pin --label "User PIN" --auth-id 02 --pin $(PKCS11PIN) --puk "" --so-pin $(PKCS11MASTERPIN) --finalize

passwords.mk:
	@echo "PASSWORD_ROOT_CA	= '$(shell grep output_password $(root).cnf | sed 's/.*=//;s/^ *//')'"		>> $@
	@echo "PASSWORD_SUB_CA	= '$(shell grep output_password $(sub).cnf | sed 's/.*=//;s/^ *//')'"		>> $@
	@echo "PASSWORD_CLIENT	= '$(shell grep output_password clt.cnf | sed 's/.*=//;s/^ *//')'"		> $@

######################################################################
#
#  Create a new Sub CA certificate
#
######################################################################
VPATH = ../sub-ca

clt.csr clt.key: clt.cnf
	$(OPENSSL) req -new -keyout clt.key -out clt.csr \
		-days 730 -config clt.cnf
	chmod g+r clt.key

clt.crt: sub-ca.crt sub-ca.key clt.csr clt.key
	@$(OPENSSL) ca -batch -keyfile $(sub).key -cert $(sub).crt -in clt.csr  -passin pass:$(SUBPASS) -out clt.crt -extensions xpclient_ext -extfile xpextensions -config $(sub).cnf

clt.der: clt.crt
	$(OPENSSL) x509 -inform PEM -outform DER -in $< -out $@

clt.key.der: clt.key
	$(EXPECTHELPER) clt key.der
#	$(OPENSSL) rsa -inform PEM -outform DER -in $< -out $@

clt.pub: clt.key
	$(EXPECTHELPER) clt pub
#	$(OPENSSL) rsa -pubout -in $< -out $@

clt.pub.der:	clt.pub
	$(OPENSSL) rsa -pubin -in $< -pubout -outform DER -out $@

clt.rsa.pub: clt.key
	$(EXPECTHELPER) clt rsa.pub
#	$(OPENSSL) rsa -RSAPublicKey_out -in $< -out $@

clt.ssh.pub: clt.pub
	$(SSHKEYGEN) -i -f $< -m PKCS8 > $@

clt.p12: clt.crt clt.key
	$(EXPECTHELPER) clt pkcs12
#	$(OPENSSL) pkcs12 -export -in clt.crt -inkey clt.key -out clt.p12 -passin pass:$(PASSWORD_CLIENT) -passout pass:$(PASSWORD_CLIENT)
	chmod g+r clt.p12

clt.pem: clt.p12
	@$(OPENSSL) pkcs12 -in clt.p12 -out clt.pem -passin pass:$(PASSWORD_CLIENT) -passout pass:$(PASSWORD_CLIENT)

.PHONY: clt.pkcs11 # Put Sub CA certificate and key to PKCS11 token
clt.pkcs11:	clt.der clt.key.der clt.pub.der
	@$(PKCS11TOOL) -y cert -w clt.der --label "Arest Sub CA Certificate" --attr-from clt.der --pin $(PKCS11$PIN) -l
	@$(PKCS11TOOL) -y privkey -w clt.key.der --label "Arest Sub CA Private Key" --attr-from clt.der --pin $(PKCS11PIN) -l
	@$(PKCS11TOOL) -y pubkey -w clt.pub.der --label "Arest Sub CA Public Key" --attr-from clt.der --pin $(PKCS11PIN) -l
	
.PHONY: clt.vrfy # Verify client certifcate using ca-chain.pem
clt.vrfy: sub-ca-chain.pem clt.crt
	$(OPENSSL) verify $(PARTIAL) -CAfile $< clt.crt

.PHONY: clt.revoke # Verify client certifcate using ca-chain.pem
clt.revoke: sub-ca.key clt.crt
	@$(OPENSSL) ca -revoke clt.crt -crl_reason superseded -config $(sub).cnf

print:
	$(OPENSSL) x509 -text -in clt.crt

printca:
	$(OPENSSL) x509 -text -in $(sub).crt

printssh:
	$(PKCS15TOOL)

#
#	Make a target that people won't run too often.
#

.PHONY: help # Generate list of targets with descriptions                                                                
help:                                                                                                                    
	@grep '^.PHONY: .* #' Makefile | sed 's/\.PHONY: \(.*\) # \(.*\)/\1 \2/' | expand -t20
clean:
	@rm -f *~ *old dh* *.csr *.key *.crt *.p12 *.pub *.der *.key.der *.pub.der *.rsa.pub *.ssh.pub *.pem ca-chain.pem *index.txt* *serial* *\.0 *\.1
#	Make file to be installed in /etc/raddb/certs to enable

.PHONY: install install-cert install-key install-ca
install:	install-cert install-key install-ca

install-cert:	$(TARGET-CRT)
	$(INSTALL) -m 0644 -o root -g root $(TARGET-CRT) $(DESTCERTDIR)
	$(INSTALL) -m 0644 -o root -g root $(TARGET-CRT) $(DESTPKIDIR)

install-key:	$(TARGET-KEY)
	$(INSTALL) -m 0640 -o root -g ssl-cert $(TARGET-KEY) $(DESTKEYDIR)
	$(INSTALL) -m 0640 -o root -g ssl-cert $(TARGET-KEY) $(DESTPKIKEYDIR)

install-ca install-chain: $(TARGET-CA)
	$(MAKE) -C ../sub-ca install-chain
