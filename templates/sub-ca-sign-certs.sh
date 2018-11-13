#!/bin/bash
# echo `date` 'Hey! Someone touched your stuff!' >> /var/log/sub-ca-sign-certs.log

#REQUESTS='/srv/nfs/Certificates/Requests'
REQUESTS='<%= @certs_requests %>'
SERVER='<%= @certs_server %>'
CLIENT='<%= @certs_client %>'
SUBCACONF='<%= @sub_ca_conf %>'
OPENSSLCMD=<%= @openssl_cmd %>

CERTS='<%= @certs_certs %>'
CRT='crt'

for csrfile in `/usr/bin/ls ${REQUESTS}/*.csr`; do

#  echo "Request File = $csrfile" >> /var/log/sub-ca-sign-certs.log

  CSRFILE=`basename $csrfile`
#  echo "CSR File = $CSRFILE" >> /var/log/sub-ca-sign-certs.log

  CRTFILE=${CSRFILE%'csr'}${CRT}
#  echo "CRT File = ${CERTS}/$CRTFILE" >> /var/log/sub-ca-sign-certs.log

#echo "${OPENSSLCMD} ca -config ${SUBCACONF} -batch -in ${csrfile} -out ${CERTS}/${CRTFILE} -extensions server_ext" >> /var/log/sub-ca-sign-certs.log
  ${OPENSSLCMD} ca -config ${SUBCACONF} -batch -in ${csrfile} -out ${CERTS}/${CRTFILE} -extensions server_ext

  /usr/bin/mv -f $csrfile $SERVER/old


done

for csrfile in `/usr/bin/ls ${SERVER}/*.csr`; do

#  echo "Request File = $csrfile" >> /var/log/sub-ca-sign-certs.log

  CSRFILE=`basename $csrfile`
#  echo "CSR File = $CSRFILE" >> /var/log/sub-ca-sign-certs.log

  CRTFILE=${CSRFILE%'csr'}${CRT}
#  echo "CRT File = ${CERTS}/$CRTFILE" >> /var/log/sub-ca-sign-certs.log

  ${OPENSSLCMD} ca -config ${SUBCACONF} -batch -in ${csrfile} -out ${CERTS}/${CRTFILE} -extensions server_ext

  /usr/bin/mv -f $csrfile $SERVER/old

done

for csrfile in `/usr/bin/ls ${CLIENT}/*.csr`; do

#  echo "Request File = $csrfile" >> /var/log/sub-ca-sign-certs.log

  CSRFILE=`basename $csrfile`
#  echo "CSR File = $CSRFILE" >> /var/log/sub-ca-sign-certs.log

  CRTFILE=${CSRFILE%'csr'}${CRT}
#  echo "CRT File = ${CERTS}/$CRTFILE" >> /var/log/sub-ca-sign-certs.log

  ${OPENSSLCMD} ca -config ${SUBCACONF} -batch -in ${csrfile} -out ${CERTS}/${CRTFILE} -extensions client_ext

  /usr/bin/mv -f $csrfile $CLIENT/old

done



# /srv/nfs/Certificates/Requests



# penssl ca -config /opt/sub-ca/sub-ca.conf -batch -in /mnt/Certificates/Requests/tele-vm-mike6.telephony.local.csr -out /mnt/Certificates/Certificates/tele-vm-mike6.telephony.local.crt -extensions server_ext

