import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _oldPwdController = TextEditingController();
  final _newPwdController = TextEditingController();
  final _formKeyPwd = GlobalKey<FormState>();
  String? _pwdError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = Provider.of<AuthService>(context);
    final user = auth.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profilo'),
        centerTitle: true,
        elevation: 2,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: theme.colorScheme.primary,
                    child: Text(
                      user.full_name.substring(0, 1).toUpperCase(),
                      style: theme.textTheme.headlineLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    user.full_name,
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6)),
                  ),
                  const SizedBox(height: 24),

                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 8,
                    shadowColor: Colors.black26,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          _buildInfoRow(
                            icon: Icons.calendar_today,
                            label: 'Registrato il',
                            value: user.registrationDate
                                .toLocal()
                                .toString()
                                .split('.')[0],
                            theme: theme,
                          ),
                          const Divider(height: 32),
                          _buildInfoRow(
                            icon: Icons.devices,
                            label: 'Dispositivi',
                            value: user.connectedDevices.isNotEmpty
                                ? user.connectedDevices.join(', ')
                                : 'Nessuno',
                            theme: theme,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: theme.colorScheme.primary),
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _showChangePasswordDialog,
                      child: Text(
                        'Cambia password',
                        style: theme.textTheme.labelLarge
                            ?.copyWith(color: theme.colorScheme.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      icon: const Icon(Icons.exit_to_app),
                      label: const Text('Logout'),
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                        shape: const StadiumBorder(),
                        padding:
                        const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () async {
                        await auth.logout();
                        Navigator.pushReplacementNamed(
                            context, '/login');
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required ThemeData theme,
  }) {
    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Text(
          '$label:',
          style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  void _showChangePasswordDialog() {
    final theme = Theme.of(context);
    _oldPwdController.clear();
    _newPwdController.clear();
    _pwdError = null;

    showDialog(
      context: context,
      builder: (dialogContext) {
        bool obscureOld = true;
        bool obscureNew = true;

        return StatefulBuilder(
          builder: (context, setState) =>
              AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Text(
                    'Cambia Password', style: theme.textTheme.headlineSmall),
                content: Form(
                  key: _formKeyPwd,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _oldPwdController,
                        obscureText: obscureOld,
                        decoration: InputDecoration(
                          labelText: 'Password attuale',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureOld ? Icons.visibility_off : Icons
                                  .visibility,
                            ),
                            onPressed: () =>
                                setState(() => obscureOld = !obscureOld),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'Inserisci password attuale';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _newPwdController,
                        obscureText: obscureNew,
                        decoration: InputDecoration(
                          labelText: 'Nuova password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureNew ? Icons.visibility_off : Icons
                                  .visibility,
                            ),
                            onPressed: () =>
                                setState(() => obscureNew = !obscureNew),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.length < 8) {
                            return 'Almeno 8 caratteri';
                          }
                          return null;
                        },
                      ),

                      if (_pwdError != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _pwdError!,
                          style: TextStyle(
                            color: theme.colorScheme.error,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                actionsPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(dialogContext, rootNavigator: true).pop();
                    },
                    child: Text('Annulla', style: theme.textTheme.labelLarge),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                    onPressed: () async {
                      if (!_formKeyPwd.currentState!.validate()) return;
                      final auth = Provider.of<AuthService>(
                          context, listen: false);
                      final success = await auth.changePassword(
                        oldPassword: _oldPwdController.text,
                        newPassword: _newPwdController.text,
                      );
                      if (success) {
                        Navigator.of(dialogContext, rootNavigator: true).pop();

                        showDialog(
                          context: context,
                          builder: (successContext) {
                            return AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              title: Text('Successo',
                                  style: theme.textTheme.headlineSmall),
                              content: Text(
                                'Password aggiornata con successo.',
                                style: theme.textTheme.bodyMedium,
                              ),
                              actions: [
                                Center(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      shape: const StadiumBorder(),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 24, vertical: 12),
                                    ),
                                    onPressed: () {
                                      Navigator
                                          .of(
                                          successContext, rootNavigator: true)
                                          .pop();
                                    },
                                    child: const Text('OK'),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      } else {
                        setState(() {
                          _pwdError = 'Impossibile cambiare password';
                        });
                      }
                    },
                    child: const Text('Conferma'),
                  ),
                ],
              ),
        );
      },
    );
  }
}