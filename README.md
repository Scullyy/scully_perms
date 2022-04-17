# Add the following to your server.cfg

ensure scully_perms

add_ace resource.scully_perms command.add_principal allow
add_ace resource.scully_perms command.remove_principal allow

# You can check permissions by doing either of the following or by using the native IsPlayerAceAllowed

exports['scully_perms']:hasPermission(source, 'permission')

or

exports['scully_perms']:hasPermission(source, {'permission1', 'permission2', 'permission3'})