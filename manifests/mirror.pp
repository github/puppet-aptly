# == Define: aptly::mirror
#
# Create a mirror using `aptly mirror create`. It will not update, snapshot,
# or publish the mirror for you, because it will take a long time and it
# doesn't make sense to schedule these actions frequenly in Puppet.
#
# NB: This will not recreate the mirror if the params change! You will need
# to manually `aptly mirror drop <name>` after also dropping all snapshot
# and publish references.
#
# === Parameters
#
# [*location*]
#   URL of the APT repo.
#
# [*key*]
#   Import the GPG key into the `trustedkeys` keyring so that aptly can
#   verify the mirror's manifests. May be specified as string or array for
#   multiple keys. If not specified, no action will be taken.
#
# [*keyserver*]
#   The keyserver to use when download the key
#   Default: 'keyserver.ubuntu.com'
#
# [*release*]
#   Distribution to mirror for.
#   Default: `$::lsbdistcodename`
#
# [*repos*]
#   Components to mirror. If an empty array then aptly will default to
#   mirroring all components.
#   Default: []
#
# [*environment*]
#   Optional environment variables to pass to the exec.
#   Example: ['http_proxy=http://127.0.0.2:3128']
#   Default: []
#
# [*cmd_options*]
#   Hash containing the command line options that will be passed to aptly.
#
define aptly::mirror (
  $location,
  $key              = undef,
  $keyserver        = 'keyserver.ubuntu.com',
  $release          = $::lsbdistcodename,
  $repos            = [],
  $environment      = [],
  $cmd_options      = {},
) {
  validate_string($keyserver)
  validate_array($repos)
  validate_array($environment)
  validate_hash($cmd_options)

  $default_cmd_options = {
    '-architectures'    => '',
    '-with-sources'     => false,
    '-with-udebs'       => false,
    '-force-components' => false,
  }

  include ::aptly

  $gpg_cmd = '/usr/bin/gpg --no-default-keyring --keyring trustedkeys.gpg'
  $aptly_cmd = "${::aptly::aptly_cmd} mirror"

  $components = join($repos, ' ')

  if $key {
    if is_array($key) {
      $key_string = join($key, "' '")
    } elsif is_string($key) or is_integer($key) {
      $key_string = $key
    } else {
      fail('$key is neither a string nor an array!')
    }

    exec { "aptly_mirror_gpg-${title}":
      path    => '/bin:/usr/bin',
      command => "${gpg_cmd} --keyserver '${keyserver}' --recv-keys '${key_string}'",
      unless  => "echo '${key_string}' | xargs -n1 ${gpg_cmd} --list-keys",
      user    => $::aptly::user,
    }

    $exec_aptly_mirror_create_require = [
      Package['aptly'],
      Exec["aptly_mirror_gpg-${title}"],
    ]
  } else {
    $exec_aptly_mirror_create_require = [
      Package['aptly'],
    ]
  }

  $cmd_options_string = join(reject(join_keys_to_values(merge($default_cmd_options, $cmd_options), '='), '.*=$'), ' ')
  $cmd_string         = rstrip("${aptly_cmd} create ${cmd_options_string} ${title} ${location} ${release} ${components}")

  exec { "aptly_mirror_create-${title}":
    command     => $cmd_string,
    unless      => "${aptly_cmd} show ${title} >/dev/null",
    user        => $::aptly::user,
    require     => $exec_aptly_mirror_create_require,
    environment => $environment,
  }
}
