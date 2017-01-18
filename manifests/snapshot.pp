# == Define: aptly::snapshot
#
# Create a snapshot using `aptly snapshot`.
#
# === Parameters
#
# [*repo*]
#   Create snapshot from given repo.
#
# [*mirror*]
#   Create snapshot from given mirror.
#
define aptly::snapshot (
  $repo        = undef,
  $mirror      = undef,
  $cli_options = {},
) {
  validate_hash($cli_options)

  include aptly

  $aptly_cmd = "${::aptly::aptly_cmd} snapshot"

  $cli_options_string = join(join_keys_to_values($cli_options, '='), ' ')

  # Since the create and show commands don't share a common set of
  # options, we need to extract the config if it has been specified.
  $config_path_specified = has_key($cli_options, '-config')
  if $config_path_specified {
    $config_string="-config=${cli_options['-config']}"
  } else {
    $config_string = ''
  }

  if $repo and $mirror {
    fail('$repo and $mirror are mutually exclusive.')
  }
  elsif $repo {
    $aptly_args = "create ${title} from repo ${repo}"
  }
  elsif $mirror {
    $aptly_args = "create ${title} from mirror ${mirror}"
  }
  else {
    $aptly_args = "create ${title} empty"
  }

  exec { "aptly_snapshot_create-${title}":
    command => "${aptly_cmd} ${cli_options_string} ${aptly_args}",
    unless  => "${aptly_cmd} ${config_string} show ${title} >/dev/null",
    user    => $::aptly::user,
    require => Class['aptly'],
  }

}
