# == Class: ckan
#
# Installs, configures, and manages ckan.
# Install Details: http://docs.ckan.org/en/ckan-2.0/install-from-package.html
#
# Additional features:
# * Database is backed up once a week to /backup/ckan_database.pg_dump.
#
# === Parameters
#
# [*site_url*] The url for the ckan site.
# [*param site_title*] The title of the web site.
# [*site_description*] The description (found in header) of the web site.
# [*site_intro*] The introduction on the landing page.
# [*site_about*] Information on the about page.
# [*plugins*] Contains the ckan plugins to be used by the installation.
# [*site_logo*] The source of the logo.  Should be spedified as
#               puppet:///<your module>/<image>.png
#               Note, should be a png file.
# [*license*] the source to the json license file.  Should be specified as
#             puppet:///<your module>/<license file> and maintained by your module
# [*is_ckan_from_repo*] A boolean to indicate if the ckan package should be
#                       installed through an already configured repository
#                       setup outside of this module. If using Ubuntu/Deb
#                       should be able to do "apt-get install python-ckan"
#                       Its the same idea for yum and other package managers.
# [*ckan_package_url*] If not using a repo, then this url needs to be
#                      specified with the location to download the package.
#                      Note, this is using dpkg so deb/ubuntu only.
# [*ckan_package_filename*] The filename of the ckan package.
# [*custom_css*] The source to a css file used for the ckan site.  This replaces
#                the default main.css.  Should be specified as
#                puppet:///<your module>/<css filename> and maintained by your module.
#                Note, images used in the custom css should be set in custom_imgs.
# [*custom_imgs*] An array of source for the images to be used by the css.
#                 Should be specified as
#                 ['puppet:///<your module>/<img1>','...']
# [*serveradmin*] The admin's email address used in the apache configuration.
# [*recaptcha_publickey*] The public key for recaptcha (by default not set).
# [*recaptcha_privatekey*] The private key for recaptcha (by default not set).
# [*max_resource_size*] The maximum in megabytes a resource upload can be.
# [*datapusher_formats*] File formats that will be pushed to the DataStore by the DataPusher.  
#                        When adding or editing a resource which links to a file in one of these formats, the DataPusher
#                        will automatically try to import its contents to the DataStore.
# [*preview_loadable*] Defines the resource formats which should be loaded directly in an iframe tag when previewing 
#                      them if no Data Viewer can preview it. 
# [*text_formats*] Formats used for the text preview
# [*apache_headers*] Sets the apache headers so to control search engine crawls and etc.
# [*postgres_pass*] The password for the postgres user of the database (admin user).
# [*pg_hba_conf_defaults*] True if use the default hbas and false to configure your own.
#  This module uses postgresql so this setting informs the postgresql module
#  that the hba's should be handled outside of this module.  Requires your own hba configuration.
#
# === Examples
#
#class { 'ckan':
#  site_url              => 'test.ckan.com',
#  site_title            => 'CKAN Test',
#  site_description      => 'A shared environment for managing Data.',
#  site_intro            => 'A CKAN test installation',
#  site_about            => 'Pilot data catalogue and repository.',
#  plugins               => 'stats text_preview recline_preview datastore resource_proxy pdf_preview',
#  is_ckan_from_repo     => 'false',
#  ckan_package_url      => 'http://packaging.ckan.org/python-ckan_2.1_amd64.deb',
#  ckan_package_filename => 'python-ckan_2.1_amd64.deb',
#}
#
# === Authors
#
# Michael Speth <spethm@landcareresearch.co.nz>
#
# === Copyright
# GPLv3
#
class ckan (
  $site_url,
  $site_title,
  $site_description,
  $site_intro,
  $site_about,
  $plugins,
  $site_logo = '',
  $license = '',
  $is_ckan_from_repo = true,
  $ckan_package_url = '',
  $ckan_package_filename = '',
  $custom_css = 'main.css',
  $custom_imgs = '',
  $do_reset_apt = true,
  $serveradmin = 'webmaster@localhost',
  $recaptcha_publickey = '',
  $recaptcha_privatekey = '',
  $max_resource_size = 100,
  $datapusher_formats = 'csv xls application/csv application/vnd.ms-excel',
  $preview_loadable = 'html htm rdf+xml owl+xml xml n3 n-triples turtle plain atom csv tsv rss txt json',
  $text_formats = '',
  $apache_headers = '',
  $postgres_pass = pass,
  $pg_hba_conf_defaults = true,
){
  # Check supported operating systems
  if $osfamily != 'debian' {
    fail("Unsupported OS $osfamily.  Please use a debian based system") 
  }
  
  File {
    owner => root,
    group => root,
  }
  
  # == Variables == #
  $ckan_package_dir = '/usr/local/ckan'

  # == stages == #
  stage {'first':
    before => Stage['main'],
  }

  # == first == #
  class { 'ckan::repos':
    stage   => first,
  }

  # == main stage ==

  class { 'ckan::install': }
  class { 'ckan::db_config':
    require => Class['ckan::install'],
  }
  class { 'ckan::config' :
    site_url         => $ckan::site_url,
    site_title       => $ckan::site_title,
    site_description => $ckan::site_description,
    site_intro       => $ckan::site_intro,
    site_about       => $ckan::site_about,
    site_logo        => $ckan::site_logo,
    plugins          => $ckan::plugins,
    require          => Class['ckan::db_config'],
  }
  class { 'ckan::service' :
    require => Class['ckan::config'],
  }
}