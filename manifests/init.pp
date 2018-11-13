# A description of what this class does
#
# @summary A short summary of the purpose of this class
#
# @example
#   include lab_ca
class lab_ca (

  Boolean $root_ocsp_service_enabled = false,
  Boolean $sub_ocsp_service_enabled  = false,
  Boolean $sub_sign_service_enabled  = false,

  String $root_ca_name           = 'root-ca',
  String $root_country_name      = 'CA',
  String $root_organization_name = 'MHA Ottawa',
  String $root_common_name       = 'Lab Root CA0',
  String $root_ocsp_subj         = "/C=CA/O=${root_organization_name}/CN=OCSP RootCA Responder",

  String $sub_ca_name           = 'sub-ca',
  String $sub_country_name      = 'CA',
  String $sub_organization_name = 'MHA Ottawa',
  String $sub_common_name       = 'Lab Sub CA0',
  String $sub_ocsp_subj         = "/C=CA/O=${root_organization_name}/CN=OCSP SubCA Responder"

) {

  $root_ca_dir         = "/opt/${root_ca_name}"
  $root_ca_dir_certs   = "${root_ca_dir}/certs"
  $root_ca_dir_db      = "${root_ca_dir}/db"
  $root_ca_dir_private = "${root_ca_dir}/private"
  $root_ca_conf_file   = 'root-ca.conf'
  $root_ca_conf        = "${root_ca_dir}/${root_ca_conf_file}"
  $root_ca_csr         = "${root_ca_dir}/root-ca.csr"
  $root_ca_crt         = "${root_ca_dir}/root-ca.crt"
  $root_ca_crl         = "${root_ca_dir}/root-ca.crl"
  $root_ca_key         = "${root_ca_dir_private}/root-ca.key"
  $root_ca_ocsp_csr    = "${root_ca_dir}/root-ca-ocsp.csr"
  $root_ca_ocsp_crt    = "${root_ca_dir}/root-ca-ocsp.crt"
  $root_ca_ocsp_key    = "${root_ca_dir_private}/root-ca-ocsp.key"

  $sub_ca_dir         = "/opt/${sub_ca_name}"
  $sub_ca_dir_certs   = "${sub_ca_dir}/certs"
  $sub_ca_dir_db      = "${sub_ca_dir}/db"
  $sub_ca_dir_private = "${sub_ca_dir}/private"
  $sub_ca_conf_file   = 'sub-ca.conf'
  $sub_ca_conf        = "${sub_ca_dir}/${sub_ca_conf_file}"
  $sub_ca_csr         = "${sub_ca_dir}/sub-ca.csr"
  $sub_ca_crt         = "${sub_ca_dir}/sub-ca.crt"
  $sub_ca_crl         = "${sub_ca_dir}/sub-ca.crl"
  $sub_ca_chain       = "${sub_ca_dir}/sub-ca-chain.crt"
  $sub_ca_key         = "${sub_ca_dir_private}/sub-ca.key"
  $sub_ca_ocsp_csr    = "${sub_ca_dir}/sub-ca-ocsp.csr"
  $sub_ca_ocsp_crt    = "${sub_ca_dir}/sub-ca-ocsp.crt"
  $sub_ca_ocsp_key    = "${sub_ca_dir_private}/sub-ca-ocsp.key"

# Client certificates are stored in a common directory.

  $certs_nfs        = '/srv/nfs'
  $certs_base       = "${certs_nfs}/Certificates"
  $certs_certs      = "${certs_base}/Certificates"
  $certs_keys       = "${certs_base}/Keys"
  $certs_requests   = "${certs_base}/Requests"
  $certs_server     = "${certs_base}/Requests/server"
  $certs_server_old = "${certs_base}/Requests/server/old"
  $certs_client     = "${certs_base}/Requests/client"
  $certs_client_old = "${certs_base}/Requests/client/old"

  $cert_tree = [
    $certs_nfs, $certs_base, $certs_certs, $certs_keys,  $certs_requests,
    $certs_server, $certs_server_old, $certs_client, $certs_client_old
  ]

  case $::osfamily {
    'RedHat': {
      $openssl_cmd = '/usr/bin/openssl'
      $openssl_dir = '/usr/bin'
      $cat_cmd     = '/usr/bin/cat'
    }
    default: {
      fail("${::hostname}: This module does not support operatingsystem ${::operatingsystem}")
    }
  }

  # Set up a Certificate Store.
  #
  # We NFS Export the $certs_base directories externel to this module.

  file { $cert_tree:
    ensure => directory,
    owner  => root,
    group  => root,
    mode   => '0600',
  }

  # Start with building a ROOT CA.
  # I will need to add a test to skip creating a RootCA if we have root ca certs etc.

  # Setup the default CA Root directory. (If needed.)
  file { $root_ca_dir:
    ensure => directory,
    owner  => root,
    group  => root,
    mode   => '0700',
  }

  file { $root_ca_dir_certs:
    ensure => directory,
    owner  => root,
    group  => root,
    mode   => '0700',
  }

  file { $root_ca_dir_db:
    ensure => directory,
    owner  => root,
    group  => root,
  }

  file { $root_ca_dir_private:
    ensure => directory,
    owner  => root,
    group  => root,
    mode   => '0700',
  }

  file { $root_ca_conf:
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => '0600',
    content => template("${module_name}/${root_ca_conf_file}.erb"),
    require => File[$root_ca_dir],
  }

  exec { 'Setup root index':
    command => "/usr/bin/touch ${root_ca_dir_db}/index",
#    onlyif  => "/usr/bin/test ! -f ${root_ca_dir_db}/index",
    creates => "${root_ca_dir_db}/index",
    require => File[$root_ca_dir_db],
  }

  exec { 'Setup root serial':
    command => "${openssl_cmd} rand -hex 16 > ${root_ca_dir_db}/serial",
#    onlyif  => "/usr/bin/test ! -f ${root_ca_dir_db}/serial",
    creates => "${root_ca_dir_db}/serial",
    require => File[$root_ca_dir_db],
  }

  exec { 'Setup root crlnumber':
    command => "/usr/bin/echo 1001 > ${root_ca_dir_db}/crlnumber",
#    onlyif  => "/usr/bin/test ! -f ${root_ca_dir_db}/crlnumber",
    creates => "${root_ca_dir_db}/crlnumber",
    require => File[$root_ca_dir_db],
  }

  exec { 'Setup root csr & key':
    command => "${openssl_cmd} req -new -config ${root_ca_conf} -out ${root_ca_csr} -keyout ${root_ca_key}",
    cwd     => $root_ca_dir,
#    onlyif  => "/usr/bin/test ! -f ${root_ca_csr}",
    creates => $root_ca_csr,
  }

  exec { 'Sign root cert':
    command => "${openssl_cmd} ca -selfsign -batch -config ${root_ca_conf} -in ${root_ca_csr} -out ${root_ca_crt} -extensions ca_ext",
    cwd     => $root_ca_dir,
#    onlyif  => "/usr/bin/test ! -f ${root_ca_crt}",
    creates => $root_ca_crt,
  }

  exec { 'Make initial Root CRL':
    command => "${openssl_cmd} ca -gencrl -config ${root_ca_conf} -out ${root_ca_crl}",
    cwd     => $root_ca_dir,
#    onlyif  => "/usr/bin/test ! -f ${root_ca_crl}",
    creates => $root_ca_crl,
  }

  exec { 'Setup root ocsp csr & key':
    command => @("END"/L),
      ${openssl_cmd} req -new -nodes -newkey rsa:2048 -subj "${root_ocsp_subj}" \
      -keyout ${root_ca_ocsp_key} -out ${root_ca_ocsp_csr}
      |-END
    cwd     => $root_ca_dir,
#    onlyif  => "/usr/bin/test ! -f ${root_ca_ocsp_key}",
    creates => $root_ca_ocsp_key,
  }

  exec { 'Sign root ocsp cert':
    command => @("END"/L),
      ${openssl_cmd} ca -config ${root_ca_conf} -batch -in ${root_ca_ocsp_csr} \
      -out ${root_ca_ocsp_crt} -extensions ocsp_ext -days 30
      |-END
    cwd     => $root_ca_dir,
#    onlyif  => "/usr/bin/test ! -f ${root_ca_ocsp_crt}",
    creates => $root_ca_ocsp_crt,
  }

  file { '/usr/lib/systemd/system/root-ca-ocsp.service':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template("${module_name}/root-ca-ocsp.service"),
  }

  if $root_ocsp_service_enabled == true {
    service {'root-ca-ocsp':
      ensure    => running,
      enable    => true,
      subscribe => File['/usr/lib/systemd/system/root-ca-ocsp.service'],
    }
  } else {
    service {'root-ca-ocsp':
      ensure => stopped,
      enable => false,
    }
  }


  # Setup the default Sub CA directory. (If needed.)
  file { $sub_ca_dir:
    ensure => directory,
    owner  => root,
    group  => root,
    mode   => '0700',
  }

  file { $sub_ca_dir_certs:
    ensure => directory,
    owner  => root,
    group  => root,
    mode   => '0700',
  }

  file { $sub_ca_dir_db:
    ensure => directory,
    owner  => root,
    group  => root,
  }

  file { $sub_ca_dir_private:
    ensure => directory,
    owner  => root,
    group  => root,
    mode   => '0700',
  }

  file { $sub_ca_conf:
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => '0600',
    content => template("${module_name}/${sub_ca_conf_file}.erb"),
    require => File[$sub_ca_dir],
  }

  exec { 'Setup sub index':
    command => "/usr/bin/touch ${sub_ca_dir_db}/index",
#    onlyif  => "/usr/bin/test ! -f ${sub_ca_dir_db}/index",
    creates => "${sub_ca_dir_db}/index",
    require => File[$sub_ca_dir_db],
  }

  exec { 'Setup sub serial':
    command => "${openssl_cmd} rand -hex 16 > ${sub_ca_dir_db}/serial",
#    onlyif  => "/usr/bin/test ! -f ${sub_ca_dir_db}/serial",
    creates => "${sub_ca_dir_db}/serial",
    require => File[$sub_ca_dir_db],
  }

  exec { 'Setup sub crlnumber':
    command => "/usr/bin/echo 1001 > ${sub_ca_dir_db}/crlnumber",
#    onlyif  => "/usr/bin/test ! -f ${sub_ca_dir_db}/crlnumber",
    creates => "${sub_ca_dir_db}/crlnumber",
    require => File[$sub_ca_dir_db],
  }

  exec { 'Setup sub csr & key':
    command => "${openssl_cmd} req -new -config ${sub_ca_conf} -out ${sub_ca_csr} -keyout ${sub_ca_key}",
    cwd     => $sub_ca_dir,
#    onlyif  => "/usr/bin/test ! -f ${sub_ca_csr}",
    creates => $sub_ca_csr,
  }

  exec { 'Sign sub cert':
    command => "${openssl_cmd} ca -batch -config ${root_ca_conf} -in ${sub_ca_csr} -out ${sub_ca_crt} -extensions sub_ca_ext",
    cwd     => $root_ca_dir,
#    onlyif  => "/usr/bin/test ! -f ${sub_ca_crt}",
    creates => $sub_ca_crt,
  }

  exec { 'Make Sub CA Chain':
    command => "${cat_cmd} ${sub_ca_crt} ${root_ca_crt} > ${sub_ca_chain}",
    cwd     => $sub_ca_dir,
#    onlyif  => "/usr/bin/test ! -f ${sub_ca_chain}",
    creates => $sub_ca_chain,
  }

  exec { 'Make initial Sub CRL':
    command => "${openssl_cmd} ca -gencrl -config ${sub_ca_conf} -out ${sub_ca_crl}",
    cwd     => $sub_ca_dir,
#    onlyif  => "/usr/bin/test ! -f ${sub_ca_crl}",
    creates => $sub_ca_crl,
  }

  exec { 'Setup sub ocsp csr & key':
    command => @("END"/L),
      ${openssl_cmd} req -new -nodes -newkey rsa:2048 -subj "${sub_ocsp_subj}" \
      -keyout ${sub_ca_ocsp_key}  -out ${sub_ca_ocsp_csr}
      |-END
    cwd     => $sub_ca_dir,
#    onlyif  => "/usr/bin/test ! -f ${sub_ca_ocsp_key}",
    creates => $sub_ca_ocsp_key,
  }

  exec { 'Sign sub ocsp cert':
    command => @("END"/L),
      ${openssl_cmd} ca -config ${sub_ca_conf} -batch -in ${sub_ca_ocsp_csr} \
      -out ${sub_ca_ocsp_crt} -extensions ocsp_ext -days 30
      |-END
    cwd     => $sub_ca_dir,
#    onlyif  => "/usr/bin/test ! -f ${sub_ca_ocsp_crt}",
    creates => $sub_ca_ocsp_crt,
  }

  file { '/usr/lib/systemd/system/sub-ca-ocsp.service':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template("${module_name}/sub-ca-ocsp.service"),
  }

  if $root_ocsp_service_enabled == true {
    service {'sub-ca-ocsp':
      ensure    => running,
      enable    => true,
      subscribe => File['/usr/lib/systemd/system/sub-ca-ocsp.service'],
    }
  } else {
    service {'sub-ca-ocsp':
      ensure => stopped,
      enable => false,
    }
  }

  file { '/usr/lib/systemd/system/sub-ca-sign-certs.service':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template("${module_name}/sub-ca-sign-certs.service"),
  }

  file { '/usr/lib/systemd/system/sub-ca-sign-certs.path':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template("${module_name}/sub-ca-sign-certs.path"),
  }

  file { '/usr/local/sbin/sub-ca-sign-certs.sh':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0744',
    content => template("${module_name}/sub-ca-sign-certs.sh"),
  }

  if $sub_sign_service_enabled == true {
    service {'sub-ca-sign-certs.path':
      ensure    => running,
      enable    => true,
      subscribe => [
        File['/usr/lib/systemd/system/sub-ca-sign-certs.path'],
        File['/usr/lib/systemd/system/sub-ca-sign-certs.service'],
        File['/usr/local/sbin/sub-ca-sign-certs.sh'],
      ],
    }
  } else {
    service {'sub-ca-sign-certs.path':
      ensure => stopped,
      enable => false,
    }
  }


}
