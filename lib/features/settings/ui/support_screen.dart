import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/support_config.dart';
import '../../../core/services/support_email_service.dart';

class SupportScreen extends StatefulWidget {
  final SupportRequest request;
  final SupportEmailService service;
  const SupportScreen({
    super.key,
    required this.request,
    required this.service,
  });
  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final _form = GlobalKey<FormState>();
  final _message = TextEditingController();
  bool _busy = false;
  bool _allowPop = false;
  bool _confirming = false;
  bool _failed = false;
  String? _notice;
  bool get _contact => widget.request == SupportRequest.contact;
  String get _title => switch (widget.request) {
    SupportRequest.feedback => 'Send Feedback',
    SupportRequest.problem => 'Report a Problem',
    SupportRequest.contact => 'Contact Us',
  };
  @override
  void initState() {
    super.initState();
    if (_contact) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _send();
      });
    }
  }

  void _notify(String message, {bool failed = false}) {
    if (mounted) {
      setState(() {
        _notice = message;
        _failed = failed;
      });
    }
  }

  Future<void> _send() async {
    if (_busy || (!_contact && !_form.currentState!.validate())) return;
    setState(() {
      _busy = true;
      _notice = null;
    });
    try {
      final draft = await widget.service.prepare(widget.request, _message.text);
      if (!mounted) return;
      final opened = await widget.service.open(draft);
      _notify(
        opened
            ? 'Email app opened. Review and send your email there. Your draft stays here until you close this screen.'
            : widget.service.configured
            ? "Couldn't open an email app. Copy the ${_contact ? 'address' : 'message'} below and try again later."
            : 'The support email has not been configured yet.${_contact ? '' : ' You can copy your message and keep it for later.'}',
        failed: !opened,
      );
    } catch (_) {
      _notify(
        'Could not prepare your email. Your text is still here. Please try again.',
        failed: true,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _copy({bool address = false}) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final text = address
          ? widget.service.address
          : (await widget.service.prepare(
              widget.request,
              _message.text,
            )).copyText;
      await Clipboard.setData(ClipboardData(text: text));
      _notify(
        address ? 'Email address copied to the system clipboard.' : 'Message copied to the system clipboard. Your draft is still here.',
      );
    } catch (_) {
      _notify(
        'Could not copy. Your text is still here; select it to copy manually.',
        failed: true,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmClose() async {
    if (_busy || _confirming) return;
    _confirming = true;
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard this draft?'),
        content: const Text(
          'This draft is only kept while this screen is open. Copy it first if you want to keep it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep editing'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    _confirming = false;
    if (discard == true && mounted) {
      setState(() => _allowPop = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return PopScope(
      canPop: !_busy && (_allowPop || _message.text.isEmpty),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _confirmClose();
      },
      child: Scaffold(
        appBar: AppBar(title: Text(_title)),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: Icon(
                                  switch (widget.request) {
                                    SupportRequest.feedback =>
                                      Icons.feedback_outlined,
                                    SupportRequest.problem =>
                                      Icons.bug_report_outlined,
                                    SupportRequest.contact =>
                                      Icons.mail_outline_rounded,
                                  },
                                  color: colors.primary,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(switch (widget.request) {
                                SupportRequest.feedback => "We'd love to hear from you. Share an idea or tell us how we can make FocusFlow better.",
                                SupportRequest.problem => 'Tell us what went wrong so we can improve FocusFlow.',
                                SupportRequest.contact =>
                                  'Get in touch with us using your email app.',
                              }, style: theme.textTheme.bodyLarge),
                              const SizedBox(height: 20),
                              if (!_contact)
                                TextFormField(
                                  controller: _message,
                                  readOnly: _busy,
                                  minLines: 5,
                                  maxLines: 10,
                                  maxLength: SupportConfig.maxMessageLength,
                                  keyboardType: TextInputType.multiline,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  onChanged: (_) =>
                                      setState(() => _notice = null),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: colors.surfaceContainerHighest,
                                    labelText:
                                        widget.request == SupportRequest.problem
                                        ? 'Problem description'
                                        : 'Your feedback',
                                    hintText:
                                        widget.request == SupportRequest.problem
                                        ? 'Describe what happened...'
                                        : 'Tell us what you think...',
                                    alignLabelWithHint: true,
                                    errorMaxLines: 3,
                                  ),
                                  validator: (value) =>
                                      value == null || value.trim().isEmpty
                                      ? 'Please write a message before continuing.'
                                      : null,
                                ),
                              if (widget.service.configured)
                                SelectableText(widget.service.address),
                              const SizedBox(height: 12),
                              Text(
                                'FocusFlow hands a draft to your email app; you choose whether to send it. Your email app may save or sync drafts.',
                                style: theme.textTheme.bodySmall,
                              ),
                              if (widget.request == SupportRequest.problem) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Only the app version, build number and platform are attached. No tasks, focus history, XP or device identifiers are included.',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      if (_notice != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Semantics(
                            liveRegion: true,
                            child: Text(
                              _notice!,
                              style: TextStyle(
                                color: _failed
                                    ? colors.error
                                    : colors.onSurface,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        key: const ValueKey('support-send'),
                        onPressed: _busy ? null : _send,
                        icon: _busy
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  semanticsLabel: 'Preparing email',
                                  value: MediaQuery.disableAnimationsOf(context)
                                      ? 1
                                      : null,
                                ),
                              )
                            : const Icon(Icons.open_in_new_rounded),
                        label: Text(
                          _busy
                              ? 'Preparing…'
                              : _contact
                              ? 'Open email app'
                              : _title,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      if (_notice != null) ...[
                        if (!_contact)
                          TextButton.icon(
                            onPressed: _busy ? null : () => _copy(),
                            icon: const Icon(Icons.copy_rounded),
                            label: const Text('Copy message'),
                          ),
                        if (widget.service.configured)
                          TextButton.icon(
                            onPressed: _busy
                                ? null
                                : () => _copy(address: true),
                            icon: const Icon(Icons.alternate_email_rounded),
                            label: const Text('Copy email address'),
                          ),
                      ],
                      TextButton(
                        onPressed: _busy
                            ? null
                            : () => Navigator.maybePop(context),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }
}
