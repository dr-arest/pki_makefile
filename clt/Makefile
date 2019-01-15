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
all: clt.p12 clt.ssh.pub

.PHONY: clt # Make Sub CA infrastructure
clt: clt.der clt.key.der clt.pub.der clt.ssh.pub clt.vrfy

.PHONY: verify  # Verify server and client certficates
verify: clt.vrfy

.PHONY: revoke # Verify server and client certficates
revoke: clt.revoke

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
	@echo "PASSWORD_CLIENT	= '$(shell grep output_password clt.cnf | sed 's/.*=//;s/^ *//')'"		> $@

######################################################################
#
#  Create a new Sub CA certificate
#
######################################################################

clt.csr clt.key: clt.cnf
	$(OPENSSL) req -new -keyout clt.key -out clt.csr \
		-days 730 -config clt.cnf
	chmod g+r clt.key

clt.crt: $(sub).crt $(sub).key clt.csr clt.key
	$(OPENSSL) ca -batch -keyfile $(sub).key -cert $(sub).crt -in clt.csr  -passin pass:$(SUBPASS) -out clt.crt -config $(sub).cnf

clt.der: clt.crt
	$(OPENSSL) x509 -inform PEM -outform DER -in $< -out $@

clt.key.der: clt.key
	$(OPENSSL) rsa -inform PEM -outform DER -in $< -out $@

clt.pub: clt.key
	$(OPENSSL) rsa -pubout -in $< -out $@

clt.pub.der:	clt.pub
	$(OPENSSL) rsa -pubin -in $< -pubout -outform DER -out $@

clt.rsa.pub: clt.key
	$(OPENSSL) rsa -RSAPublicKey_out -in $< -out $@

clt.ssh.pub: clt.pub
	$(SSHKEYGEN) -i -f $< -m PKCS8 > $@

clt.p12: clt.crt clt.key
	$(OPENSSL) pkcs12 -export -in clt.crt -inkey clt.key -out clt.p12 -passin pass:$(PASSWORD_CLIENT) -passout pass:$(PASSWORD_CLIENT)
	chmod g+r clt.p12

clt.pem: clt.p12
	$(OPENSSL) pkcs12 -in clt.p12 -out clt.pem -passin pass:$(PASSWORD_CLIENT) -passout pass:$(PASSWORD_CLIENT)

.PHONY: clt.pkcs11 # Put Sub CA certificate and key to PKCS11 token
clt.pkcs11:	clt.der clt.key.der clt.pub.der
	$(PKCS11TOOL) -y cert -w clt.der --label "Arest Sub CA Certificate" --attr-from clt.der --pin $(PKCS11$PIN) -l
	$(PKCS11TOOL) -y privkey -w clt.key.der --label "Arest Sub CA Private Key" --attr-from clt.der --pin $(PKCS11PIN) -l
	$(PKCS11TOOL) -y pubkey -w clt.pub.der --label "Arest Sub CA Public Key" --attr-from clt.der --pin $(PKCS11PIN) -l
	
.PHONY: clt.vrfy # Verify client certifcate using ca-chain.pem
clt.vrfy: $(sub).crt clt.crt
	$(OPENSSL) verify -CAfile $(sub)-chain.pem clt.crt

.PHONY: clt.revoke # Verify client certifcate using ca-chain.pem
clt.revoke: $(sub).key clt.crt
	$(OPENSSL) ca -revoke clt.crt -crl_reason superseded -config $(sub).cnf

print:
	$(OPENSSL) x509 -text -in clt.crt

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
