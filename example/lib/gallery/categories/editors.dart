import 'package:cloudscape_flutter/cloudscape_flutter.dart';
import 'package:flutter/widgets.dart';

import '../demo.dart';

/// Attribute editor, tag editor, file upload, file input, dropzone, prompt
/// input and code editor. Every name and figure here is sample data.
final CsDemoCategory editorsCategory = CsDemoCategory(
  title: 'Editors and uploads',
  description: 'Attribute editor, tag editor, file upload, file input, dropzone, prompt input and code editor.',
  icon: CsIcons.upload,
  demos: [
    CsDemo(
      title: 'CsAttributeEditor',
      description: 'Rows of fields with add and remove, validation, an item limit and responsive layouts.',
      docPath: 'doc/components/CsAttributeEditor.md',
      builder: (_) => const _AttributeEditorDemo(),
    ),
    CsDemo(
      title: 'CsTagEditor',
      description: 'Resource tags with suggestions, validation, a tag limit and undo for existing tags.',
      docPath: 'doc/components/CsTagEditor.md',
      builder: (_) => const _TagEditorDemo(),
    ),
    CsDemo(
      title: 'CsFileInput',
      description: 'A button or icon that opens the app picker.',
      docPath: 'doc/components/CsFileInput.md',
      builder: (_) => const _FileInputDemo(),
    ),
    CsDemo(
      title: 'CsFileDropzone',
      description: 'The drop area: tap to pick, drag sample files onto it, or drive the active state.',
      docPath: 'doc/components/CsFileDropzone.md',
      builder: (_) => const _FileDropzoneDemo(),
    ),
    CsDemo(
      title: 'CsFileTokenGroup',
      description: 'File tokens with metadata, thumbnails, loading, errors, warnings and a limit.',
      docPath: 'doc/components/CsFileTokenGroup.md',
      builder: (_) => const _FileTokenGroupDemo(),
    ),
    CsDemo(
      title: 'CsFileUpload',
      description: 'Choose files, see them as tokens, with constraint and validation text.',
      docPath: 'doc/components/CsFileUpload.md',
      builder: (_) => const _FileUploadDemo(),
    ),
    CsDemo(
      title: 'CsPromptInput',
      description: 'A chat field that grows, sends on Enter and holds secondary actions and content.',
      docPath: 'doc/components/CsPromptInput.md',
      builder: (_) => const _PromptInputDemo(),
    ),
    CsDemo(
      title: 'CsCodeEditor',
      description: 'Line numbers, highlighting, validation, preferences and the status bar.',
      docPath: 'doc/components/CsCodeEditor.md',
      builder: (_) => const _CodeEditorDemo(),
    ),
  ],
);

/// Sample files the demo "picker" hands out, in turn.
final List<CsFile> _sampleFiles = [
  CsFile(
    name: 'access-log-2024-01-15.txt',
    size: 482133,
    lastModified: DateTime(2024, 1, 15, 13, 45),
    type: 'text/plain',
  ),
  CsFile(name: 'architecture-diagram.png', size: 1203554, lastModified: DateTime(2024, 1, 12, 9, 5), type: 'image/png'),
  CsFile(
    name: 'server.crt',
    size: 2048,
    lastModified: DateTime(2024, 1, 2, 18, 30),
    type: 'application/x-x509-ca-cert',
  ),
  CsFile(name: 'bucket-policy.json', size: 912, lastModified: DateTime(2023, 12, 20, 11, 0), type: 'application/json'),
  CsFile(name: 'instance-inventory.csv', size: 33210, lastModified: DateTime(2023, 12, 1, 8, 15), type: 'text/csv'),
];

int _pickCursor = 0;

/// Stands in for a real picker (file_picker, image_picker): returns sample
/// files after a short delay.
Future<List<CsFile>?> _samplePicker(CsFilePickRequest request) async {
  await Future<void>.delayed(const Duration(milliseconds: 150));
  final count = request.multiple ? 2 : 1;
  return [for (var i = 0; i < count; i++) _sampleFiles[(_pickCursor++) % _sampleFiles.length]];
}

class _EnvVar {
  const _EnvVar(this.key, this.value);
  final String key;
  final String value;
}

class _AttributeEditorDemo extends StatefulWidget {
  const _AttributeEditorDemo();

  @override
  State<_AttributeEditorDemo> createState() => _AttributeEditorDemoState();
}

class _AttributeEditorDemoState extends State<_AttributeEditorDemo> {
  static const _limit = 5;
  List<_EnvVar> _vars = const [_EnvVar('STAGE', 'production'), _EnvVar('BUCKET', 'example-bucket')];
  List<(String, String, String, String)> _rules = const [('HTTPS', '443', '0.0.0.0/0', 'Public web')];

  void _setVar(int i, {String? key, String? value}) => setState(() {
    final v = _vars[i];
    _vars = [..._vars]..[i] = _EnvVar(key ?? v.key, value ?? v.value);
  });

  @override
  Widget build(BuildContext context) {
    return DemoColumn(
      children: [
        DemoSection(
          title: 'Environment variables',
          caption: 'Two fields share a line on wide containers and stack on narrow ones. Keys are required.',
          child: CsAttributeEditor<_EnvVar>(
            items: _vars,
            addButtonText: 'Add environment variable',
            itemLimit: _limit,
            empty: const Text('No environment variables.'),
            additionalInfo: Text(
              _vars.length >= _limit
                  ? 'You have reached the limit of $_limit variables.'
                  : 'You can add up to ${_limit - _vars.length} more variables.',
            ),
            removeButtonAriaLabel: (v) => 'Remove ${v.key.isEmpty ? 'variable' : v.key}',
            onAddButtonClick: () => setState(() => _vars = [..._vars, const _EnvVar('', '')]),
            onRemoveButtonClick: (i) => setState(() => _vars = [..._vars]..removeAt(i)),
            definition: [
              CsAttributeEditorField(
                label: 'Key',
                control: (v, i) => CsInput(
                  value: v.key,
                  placeholder: 'MY_VARIABLE',
                  invalid: v.key.isEmpty,
                  onChange: (s) => _setVar(i, key: s),
                ),
                errorText: (v, i) => v.key.isEmpty ? 'Enter a key.' : null,
              ),
              CsAttributeEditorField(
                label: 'Value',
                control: (v, i) => CsInput(
                  value: v.value,
                  placeholder: 'value',
                  onChange: (s) => _setVar(i, value: s),
                ),
                constraintText: (v, i) => i == _vars.length - 1 ? 'Up to 256 characters.' : null,
              ),
            ],
          ),
        ),
        DemoSection(
          title: 'Four fields with a custom layout',
          caption: 'Inbound rules: one line from the s breakpoint, two by two below it, stacked on phones.',
          child: CsAttributeEditor<(String, String, String, String)>(
            items: _rules,
            addButtonText: 'Add rule',
            addButtonVariant: CsAttributeEditorAddButtonVariant.inlineLink,
            isItemRemovable: (r) => r.$1 != 'HTTPS',
            onAddButtonClick: () => setState(() => _rules = [..._rules, ('Custom TCP', '8080', '10.0.0.0/16', '')]),
            onRemoveButtonClick: (i) => setState(() => _rules = [..._rules]..removeAt(i)),
            gridLayout: const [
              CsAttributeEditorGridLayout(
                breakpoint: CsBreakpoint.s,
                rows: [
                  [2, 1, 2, 3],
                ],
              ),
              CsAttributeEditorGridLayout(
                breakpoint: CsBreakpoint.xxs,
                rows: [
                  [1, 1],
                  [1, 1],
                ],
              ),
              CsAttributeEditorGridLayout(
                rows: [
                  [1],
                  [1],
                  [1],
                  [1],
                ],
              ),
            ],
            definition: [
              CsAttributeEditorField(
                label: 'Type',
                control: (r, i) => CsInput(value: r.$1, readOnly: true),
              ),
              CsAttributeEditorField(
                label: 'Port',
                control: (r, i) => CsInput(value: r.$2, readOnly: true),
              ),
              CsAttributeEditorField(
                label: 'Source',
                control: (r, i) => CsInput(value: r.$3, readOnly: true),
              ),
              CsAttributeEditorField(
                label: 'Description',
                control: (r, i) => CsInput(value: r.$4, readOnly: true, placeholder: 'Optional'),
                warningText: (r, i) => r.$3 == '0.0.0.0/0' ? 'Open to the internet.' : null,
              ),
            ],
          ),
        ),
        DemoSection(
          title: 'Empty',
          child: CsAttributeEditor<_EnvVar>(
            items: const [],
            addButtonText: 'Add header',
            empty: const Text('No custom headers.'),
            onAddButtonClick: () {},
            definition: [
              CsAttributeEditorField(
                label: 'Header',
                control: (v, i) => CsInput(value: v.key),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TagEditorDemo extends StatefulWidget {
  const _TagEditorDemo();

  @override
  State<_TagEditorDemo> createState() => _TagEditorDemoState();
}

class _TagEditorDemoState extends State<_TagEditorDemo> {
  static const _initial = [
    CsTag(key: 'environment', value: 'production', existing: true),
    CsTag(key: 'team', value: 'payments', existing: true),
  ];
  List<CsTag> _tags = _initial;
  bool _valid = true;
  bool _loading = false;

  static Future<List<String>> _keys(String key) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return ['environment', 'team', 'cost-center', 'owner', 'project'];
  }

  static Future<List<String>> _values(String key, String value) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return switch (key) {
      'environment' => ['production', 'staging', 'development'],
      'team' => ['payments', 'search', 'platform'],
      'cost-center' => ['cc-1001', 'cc-2040'],
      _ => [],
    };
  }

  @override
  Widget build(BuildContext context) {
    final diff = CsTagEditor.getTagsDiff(_initial, _tags);
    return DemoColumn(
      children: [
        DemoSection(
          title: 'Tags with suggestions',
          caption: 'Focus a key or value for suggestions. Removing an existing tag offers Undo. The limit is 5.',
          child: CsTagEditor(
            tags: _tags,
            tagLimit: 5,
            loading: _loading,
            keysRequest: _keys,
            valuesRequest: _values,
            onChange: (c) => setState(() {
              _tags = c.tags;
              _valid = c.valid;
            }),
          ),
        ),
        DemoSection(
          title: 'Changes to save',
          child: CsBox(
            variant: CsBoxVariant.code,
            text: 'valid: $_valid\ncreated: ${diff.created}\nremoved: ${diff.removed}',
          ),
        ),
        DemoSection(
          title: 'Loading',
          child: CsCheckbox(
            checked: _loading,
            label: 'Show the loading state',
            onChange: (v) => setState(() => _loading = v),
          ),
        ),
      ],
    );
  }
}

class _FileInputDemo extends StatefulWidget {
  const _FileInputDemo();

  @override
  State<_FileInputDemo> createState() => _FileInputDemoState();
}

class _FileInputDemoState extends State<_FileInputDemo> {
  List<CsFile> _files = const [];

  @override
  Widget build(BuildContext context) {
    return DemoColumn(
      children: [
        DemoSection(
          title: 'Button',
          caption: 'onPick opens the app picker (here, a sample one).',
          child: CsSpaceBetween(
            direction: CsSpaceBetweenDirection.horizontal,
            size: CsSpacingSize.xs,
            alignItems: CsSpaceBetweenAlign.center,
            children: [
              CsFileInput(
                value: _files,
                text: 'Choose files',
                multiple: true,
                onPick: _samplePicker,
                onChange: (f) => setState(() => _files = f),
              ),
              CsFileInput(
                value: _files,
                variant: CsFileInputVariant.icon,
                ariaLabel: 'Upload a log file',
                onPick: _samplePicker,
                onChange: (f) => setState(() => _files = f),
              ),
              const CsFileInput(value: [], text: 'Choose file', disabled: true),
            ],
          ),
        ),
        DemoSection(
          title: 'Picked',
          child: CsBox(
            color: CsBoxColor.textBodySecondary,
            text: _files.isEmpty ? 'No files chosen.' : _files.map((f) => f.name).join(', '),
          ),
        ),
      ],
    );
  }
}

class _FileDropzoneDemo extends StatefulWidget {
  const _FileDropzoneDemo();

  @override
  State<_FileDropzoneDemo> createState() => _FileDropzoneDemoState();
}

class _FileDropzoneDemoState extends State<_FileDropzoneDemo> {
  List<CsFile> _files = const [];
  bool _active = false;

  @override
  Widget build(BuildContext context) {
    return DemoColumn(
      children: [
        DemoSection(
          title: 'Tap or drop',
          caption: 'Tap the zone to pick, or drag a sample file onto it.',
          child: CsSpaceBetween(
            size: CsSpacingSize.s,
            children: [
              Wrap(
                spacing: CsSpace.xs,
                runSpacing: CsSpace.xs,
                children: [
                  for (final f in _sampleFiles.take(3))
                    Draggable<CsFile>(
                      data: f,
                      feedback: CsBox(variant: CsBoxVariant.small, text: f.name),
                      child: CsBox(variant: CsBoxVariant.code, text: f.name),
                    ),
                ],
              ),
              CsFileDropzone(
                active: _active,
                semanticLabel: 'Choose files to upload',
                onPick: _samplePicker,
                onChange: (f) => setState(() => _files = [..._files, ...f]),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [CsIcon(CsIcons.upload), Text('Drop files to upload, or tap to choose')],
                ),
              ),
            ],
          ),
        ),
        DemoSection(
          title: 'Driven by the app',
          caption: 'A drag and drop plugin sets active while OS files hover the window.',
          child: CsCheckbox(
            checked: _active,
            label: 'Files are over the zone',
            onChange: (v) => setState(() => _active = v),
          ),
        ),
        DemoSection(
          title: 'Received',
          child: CsFileTokenGroup(
            items: [for (final f in _files) CsFileTokenGroupItem(file: f)],
            onDismiss: (i) => setState(() => _files = [..._files]..removeAt(i)),
          ),
        ),
      ],
    );
  }
}

class _FileTokenGroupDemo extends StatefulWidget {
  const _FileTokenGroupDemo();

  @override
  State<_FileTokenGroupDemo> createState() => _FileTokenGroupDemoState();
}

class _FileTokenGroupDemoState extends State<_FileTokenGroupDemo> {
  late List<CsFileTokenGroupItem> _items = [
    CsFileTokenGroupItem(file: _sampleFiles[0]),
    CsFileTokenGroupItem(file: _sampleFiles[1], loading: true),
    CsFileTokenGroupItem(file: _sampleFiles[2], errorText: 'The certificate has expired.'),
    CsFileTokenGroupItem(file: _sampleFiles[3], warningText: 'The policy allows public read access.'),
    CsFileTokenGroupItem(file: _sampleFiles[4]),
  ];
  bool _horizontal = false;
  bool _readOnly = false;

  @override
  Widget build(BuildContext context) {
    return DemoColumn(
      children: [
        DemoSection(
          title: 'Options',
          child: Wrap(
            spacing: CsSpace.l,
            children: [
              CsCheckbox(checked: _horizontal, label: 'Horizontal', onChange: (v) => setState(() => _horizontal = v)),
              CsCheckbox(checked: _readOnly, label: 'Read-only', onChange: (v) => setState(() => _readOnly = v)),
            ],
          ),
        ),
        DemoSection(
          title: 'Size, date and thumbnail, limited to 3',
          caption: 'Loading, error and warning tokens; dismiss removes a token.',
          child: CsFileTokenGroup(
            items: _items,
            showFileSize: true,
            showFileLastModified: true,
            showFileThumbnail: true,
            limit: 3,
            readOnly: _readOnly,
            alignment: _horizontal ? CsFileTokenGroupAlignment.horizontal : CsFileTokenGroupAlignment.vertical,
            onDismiss: (i) => setState(() => _items = [..._items]..removeAt(i)),
          ),
        ),
        DemoSection(
          title: 'Names only',
          child: CsFileTokenGroup(
            items: [for (final f in _sampleFiles.take(2)) CsFileTokenGroupItem(file: f)],
            onDismiss: (_) {},
          ),
        ),
      ],
    );
  }
}

class _FileUploadDemo extends StatefulWidget {
  const _FileUploadDemo();

  @override
  State<_FileUploadDemo> createState() => _FileUploadDemoState();
}

class _FileUploadDemoState extends State<_FileUploadDemo> {
  List<CsFile> _single = const [];
  List<CsFile> _multiple = const [];
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    final tooLarge = [for (final f in _multiple) f.size > 1000000 ? 'Files must be 1 MB or smaller.' : null];
    return DemoColumn(
      children: [
        DemoSection(
          title: 'Single file',
          child: CsFormField(
            label: 'Certificate',
            description: 'The certificate for the load balancer listener.',
            stretch: true,
            child: CsFileUpload(
              value: _single,
              accept: '.pem,.crt',
              constraintText: 'PEM or CRT, up to 1 MB.',
              showFileSize: true,
              showFileLastModified: true,
              errorText: _single.isEmpty
                  ? null
                  : (_single.first.name.endsWith('.crt') ? null : 'Choose a PEM or CRT file.'),
              onPick: _samplePicker,
              onChange: (f) => setState(() => _single = f),
            ),
          ),
        ),
        DemoSection(
          title: 'Multiple files with per-file errors',
          caption: 'Each pick adds two sample files. Files over 1 MB are flagged.',
          child: CsFileUpload(
            value: _multiple,
            multiple: true,
            tokenLimit: 3,
            showFileSize: true,
            showFileThumbnail: true,
            fileErrors: tooLarge,
            dropzoneActive: _dragging,
            constraintText: 'Up to 10 files, 1 MB each.',
            fileTokenAlignment: CsFileTokenGroupAlignment.horizontal,
            onPick: _samplePicker,
            onChange: (f) => setState(() => _multiple = f),
          ),
        ),
        DemoSection(
          title: 'Dragging over the app',
          child: CsCheckbox(
            checked: _dragging,
            label: 'Show the dropzone in place of the button',
            onChange: (v) => setState(() => _dragging = v),
          ),
        ),
      ],
    );
  }
}

class _PromptInputDemo extends StatefulWidget {
  const _PromptInputDemo();

  @override
  State<_PromptInputDemo> createState() => _PromptInputDemoState();
}

class _PromptInputDemoState extends State<_PromptInputDemo> {
  String _prompt = '';
  String _withActions = '';
  final List<String> _sent = [];
  List<CsFile> _attached = [];
  bool _invalid = false;
  bool _disabled = false;

  @override
  Widget build(BuildContext context) {
    return DemoColumn(
      children: [
        DemoSection(
          title: 'Send on Enter',
          caption: 'Shift+Enter adds a line; the field grows to 3 lines, then scrolls.',
          child: CsSpaceBetween(
            size: CsSpacingSize.s,
            children: [
              for (final m in _sent) CsBox(color: CsBoxColor.textBodySecondary, text: 'Sent: $m'),
              CsPromptInput(
                value: _prompt,
                placeholder: 'Ask a question about your instances',
                actionButtonIcon: CsIcons.send,
                disableActionButton: _prompt.trim().isEmpty,
                invalid: _invalid,
                disabled: _disabled,
                onChange: (v) => setState(() => _prompt = v),
                onAction: (v) {
                  if (v.trim().isEmpty) return;
                  setState(() {
                    _sent.add(v.trim());
                    _prompt = '';
                  });
                },
              ),
              Wrap(
                spacing: CsSpace.l,
                children: [
                  CsCheckbox(checked: _invalid, label: 'Invalid', onChange: (v) => setState(() => _invalid = v)),
                  CsCheckbox(checked: _disabled, label: 'Disabled', onChange: (v) => setState(() => _disabled = v)),
                ],
              ),
            ],
          ),
        ),
        DemoSection(
          title: 'Secondary actions and content',
          caption: 'Attach adds a sample file above the text; the send button moves to the action row.',
          child: CsPromptInput(
            value: _withActions,
            placeholder: 'Describe the distribution d111111abcdef8',
            actionButtonIcon: CsIcons.send,
            minRows: 2,
            maxRows: 6,
            onChange: (v) => setState(() => _withActions = v),
            onAction: (_) => setState(() {
              _withActions = '';
              _attached = [];
            }),
            secondaryContent: _attached.isEmpty
                ? null
                : CsFileTokenGroup(
                    alignment: CsFileTokenGroupAlignment.horizontal,
                    items: [for (final f in _attached) CsFileTokenGroupItem(file: f)],
                    onDismiss: (i) => setState(() => _attached = [..._attached]..removeAt(i)),
                  ),
            secondaryActions: CsFileInput(
              value: _attached,
              variant: CsFileInputVariant.icon,
              ariaLabel: 'Attach file',
              onPick: _samplePicker,
              onChange: (f) => setState(() => _attached = [..._attached, ...f]),
            ),
          ),
        ),
        DemoSection(
          title: 'Read-only and warning',
          child: CsSpaceBetween(
            size: CsSpacingSize.s,
            children: [
              CsPromptInput(
                value: 'Summarize the alarms for i-0abc123',
                readOnly: true,
                actionButtonIcon: CsIcons.send,
                onAction: (_) {},
              ),
              CsPromptInput(
                value: 'Delete every bucket',
                warning: true,
                actionButtonIcon: CsIcons.send,
                onAction: (_) {},
              ),
            ],
          ),
        ),
      ],
    );
  }
}

const _policy = '''{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicRead",
      "Effect": "Allow",
      "Principal": "*",
      "Action": ["s3:GetObject"],
      "Resource": ["arn:aws:s3:::example-bucket/*"]
    }
  ]
}''';

const _samples = {
  'json': _policy,
  'yaml':
      'Resources:\n  ExampleBucket:\n    Type: Bucket   # sample template\n    Properties:\n      Versioning: true\n',
  'javascript':
      "export async function handler(event) {\n  const id = event.instanceId ?? 'i-0abc123';\n  return { statusCode: 200, body: JSON.stringify({ id }) };\n}\n",
  'python':
      "def handler(event, context):\n    bucket = event.get('bucket', 'example-bucket')  # default\n    return {'status': 200, 'bucket': bucket}\n",
  'sh':
      '#!/bin/sh\nset -e\nBUCKET="example-bucket"\necho "Syncing to \$BUCKET" && sync ./site "s3://\$BUCKET" --delete\n',
};

class _CodeEditorDemo extends StatefulWidget {
  const _CodeEditorDemo();

  @override
  State<_CodeEditorDemo> createState() => _CodeEditorDemoState();
}

class _CodeEditorDemoState extends State<_CodeEditorDemo> {
  String _language = 'json';
  final Map<String, String> _values = Map.of(_samples);
  CsCodeEditorPreferences _prefs = const CsCodeEditorPreferences();
  bool _loading = false;

  List<CsCodeEditorAnnotation> _validate(String value) {
    if (_language == 'json') {
      final errors = CsCodeEditor.jsonValidator(value);
      if (errors.isNotEmpty) return errors;
      final row = value.split('\n').indexWhere((l) => l.contains('"Principal": "*"'));
      return [
        if (row >= 0)
          CsCodeEditorAnnotation(
            row: row,
            text: 'The policy grants access to everyone.',
            type: CsCodeEditorAnnotationType.warning,
          ),
      ];
    }
    return const [];
  }

  @override
  Widget build(BuildContext context) {
    return DemoColumn(
      children: [
        DemoSection(
          title: 'Language',
          child: Wrap(
            spacing: CsSpace.xs,
            runSpacing: CsSpace.xs,
            children: [
              for (final lang in _samples.keys)
                CsButton(
                  text: lang,
                  variant: lang == _language ? CsButtonVariant.primary : CsButtonVariant.normal,
                  onPress: () => setState(() => _language = lang),
                ),
            ],
          ),
        ),
        DemoSection(
          title: 'Bucket policy',
          caption: 'Break the JSON to see an error; the public principal is a warning. Use the cog for preferences.',
          child: CsCodeEditor(
            value: _values[_language]!,
            language: _language,
            loading: _loading,
            validator: _validate,
            preferences: _prefs,
            onPreferencesChange: (p) => setState(() => _prefs = p),
            onChange: (v) => setState(() => _values[_language] = v),
          ),
        ),
        DemoSection(
          title: 'Loading',
          child: CsCheckbox(
            checked: _loading,
            label: 'Show the loading state',
            onChange: (v) => setState(() => _loading = v),
          ),
        ),
      ],
    );
  }
}
