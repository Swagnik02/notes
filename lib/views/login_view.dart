// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'dart:developer' as devtools show log;

import 'package:notes/constants/routes.dart';
import 'package:notes/sevices/auth/auth_exceptions.dart';
import 'package:notes/sevices/auth/auth_service.dart';

import '../utilities/show_error_dialogue.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
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
        title: const Text('Login'),
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
                final userCredential = await AuthService.firebase().logIn(
                  email: email,
                  password: password,
                );
                final user = AuthService.firebase().currentUser;

                if (user?.isEmailVerified ?? false) {
                  //Users email verified
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    notesRoute,
                    (route) => false,
                  );
                  devtools.log(userCredential.toString());
                } else {
                  //Users email not verified
                  Navigator.of(context).pushNamed(verifyEmailRoute);
                }
              } on UserNotFoundAuthException {
                await showErrorDialogue(
                  context,
                  'User Not Found',
                );
              } on WrongPasswordAuthException {
                await showErrorDialogue(
                  context,
                  'Wrong Credentials',
                );
              } on GenericAuthExceptions {
                await showErrorDialogue(
                  context,
                  'AuthenticationError',
                );
              }
            },
            child: const Text('Login'),
          ),
          TextButton(
              onPressed: () {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  registerRoute,
                  (route) => false,
                );
              },
              child: const Text('Not registered yet ? Register Here!'))
        ],
      ),
    );
  }
}
