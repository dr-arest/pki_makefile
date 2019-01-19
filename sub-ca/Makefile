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
sub-ca		= sub-ca
BASE		= 
PKCS11PIN	= 3128443
PKCS11MASTERPIN	= Perekatipole
PKCS11_MODULE = /usr/lib/librtpkcs11ecp.so
#PKCS11_MODULE = /usr/lib/libeTPkcs11.so
SUBPASS		= PerekatipoleSubJOZEPH
ROOTPASS	= PerekatipoleRootJOZEPH
SAN="DNS:arest-home.pp.ua,DNS:*.arest-home.pp.ua,DNS:arest-home.loc,DNS:*.arest-home.loc,IP:193.93.219.55,IP:192.168.51.65,IP:192.168.51.70"

TARGET-CERT	= sub-ca.crt sub-ca.der
TARGET-KEY	= sub-ca.key
TARGET-CHAIN	= sub-ca-chain.pem
TARGET-CRL	= sub-ca.crl
TARGET-CRT	= $(TARGET-CERT) $(TARGET-CHAIN) $(TARGET-CRL)

DESTCERTDIR	= /etc/ssl 
DESTWWWDIR	= /etc/apache2/ssl 
DESTPKIDIR	= /var/www/pki
DESTKEYDIR	= /etc/ssl/private
EXPECTHELPER	= expect /etc/ssl/build_link.expect
INSTALL		= install 

source_dirs = . ./root-ca
DH_KEY_SIZE	= 2048
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
VPATH	= ..\sub-ca:..\root-ca
######################################################################
#
#
######################################################################
.PHONY: all # Make everything
all: sub-ca

.PHONY: sub-ca # Make Sub CA infrastructure
sub-ca: index.txt serial sub-ca.der sub-ca.key.der sub-ca.pub.der sub-ca-chain.pem sub-ca.ssh.pub

.PHONY: crl # make Root CA and Sub CA certficate revokation lists (CRL)
crl:	sub-ca.crl

.PHONY: revoke # Verify server and client certficates
revoke: sub-ca.revoke

.PHONY: clean-pkcs11 # Clean PKCS11 token (be careful!)
clean-pkcs11: 
	@$(PKCS11TOOL) --init-token --label "Arest ruToken" --so-pin $(PKCS11MASTERPIN)
	@$(PKCS11TOOL) --init-pin --login --pin $(PKCS11PIN) --so-pin $(PKCS11MASTERPIN)
	@$(PKCS15TOOL) --erase-card -p rutoken_ecp -l "Arest ruToken" 
	@$(PKCS15TOOL) --create-pkcs15 --so-pin $(PKCS11MASTERPIN) --so-puk ""
	@$(PKCS15TOOL) --store-pin --label "User PIN" --auth-id 02 --pin $(PKCS11PIN) --puk "" --so-pin $(PKCS11MASTERPIN) --finalize

passwords.mk:
	@echo "PASSWORD_ROOT_CA	= '$(shell grep output_password $(root).cnf | sed 's/.*=//;s/^ *//')'"		>> $@
	@echo "PASSWORD_SUB_CA	= '$(shell grep output_password sub-ca.cnf | sed 's/.*=//;s/^ *//')'"		>> $@
	@echo "SUB_CA_DEFAULT_DAYS  = '$(shell grep default_days sub-ca.cnf | sed 's/.*=//;s/^ *//')'"			>> $@

######################################################################
#
#  Diffie-Hellman parameters
#
######################################################################
dh:
	$(OPENSSL) dhparam -out $@.pem -2 $(DH_KEY_SIZE)

######################################################################
#
#  Create a new Sub CA certificate
#
######################################################################

sub-ca.csr sub-ca.key: sub-ca.cnf

	@[ -f serial ] || $(MAKE) serial
	@$(OPENSSL) req -new -keyout sub-ca.key -out sub-ca.csr \
		-days $(SUB_CA_DEFAULT_DAYS) -config sub-ca.cnf
	@chmod g+r sub-ca.key

sub-ca.crt: $(root).crt $(root).key sub-ca.csr sub-ca.key
	@$(OPENSSL) ca -batch -keyfile $(root).key -cert $(root).crt -in sub-ca.csr  -passin pass:$(ROOTPASS) -out sub-ca.crt -config $(root).cnf  -extensions v3_req      #   xpca_ext -extfile xpextensions
	@mv sub-ca.crt sub-ca.crt.text
	@$(OPENSSL) x509 -in sub-ca.crt.text -out sub-ca.crt
	@rm sub-ca.crt.text


sub-ca-chain.pem: $(root).crt sub-ca.crt
	@cat $? > $@

sub-ca.der: sub-ca.crt
	$(OPENSSL) x509 -inform PEM -outform DER -in $? -out $@

sub-ca.key.der: sub-ca.key
	$(EXPECTHELPER) sub-ca key.der
#	$(OPENSSL) rsa -inform PEM -outform DER -in $< -out $@

sub-ca.pub: sub-ca.key
	$(EXPECTHELPER) sub-ca pub
#	$(OPENSSL) rsa -pubout -in $< -out $@

sub-ca.pub.der:	sub-ca.pub
	$(OPENSSL) rsa -pubin -in $? -pubout -outform DER -out $@

sub-ca.rsa.pub: sub-ca.key
	$(EXPECTHELPER) sub-ca rsa.pub
#	$(OPENSSL) rsa -RSAPublicKey_out -in $< -out $@

sub-ca.ssh.pub: sub-ca.pub
	$(SSHKEYGEN) -i -f $? -m PKCS8 > $@

.PHONY: sub-ca.pkcs11 # Put Sub CA certificate and key to PKCS11 token
sub-ca.pkcs11:	sub-ca.der sub-ca.key.der sub-ca.pub.der
	@$(PKCS11TOOL) -y cert -w sub-ca.der --label "Arest Sub CA Certificate" --attr-from sub-ca.der --pin $(PKCS11$PIN) -l
	@$(PKCS11TOOL) -y privkey -w sub-ca.key.der --label "Arest Sub CA Private Key" --attr-from sub-ca.der --pin $(PKCS11PIN) -l
	@$(PKCS11TOOL) -y pubkey -w sub-ca.pub.der --label "Arest Sub CA Public Key" --attr-from sub-ca.der --pin $(PKCS11PIN) -l
	
.PHONY: sub-ca.crl # Make Sub CA certifcate revokation list (CRL)
sub-ca.crl:
	@$(OPENSSL) ca -gencrl -out $@ -passin pass:$(PASSWORD_SUB_CA) -config sub-ca.cnf
	
.PHONY: sub-ca.revoke # Verify client certifcate using ca-chain.pem
sub-ca.revoke: $(root).key sub-ca.crt
	@$(OPENSSL) ca -revoke sub-ca.crt -crl_reason superseded -config $(root).cnf

index.txt:
	@touch index.txt

serial:
	@echo '01' > serial

print:
	$(OPENSSL) x509 -text -in sub-ca.crt

printca:
	$(OPENSSL) x509 -text -in $(root).crt

printssh:
	$(PKCS15TOOL)

#
#	Make a target that people won't run too often.
#

.PHONY: help # Generate list of targets with descriptions                                                                
help:                                                                                                                    
	@grep '^.PHONY: .* #' Makefile | sed 's/\.PHONY: \(.*\) # \(.*\)/\1 \2/' | expand -t20

clean:
	@rm -f *~ *old dh* *.csr *.key *.crt *.p12 *.pub *.der *.key.der *.pub.der *.rsa.pub *.ssh.pub *.pem *.crl sub-ca-chain.pem *index.txt* *serial* *\.0 *\.1
#	Make file to be installed in /etc/raddb/certs to enable

.PHONY: install install-cert install-key
install:	install-cert install-key

install-cert:	$(TARGET-CRT)
	$(INSTALL) -m 0644 -o root -g root -t $(DESTCERTDIR) $(TARGET-CRT)
	$(INSTALL) -m 0644 -o root -g root -t $(DESTWWWDIR) $(TARGET-CRT)
	$(INSTALL) -m 0644 -o root -g root -t $(DESTPKIDIR) $(TARGET-CRT)
install-key:	$(TARGET-KEY)
	$(INSTALL) -m 0640 -o root -g ssl-cert $(TARGET-KEY) $(DESTKEYDIR)
install-chain:	$(TARGET-CHAIN)
	$(INSTALL) -m 0644 -o root -g root $(TARGET-CHAIN) $(DESTCERTDIR)
