#!/usr/bin/env bats
load test_helper

setup() {
  dokku "$PLUGIN_COMMAND_PREFIX:create" l >&2
  dokku apps:create my_app >&2
}

teardown() {
  dokku --force "$PLUGIN_COMMAND_PREFIX:destroy" l >&2
  rm "$DOKKU_ROOT/my_app" -rf
}

@test "($PLUGIN_COMMAND_PREFIX:link) error when there are no arguments" {
  run dokku "$PLUGIN_COMMAND_PREFIX:link"
  assert_contains "${lines[*]}" "Please specify a name for the service"
}

@test "($PLUGIN_COMMAND_PREFIX:link) error when the app argument is missing" {
  run dokku "$PLUGIN_COMMAND_PREFIX:link" l
  assert_contains "${lines[*]}" "Please specify an app to run the command on"
}

@test "($PLUGIN_COMMAND_PREFIX:link) error when the app does not exist" {
  run dokku "$PLUGIN_COMMAND_PREFIX:link" l not_existing_app
  assert_contains "${lines[*]}" "App not_existing_app does not exist"
}

@test "($PLUGIN_COMMAND_PREFIX:link) error when the service does not exist" {
  run dokku "$PLUGIN_COMMAND_PREFIX:link" not_existing_service my_app
  assert_contains "${lines[*]}" "service not_existing_service does not exist"
}

@test "($PLUGIN_COMMAND_PREFIX:link) error when the service is already linked to app" {
  dokku "$PLUGIN_COMMAND_PREFIX:link" l my_app
  run dokku "$PLUGIN_COMMAND_PREFIX:link" l my_app
  assert_contains "${lines[*]}" "Already linked as DIRECTORY_URL"
}

@test "($PLUGIN_COMMAND_PREFIX:link) exports DIRECTORY_URL to app" {
  dokku "$PLUGIN_COMMAND_PREFIX:link" l my_app
  url=$(dokku config:get my_app DIRECTORY_URL)
  password="$(cat "$PLUGIN_DATA_ROOT/l/PASSWORD")"
  assert_contains "$url" "ldap://admin:$password@dokku-ldap-l:389/l"
  dokku "$PLUGIN_COMMAND_PREFIX:unlink" l my_app
}

@test "($PLUGIN_COMMAND_PREFIX:link) generates an alternate config url when DIRECTORY_URL already in use" {
  dokku config:set my_app DIRECTORY_URL=ldap://user:pass@host:3306/db
  dokku "$PLUGIN_COMMAND_PREFIX:link" l my_app
  run dokku config my_app
  assert_contains "${lines[*]}" "DOKKU_LDAP_"
  dokku "$PLUGIN_COMMAND_PREFIX:unlink" l my_app
}

@test "($PLUGIN_COMMAND_PREFIX:link) links to app with docker-options" {
  dokku "$PLUGIN_COMMAND_PREFIX:link" l my_app
  run dokku docker-options my_app
  assert_contains "${lines[*]}" "--link dokku.ldap.l:dokku-ldap-l"
  dokku "$PLUGIN_COMMAND_PREFIX:unlink" l my_app
}

@test "($PLUGIN_COMMAND_PREFIX:link) uses apps LDAP_DIRECTORY_SCHEME variable" {
  dokku config:set my_app LDAP_DIRECTORY_SCHEME=ldap2
  dokku "$PLUGIN_COMMAND_PREFIX:link" l my_app
  url=$(dokku config:get my_app DIRECTORY_URL)
  password="$(cat "$PLUGIN_DATA_ROOT/l/PASSWORD")"
  assert_contains "$url" "ldap2://admin:$password@dokku-ldap-l:389/l"
  dokku "$PLUGIN_COMMAND_PREFIX:unlink" l my_app
}
