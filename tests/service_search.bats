cd #!/usr/bin/env bats
load test_helper

setup() {
  export ECHO_DOCKER_COMMAND="false"
  dokku "$PLUGIN_COMMAND_PREFIX:create" l >&2
}

teardown() {
  export ECHO_DOCKER_COMMAND="false"
  dokku --force "$PLUGIN_COMMAND_PREFIX:destroy" l >&2
}

@test "($PLUGIN_COMMAND_PREFIX:search) error when there are no arguments" {
  run dokku "$PLUGIN_COMMAND_PREFIX:search"
  assert_contains "${lines[*]}" "Please specify a name for the service"
}

@test "($PLUGIN_COMMAND_PREFIX:search) error when service does not exist" {
  run dokku "$PLUGIN_COMMAND_PREFIX:search" not_existing_service
  assert_contains "${lines[*]}" "service not_existing_service does not exist"
}

@test "($PLUGIN_COMMAND_PREFIX:search) success" {
  export ECHO_DOCKER_COMMAND="true"
  run dokku "$PLUGIN_COMMAND_PREFIX:search" l
  PASSWORD="$(cat "$PLUGIN_DATA_ROOT/l/PASSWORD")"
  assert_output "docker exec dokku.ldap.l ldapsearch -x -h localhost -D cn=admin,dc=l -w $PASSWORD l"
}
