# == Define: aptly::repo
#
# Create a repository using `aptly create`. It will not snapshot, or update the
# repository for you, because it will take a long time and it doesn't make sense
# to schedule these actions frequently in Puppet.
#
# === Parameters
#
# [*cli_options*]
#   Hash containing the command line options that will be passed to aptly.

define aptly::repo(
  $cli_options   = {},
){
  validate_hash($cli_options)

  include ::aptly

  $aptly_cmd = "${::aptly::aptly_cmd} repo"

  $cli_options_string = join(reject(join_keys_to_values($cli_options, '='), '.*=$'), ' ')
  $cmd_string         = rstrip("${aptly_cmd} create ${cli_options_string} ${title}")

  # Since the create and show commands don't share a common set of
  # options, we need to extract the config
  if has_key($cli_options, '-config') {
    $config_string = "-config=${cli_options['-config']}"
  } else {
    $config_string = ''
  }

  exec{ "aptly_repo_create-${title}":
    command => $cmd_string,
    unless  => "${aptly_cmd} show ${config_string} ${title} >/dev/null",
    user    => $::aptly::user,
    require => Package['aptly'],
  }
}
