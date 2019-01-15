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

srv		= arest-home.pp.ua
clt		= arest@arest-home.pp.ua
root		= root-ca
sub		= sub-ca
BASE		= 
PKCS11PIN	= 3128443
PKCS11MASTERPIN	= Perekatipole
PKCS11_MODULE = /usr/lib/librtpkcs11ecp.so
#PKCS11_MODULE = /usr/lib/libeTPkcs11.so
SUBPASS		= PerekatipoleSub
ROOTPASS	= PerekatipoleRoot
SAN="DNS:arest-home.pp.ua,DNS:*.arest-home.pp.ua,DNS:arest-home.loc,DNS:*.arest-home.loc,IP:193.93.219.55,IP:192.168.51.65,IP:192.168.51.70"


source_dirs = . root-ca $(sub)
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
#  Make the necessary files, but not clt certificates.
#
######################################################################
.PHONY: all # Make everything
all: root-ca dh

.PHONY: root-ca	# Make Root CA infrastructure
root-ca: root.index.txt root.serial root-ca.der root-ca.key.der root-ca.pub.der

.PHONY: $(sub) # Make Sub CA infrastructure
$(sub): sub.index.txt sub.serial root-ca $(sub).der $(sub).pub.der ca-chain.pem $(sub).ssh.pub

.PHONY: $(srv) # Make server certificate and key
$(srv): $(sub) $(srv).pem $(srv).ssh.pub $(srv).p12 $(srv).vrfy

.PHONY: $(clt) # Make client certificate and key
$(clt): $(clt).pem $(clt).ssh.pub $(clt).p12

.PHONY: verify # Verify server and client certficates
verify: $(srv).vrfy $(clt).vrfy

.PHONY: pkcs11 # Put all certificates and keys to PKCS11 token
pkcs11: root-ca.pkcs11 $(sub).pkcs11 $(srv).pkcs11 $(clt).pkcs11

.PHONY: crl # make Root CA and Sub CA certficate revokation lists (CRL)
crl:	root-ca.crl $(sub).crl

.PHONY: clean-pkcs11 # Clean PKCS11 token (be careful!)
clean-pkcs11: 
	$(PKCS11TOOL) --init-token --label "Arest ruToken" --so-pin $(PKCS11MASTERPIN)
	$(PKCS11TOOL) --init-pin --login --pin $(PKCS11PIN) --so-pin $(PKCS11MASTERPIN)
	$(PKCS15TOOL) --erase-card -p rutoken_ecp -l "Arest ruToken" 
	$(PKCS15TOOL) --create-pkcs15 --so-pin $(PKCS11MASTERPIN) --so-puk ""
	$(PKCS15TOOL) --store-pin --label "User PIN" --auth-id 02 --pin $(PKCS11PIN) --puk "" --so-pin $(PKCS11MASTERPIN) --finalize

passwords.mk: root-ca.cnf 
# inner-$(SRVCNF)
	@echo "PASSWORD_ROOT_CA	= '$(shell grep output_password root-ca.cnf | sed 's/.*=//;s/^ *//')'"		>> $@
	@echo "ROOT_CA_DEFAULT_DAYS  = '$(shell grep default_days root-ca.cnf | sed 's/.*=//;s/^ *//')'"			>> $@

######################################################################
#
#  Diffie-Hellman parameters
#
######################################################################
dh:
	$(OPENSSL) dhparam -out dh.pem -2 $(DH_KEY_SIZE)

######################################################################
#
#  Create a new self-signed CA certificate
#
######################################################################
root-ca.key root-ca.crt: root-ca.cnf
	@[ -f index.txt ] || $(MAKE) index.txt
	@[ -f serial ] || $(MAKE) serial
	$(OPENSSL) req -new -x509 -keyout root-ca.key -out root-ca.crt \
		-days $(ROOT_CA_DEFAULT_DAYS) -config root-ca.cnf
	chmod g+r root-ca.key
	mv root-ca.crt root-ca.crt.text
	$(OPENSSL) x509 -in root-ca.crt.text -out root-ca.crt
	rm root-ca.crt.text

root-ca.der: root-ca.crt
	$(OPENSSL) x509 -inform PEM -outform DER -in root-ca.crt -out root-ca.der

root-ca.key.der: root-ca.key
	$(OPENSSL) rsa -inform PEM -outform DER -in root-ca.key -out root-ca.key.der

root-ca.pub:
	$(OPENSSL) rsa -pubout -in root-ca.key -out root-ca.pub

root-ca.pub.der: root-ca.pub
	$(OPENSSL) rsa -pubin -in root-ca.pub -pubout -outform DER -out root-ca.pub.der 

.PHONY: root-ca.pkcs11 # Put Root CA certificate and key to PKCS11 token
root-ca.pkcs11:	root-ca.der root-ca.key.der root-ca.pub.der
	$(PKCS11TOOL) -y cert -w root-ca.der --label "Arest Root CA Certificate" --attr-from root-ca.der --pin $(PKCS11PIN) -l
	$(PKCS11TOOL) -y privkey -w root-ca.key.der --label "Arest Root CA Private Key" --attr-from root-ca.der --pin $(PKCS11PIN) -l
	$(PKCS11TOOL) -y pubkey -w root-ca.pub.der --label "Arest Root CA Public Key" --attr-from root-ca.der --pin $(PKCS11PIN) -l

.PHONY: root-ca.crl # Make Root CA certficate revokation list (CRL)
root-ca.crl: root-ca.key
	$(OPENSSL) gencrl -out root-ca.crl
	
######################################################################
#
#  Miscellaneous rules.
#
######################################################################
root.index.txt:
	@touch index.txt

root.serial:
	@echo '01' > serial

sub.index.txt:
	@touch index.txt

sub.serial:
	@echo '01' > serial

print:
	$(OPENSSL) x509 -text -in root-ca.crt

printca:
	$(OPENSSL) x509 -text -in root-ca.crt

printssh:
	$(PKCS15TOOL)

clean:
	@rm -f *~ *old dh* *.csr *.key *.crt *.p12 *.pub *.der *.key.der *.pub.der *.rsa.pub *.ssh.pub *.pem ca-chain.pem *index.txt* *serial* *\.0 *\.1

#
#	Make a target that people won't run too often.
#
.PHONY: help # Generate list of targets with descriptions                                                                
help:                                                                                                                    
	@grep '^.PHONY: .* #' Makefile | sed 's/\.PHONY: \(.*\) # \(.*\)/\1 \2/' | expand -t20

