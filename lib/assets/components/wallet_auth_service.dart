import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

class WalletAuthService {
  final LocalAuthentication _localAuth = LocalAuthentication();

  // Hash PIN using SHA-256
  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Set PIN in Firestore (hashed)
  Future<void> setPin(String pin) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final hashedPin = _hashPin(pin);
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'wallet_pin': hashedPin,
    }, SetOptions(merge: true));
  }

  // Verify PIN by comparing hash in Firestore
  Future<bool> verifyPin(String pin) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (!doc.exists || !doc.data()!.containsKey('wallet_pin')) return false;
    final hashedPin = _hashPin(pin);
    return doc['wallet_pin'] == hashedPin;
  }

  // Delete PIN from Firestore
  Future<void> deletePin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'wallet_pin': FieldValue.delete(),
    });
  }

  // Check if device supports biometrics
  Future<bool> isBiometricsAvailable() async {
    if (kIsWeb) return false; // Return false for web platform
    try {
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      
      print('Biometrics Debug in Service:');
      print('canCheckBiometrics: $canCheckBiometrics');
      print('isDeviceSupported: $isDeviceSupported');
      
      return canCheckBiometrics && isDeviceSupported;
    } catch (e) {
      print('Error checking biometrics availability: $e');
      return false;
    }
  }

  // Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      final biometrics = await _localAuth.getAvailableBiometrics();
      print('Available biometrics: $biometrics');
      return biometrics;
    } on PlatformException catch (e) {
      print('Error getting available biometrics: $e');
      return [];
    }
  }

  // Authenticate with biometrics
  Future<bool> authenticateWithBiometrics() async {
    if (kIsWeb) return false; // Return false for web platform
    try {
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      
      if (availableBiometrics.isEmpty) {
        return false;
      }

      return await _localAuth.authenticate(
        localizedReason: 'Authenticate to access your wallet',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (e) {
      print('Error authenticating with biometrics: $e');
      return false;
    }
  }

  // Check if PIN is set in Firestore
  Future<bool> isPinSet() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    return doc.exists && doc.data()!.containsKey('wallet_pin');
  }
} 