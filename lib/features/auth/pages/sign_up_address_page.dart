import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../data/us_states.dart';
import '../models/sign_up_draft.dart';
import '../providers/sign_up_provider.dart';
import '../services/address_suggestions.dart';
import '../widgets/address_suggestion_field.dart';
import '../widgets/email_domain_dropdown.dart';
import '../widgets/sign_up_components.dart';

class SignUpAddressPage extends ConsumerStatefulWidget {
  const SignUpAddressPage({super.key, this.onSubmit});
  final Future<void> Function(SignUpDraft draft)? onSubmit;
  @override
  ConsumerState<SignUpAddressPage> createState() => _SignUpAddressPageState();
}

class _SignUpAddressPageState extends ConsumerState<SignUpAddressPage> {
  late final TextEditingController _address, _apartment, _city, _zip;
  bool _busy = false;
  String? _notice;
  @override
  void initState() {
    super.initState();
    final draft = ref.read(signUpProvider);
    _address = TextEditingController(text: draft.addressLine1);
    _apartment = TextEditingController(text: draft.apartment);
    _city = TextEditingController(text: draft.city);
    _zip = TextEditingController(text: draft.zipCode);
  }

  @override
  void dispose() {
    for (final controller in [_address, _apartment, _city, _zip]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _select(AddressSuggestion suggestion) {
    _address.text = suggestion.line1;
    _city.text = suggestion.city;
    _zip.text = suggestion.zip;
    final draft = ref.read(signUpProvider);
    ref
        .read(signUpProvider.notifier)
        .update(
          draft.copyWith(
            addressLine1: suggestion.line1,
            city: suggestion.city,
            stateCode: suggestion.stateCode,
            zipCode: suggestion.zip,
          ),
        );
    FocusManager.instance.primaryFocus?.unfocus();
  }

  Future<void> _submit() async {
    final draft = ref.read(signUpProvider);
    if (_busy || !draft.canSubmit) return;
    FocusManager.instance.primaryFocus?.unfocus();
    if (widget.onSubmit == null) {
      setState(
        () => _notice =
            'Sign up is not connected yet. No account has been created.',
      );
      return;
    }
    setState(() {
      _busy = true;
      _notice = null;
    });
    try {
      await widget.onSubmit!(draft.normalized);
    } catch (_) {
      if (mounted) {
        setState(() => _notice = 'Unable to submit. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _input(
    String key,
    TextEditingController text,
    String hint,
    ValueChanged<String> onChanged, {
    bool zip = false,
  }) => TextField(
    key: ValueKey(key),
    controller: text,
    enabled: !_busy,
    textInputAction: TextInputAction.next,
    style: const TextStyle(fontSize: 16, height: 1.2),
    keyboardType: zip ? TextInputType.number : TextInputType.text,
    inputFormatters: zip ? [FilteringTextInputFormatter.digitsOnly] : null,
    decoration: signUpDecoration(hint),
    onChanged: onChanged,
  );
  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(signUpProvider);
    final controller = ref.read(signUpProvider.notifier);
    return SignUpScaffold(
      title: 'ADDRESS',
      address: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SignUpField(
            label: 'Address line 1',
            child: AddressSuggestionField(
              controller: _address,
              enabled: !_busy,
              source: ref.watch(addressSuggestionSourceProvider),
              onChanged: (value) => controller.update(
                ref.read(signUpProvider).copyWith(addressLine1: value),
              ),
              onSelected: _select,
            ),
          ),
          const SizedBox(height: 18),
          SignUpField(
            label: 'Apt, unit, etc.',
            child: _input(
              'signup-apartment',
              _apartment,
              'e.g. Apt 4B',
              (value) => controller.update(
                ref.read(signUpProvider).copyWith(apartment: value),
              ),
            ),
          ),
          const SizedBox(height: 18),
          SignUpField(
            label: 'City',
            child: _input(
              'signup-city',
              _city,
              'e.g. Brooklyn',
              (value) => controller.update(
                ref.read(signUpProvider).copyWith(city: value),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SignUpField(
                  label: 'State',
                  child: EmailDomainDropdown(
                    controlKey: const ValueKey('signup-state'),
                    semanticLabel: 'Choose state',
                    options: [
                      if (draft.stateCode.isNotEmpty) draft.stateCode,
                      ...usStates.keys.where((code) => code != draft.stateCode),
                    ],
                    optionNames: usStates,
                    maxMenuHeight: 192,
                    value: draft.stateCode.isEmpty ? null : draft.stateCode,
                    showSelectionMark: true,
                    enabled: !_busy,
                    onChanged: (value) => controller.update(
                      ref.read(signUpProvider).copyWith(stateCode: value),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SignUpField(
                  label: 'ZIP code',
                  child: _input(
                    'signup-zip',
                    _zip,
                    'e.g. 10025',
                    (value) => controller.update(
                      ref.read(signUpProvider).copyWith(zipCode: value),
                    ),
                    zip: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SignUpButton(
            label: 'Join',
            onPressed: draft.canSubmit && !_busy ? _submit : null,
          ),
          if (_busy)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (_notice != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Semantics(
                liveRegion: true,
                child: Text(
                  _notice!,
                  style: const TextStyle(color: Color(0xFF606060)),
                ),
              ),
            ),
          const SizedBox(height: 32),
          const Text(
            "Your exact address and the fact that you live here stay private, and you'll always appear anonymously.",
            style: TextStyle(
              color: Color(0xFF667685),
              fontSize: 12,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
