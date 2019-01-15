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

srv		= srv
clt		= clt
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


source_dirs := . $(root) $(sub) $(srv) $(clt)
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
SOURCES := root-ca sub-ca srv clt 

VPATH := $(source_dirs)

$(SOURCES): 
	$(MAKE) -C $@

.PHONY: all # Make everything
all: $(SOURCES)

.PHONY: verify # Verify server and client certficates
verify: srv.vrfy clt.vrfy

.PHONY: pkcs11 # Put all certificates and keys to PKCS11 token
pkcs11: root.pkcs11 sub.pkcs11 srv.pkcs11 clt.pkcs11

.PHONY: crl # make Root CA and Sub CA certficate revokation lists (CRL)
crl:	root.crl sub.crl

.PHONY: clean-pkcs11 # Clean PKCS11 token (be careful!)
clean-pkcs11: 
	$(PKCS11TOOL) --init-token --label "Arest ruToken" --so-pin $(PKCS11MASTERPIN)
	$(PKCS11TOOL) --init-pin --login --pin $(PKCS11PIN) --so-pin $(PKCS11MASTERPIN)
	$(PKCS15TOOL) --erase-card -p rutoken_ecp -l "Arest ruToken" 
	$(PKCS15TOOL) --create-pkcs15 --so-pin $(PKCS11MASTERPIN) --so-puk ""
	$(PKCS15TOOL) --store-pin --label "User PIN" --auth-id 02 --pin $(PKCS11PIN) --puk "" --so-pin $(PKCS11MASTERPIN) --finalize

passwords.mk: root-ca.cnf sub-ca.cnf srv.cnf clt.cnf 
# inner-$(SRVCNF)
	@echo "PASSWORD_SERVER	= '$(shell grep output_password srv.cnf | sed 's/.*=//;s/^ *//')'"		> $@
#	@echo "PASSWORD_INNER	= '$(shell grep output_password inner-srv.cnf | sed 's/.*=//;s/^ *//')'"	>> $@
	@echo "PASSWORD_ROOT_CA	= '$(shell grep output_password root-ca.cnf | sed 's/.*=//;s/^ *//')'"		>> $@
	@echo "PASSWORD_SUB_CA	= '$(shell grep output_password sub-ca.cnf | sed 's/.*=//;s/^ *//')'"		>> $@
	@echo "PASSWORD_CLIENT	= '$(shell grep output_password clt.cnf | sed 's/.*=//;s/^ *//')'"		>> $@
	@echo "USER_NAME	= '$(shell grep emailAddress clt.cnf | grep '@' | sed 's/.*=//;s/^ *//')'"	>> $@
	@echo "ROOT_CA_DEFAULT_DAYS  = '$(shell grep default_days root-ca.cnf | sed 's/.*=//;s/^ *//')'"			>> $@
	@echo "SUB_CA_DEFAULT_DAYS  = '$(shell grep default_days sub-ca.cnf | sed 's/.*=//;s/^ *//')'"			>> $@

######################################################################
#
#  Diffie-Hellman parameters
#
######################################################################
dh:
	$(OPENSSL) dhparam -out dh.pem -2 $(DH_KEY_SIZE)

######################################################################
#
#  Make root-ca dir
#
######################################################################
######################################################################
#
#  Create a new self-signed CA certificate
#
######################################################################
.PHONY: help # Generate list of targets with descriptions                                                                
help:                                                                                                                    
	@grep '^.PHONY: .* #' Makefile | sed 's/\.PHONY: \(.*\) # \(.*\)/\1 \2/' | expand -t20

#.PHONY: list
#list:	
# search all include files for targets.
# ... excluding special targets, and output dynamic rule definitions unresolved.
#	@for inc in $(MAKEFILE_LIST); do 
#    		@echo ' =' $$inc '= ' 
#		@grep -Eo '^[^\.#[:blank:]]+.*:.*' $$inc | grep -v ':=' | cut -f 1 | sort | sed 's/.*/  &/' | sed -n 's/:.*$$//p' | tr $$ \\\ | tr $(open_paren) % | tr $(close_paren) % 
#	@done
#
# to get around escaping limitations:
#open_paren := \(
#close_paren := \)
clean:
	@for p in root-ca sub-ca srv clt; do \
		for ex in ~ old csr key crt p12 pub der key.der pub.der rsa.pub ssh.pub pem 0 1 serial* index*; do \
			rm -f $$p/*$$ex ;\
		done ; \
	done

