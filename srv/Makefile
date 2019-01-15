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
BASE		= 
PKCS11PIN	= 3128443
PKCS11MASTERPIN	= Perekatipole
PKCS11_MODULE = /usr/lib/librtpkcs11ecp.so
#PKCS11_MODULE = /usr/lib/libeTPkcs11.so
SUBPASS		= PerekatipoleSub
ROOTPASS	= PerekatipoleRoot
SAN="DNS:arest-home.pp.ua,DNS:*.arest-home.pp.ua,DNS:arest-home.loc,DNS:*.arest-home.loc,IP:193.93.219.55,IP:192.168.51.65,IP:192.168.51.70"


source_dirs = . ../root-ca ../sub-ca
DH_KEY_SIZE	= 512
OPENSSL		= openssl
PKCS11TOOL	= pkcs11-tool --module $(PKCS11_MODULE)
PKCS15TOOL	= pkcs15-init
SSHKEYGEN	= ssh-keygen
EXTERNAL_CA	= $(wildcard external_ca.*)

ifneq "$(EXTERNAL_CA)" ""
PARTIAL		= -partial_chain
endif

##
##  Set the passwords
#
include passwords.mk

######################################################################
#
#
######################################################################
.PHONY: all # Make everything
all: srv.p12 srv.ssh.pub

.PHONY: srv # Make Sub CA infrastructure
srv: srv.der srv.key.der srv.pub.der srv.ssh.pub srv.vrfy

.PHONY: verify # Verify server and client certficates
verify: srv.vrfy

.PHONY: revoke # Verify server and client certficates
revoke: srv.revoke

.PHONY: clean-pkcs11 # Clean PKCS11 token (be careful!)
clean-pkcs11: 
	$(PKCS11TOOL) --init-token --label "Arest ruToken" --so-pin $(PKCS11MASTERPIN)
	$(PKCS11TOOL) --init-pin --login --pin $(PKCS11PIN) --so-pin $(PKCS11MASTERPIN)
	$(PKCS15TOOL) --erase-card -p rutoken_ecp -l "Arest ruToken" 
	$(PKCS15TOOL) --create-pkcs15 --so-pin $(PKCS11MASTERPIN) --so-puk ""
	$(PKCS15TOOL) --store-pin --label "User PIN" --auth-id 02 --pin $(PKCS11PIN) --puk "" --so-pin $(PKCS11MASTERPIN) --finalize

passwords.mk:
	@echo "PASSWORD_ROOT_CA	= '$(shell grep output_password $(root).cnf | sed 's/.*=//;s/^ *//')'"		>> $@
	@echo "PASSWORD_SUB_CA	= '$(shell grep output_password $(sub).cnf | sed 's/.*=//;s/^ *//')'"		>> $@
	@echo "PASSWORD_SERVER	= '$(shell grep output_password srv.cnf | sed 's/.*=//;s/^ *//')'"		> $@

######################################################################
#
#  Create a new Sub CA certificate
#
######################################################################

srv.csr srv.key: srv.cnf
	$(OPENSSL) req -new -keyout srv.key -out srv.csr \
		-days 730 -config srv.cnf
	chmod g+r srv.key

srv.crt: $(sub).crt $(sub).key srv.csr srv.key
	$(OPENSSL) ca -batch -keyfile $(sub).key -cert $(sub).crt -in srv.csr  -passin pass:$(SUBPASS) -out srv.crt -config $(sub).cnf

srv.der: srv.crt
	$(OPENSSL) x509 -inform PEM -outform DER -in $< -out $@

srv.key.der: srv.key
	$(OPENSSL) rsa -inform PEM -outform DER -in $< -out $@

srv.pub: srv.key
	$(OPENSSL) rsa -pubout -in $< -out $@

srv.pub.der:	srv.pub
	$(OPENSSL) rsa -pubin -in $< -pubout -outform DER -out $@

srv.rsa.pub: srv.key
	$(OPENSSL) rsa -RSAPublicKey_out -in $< -out $@

srv.ssh.pub: srv.pub
	$(SSHKEYGEN) -i -f $< -m PKCS8 > $@

srv.p12: srv.crt srv.key
	$(OPENSSL) pkcs12 -export -in srv.crt -inkey srv.key -out srv.p12 -passin pass:$(PASSWORD_SERVER) -passout pass:$(PASSWORD_SERVER)
	chmod g+r srv.p12

srv.pem: srv.p12
	$(OPENSSL) pkcs12 -in srv.p12 -out srv.pem -passin pass:$(PASSWORD_SERVER) -passout pass:$(PASSWORD_SERVER)

.PHONY: srv.pkcs11 # Put Sub CA certificate and key to PKCS11 token
srv.pkcs11:	srv.der srv.key.der srv.pub.der
	$(PKCS11TOOL) -y cert -w srv.der --label "Arest Sub CA Certificate" --attr-from srv.der --pin $(PKCS11$PIN) -l
	$(PKCS11TOOL) -y privkey -w srv.key.der --label "Arest Sub CA Private Key" --attr-from srv.der --pin $(PKCS11PIN) -l
	$(PKCS11TOOL) -y pubkey -w srv.pub.der --label "Arest Sub CA Public Key" --attr-from srv.der --pin $(PKCS11PIN) -l
	
.PHONY: srv.vrfy # Verify server certificate using ca-chain.pem file
srv.vrfy: $(sub)-chain.pem srv.crt
	@$(OPENSSL) verify $(PARTIAL) -CAfile $(sub)-ca-chain.pem srv.crt

.PHONY: srv.revoke # Verify client certifcate using ca-chain.pem
srv.revoke: $(sub).key srv.crt
	$(OPENSSL) ca -revoke srv.crt -crl_reason superseded -config $(sub).cnf

print:
	$(OPENSSL) x509 -text -in srv.crt

printca:
	$(OPENSSL) x509 -text -in $(sub).crt

printssh:
	$(PKCS15TOOL)

clean:
	rm -rf *~ dh *.csr *.crt *.p12 *.der *.pem *.key *.pub ca-chain.pem *index.txt* *serial*

#
#	Make a target that people won't run too often.
#

.PHONY: help # Generate list of targets with descriptions                                                                
help:                                                                                                                    
	@grep '^.PHONY: .* #' Makefile | sed 's/\.PHONY: \(.*\) # \(.*\)/\1 \2/' | expand -t20

