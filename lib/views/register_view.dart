// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'dart:developer' as devtools show log;

import 'package:notes/constants/routes.dart';
import 'package:notes/sevices/auth/auth_exceptions.dart';
import 'package:notes/sevices/auth/auth_service.dart';
import 'package:notes/utilities/show_error_dialogue.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  late final TextEditingController _email;
  late final TextEditingController _password;

  @override
  void initState() {
    _email = TextEditingController();
    _password = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
      ),
      body: Column(
        children: [
          TextField(
            controller: _email,
            enableSuggestions: false,
            autocorrect: false,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              hintText: 'Enter your email here',
            ),
          ),
          TextField(
            controller: _password,
            obscureText: true,
            enableSuggestions: false,
            autocorrect: false,
            decoration: const InputDecoration(
              hintText: 'Enter your password here',
            ),
          ),
          TextButton(
            onPressed: () async {
              final email = _email.text;
              final password = _password.text;
              try {
                final userCredential = await AuthService.firebase().createUser(
                  email: email,
                  password: password,
                );
                devtools.log(userCredential.toString());
                await AuthService.firebase().sendEmailVerification();

                Navigator.of(context).pushNamed(verifyEmailRoute);
              } on WeakPasswordAuthException {
                await showErrorDialogue(
                  context,
                  'Weak Password',
                );
              } on EmailAlreadyInUseException {
                await showErrorDialogue(
                  context,
                  'Email Already In Use',
                );
              } on InvalidEmailException {
                await showErrorDialogue(
                  context,
                  'Invalid Email Entered',
                );
              } on GenericAuthExceptions {
                if (email.isEmpty && password.isEmpty) {
                  await showErrorDialogue(
                    context,
                    'Enter email and password',
                  );
                } else if (email.isEmpty) {
                  await showErrorDialogue(
                    context,
                    'Enter email',
                  );
                } else if (password.isEmpty) {
                  await showErrorDialogue(
                    context,
                    'Enter password',
                  );
                } else {
                  await showErrorDialogue(
                    context,
                    'AuthenticationError',
                  );
                }
              }
            },
            child: const Text('Register'),
          ),
          TextButton(
              onPressed: () {
                Navigator.of(context)
                    .pushNamedAndRemoveUntil(loginRoute, (route) => false);
              },
              child: const Text('Already registered? Login Here!'))
        ],
      ),
    );
  }
}
