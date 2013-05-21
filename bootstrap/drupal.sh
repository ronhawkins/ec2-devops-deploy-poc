#!/bin/bash
# 
# This bootstrap script uses puppet to setup a
#  LAMP platform appropriate for Drupal
#
# assumes the following bash vars are defined:
#
#  - PUPPET_REPO_URL
#  - PUPPET_REPO_BRANCH
#
#  - DRUPAL_REPO_URL
#  - DRUPAL_REPO_BRANCH
#  - APP_REPO_URL=
#  - APP_REPO_BRANCH
#
#  - EXTRA_PKGS (optional)

#---------------------------------
#  Build and configure PLATFORM
#---------------------------------

#
# Install basics to bootstrap this process
#
export PATH="${PATH}:/usr/local/bin"
PKGS="puppet git curl ${EXTRA_PKGS}"
yum -y install ${PKGS}
cp -a /etc/system-release /etc/redhat-release # to convince puppet we're a RHEL derivative

#
# pull, setup and run puppet manifests
#
cd /tmp 
PUPPET_REPO_BRANCH=${PUPPET_REPO_BRANCH:-master}
git clone --branch ${PUPPET_REPO_BRANCH} ${PUPPET_REPO_URL}
PUPPET_DIR=$( echo ${PUPPET_REPO_URL} | awk -F/ '{print $NF}' | sed 's/\.git//' )
cd $PUPPET_DIR
git submodule sync 
git submodule update --init  

puppet apply ./manifests/site.pp --modulepath=./modules

#--------------------------------------------
#
#  Build and configure APPLICATION
#
#--------------------------------------------

#
# Drupal first
#
cd /var/www
DRUPAL_REPO_BRANCH=${DRUPAL_REPO_BRANCH:-master}
git clone --branch ${DRUPAL_REPO_BRANCH} ${DRUPAL_REPO_URL}
DRUPAL_DIR=$( echo ${DRUPAL_REPO_URL} | awk -F/ '{print $NF}' | sed 's/\.git//' )
ln -s $DRUPAL_DIR drupal
cd /var/www/drupal

drush si standard \
 --db-url=mysql://drupal:drupal@localhost/drupal \
 --db-su=root \
 --db-su-pw=password \
 --site-name="Drupal Dev Site" \
 -y

drush dl blazemeter -y && drush en blazemeter -y
chmod 777 /var/www/drupal/sites/default/files -R


#
# App next
#


#--------------------------------------------
#
#  Test APPLICATION
#
#--------------------------------------------

