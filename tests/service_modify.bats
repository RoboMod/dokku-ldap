#!/usr/bin/env bats
load test_helper

setup() {
  export ECHO_DOCKER_COMMAND="false"
  dokku "$PLUGIN_COMMAND_PREFIX:create" l >&2
  echo "data" > "$PLUGIN_DATA_ROOT/fake.input"
}

teardown() {
  export ECHO_DOCKER_COMMAND="false"
  dokku --force "$PLUGIN_COMMAND_PREFIX:destroy" l >&2
  rm -f "$PLUGIN_DATA_ROOT/fake.input"
}

@test "($PLUGIN_COMMAND_PREFIX:modify) error when there are no arguments" {
  run dokku "$PLUGIN_COMMAND_PREFIX:modify"
  assert_contains "${lines[*]}" "Please specify a name for the service"
}

@test "($PLUGIN_COMMAND_PREFIX:modify) error when service does not exist" {
  run dokku "$PLUGIN_COMMAND_PREFIX:modify" not_existing_service
  assert_contains "${lines[*]}" "service not_existing_service does not exist"
}

@test "($PLUGIN_COMMAND_PREFIX:modify) success" {
  export ECHO_DOCKER_COMMAND="true"
  run dokku "$PLUGIN_COMMAND_PREFIX:modify" l < "$PLUGIN_DATA_ROOT/fake.input"
  PASSWORD="$(cat "$PLUGIN_DATA_ROOT/l/PASSWORD")"
  assert_output "docker exec -i dokku.ldap.l ldapmodify -x -h localhost -D cn=admin,dc=l -w $PASSWORD"
}
