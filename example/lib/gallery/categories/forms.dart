import 'package:cloudscape_flutter/cloudscape_flutter.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../demo.dart';

/// Text inputs, form fields and forms, checkboxes, radio groups, toggles,
/// tiles, segmented controls and sliders. Every name and figure here is
/// sample data.
final CsDemoCategory formsCategory = CsDemoCategory(
  title: 'Forms',
  description:
      'Text inputs, form fields and forms, checkboxes, radio groups, toggles, tiles, segmented controls and sliders.',
  icon: CsIcons.edit,
  demos: [
    CsDemo(
      title: 'CsInput',
      description: 'Text, search, password and number inputs with prefix, suffix, inline label and every state.',
      docPath: 'doc/components/CsInput.md',
      builder: (_) => const _InputDemo(),
    ),
    CsDemo(
      title: 'CsFormField',
      description: 'Label, info link, description, constraint text, character count, errors and warnings.',
      docPath: 'doc/components/CsFormField.md',
      builder: (_) => const _FormFieldDemo(),
    ),
    CsDemo(
      title: 'CsTextarea',
      description: 'Multi-line text with fixed rows or growth, a character count and validation.',
      docPath: 'doc/components/CsTextarea.md',
      builder: (_) => const _TextareaDemo(),
    ),
    CsDemo(
      title: 'CsForm',
      description: 'A create flow with header, fields, a form-level error and the action row.',
      docPath: 'doc/components/CsForm.md',
      builder: (_) => const _FormDemo(),
    ),
    CsDemo(
      title: 'CsCheckbox',
      description: 'Checked, indeterminate "select all", descriptions, disabled and read-only.',
      docPath: 'doc/components/CsCheckbox.md',
      builder: (_) => const _CheckboxDemo(),
    ),
    CsDemo(
      title: 'CsRadioGroup',
      description: 'Vertical and horizontal groups with descriptions, disabled items and arrow keys.',
      docPath: 'doc/components/CsRadioGroup.md',
      builder: (_) => const _RadioGroupDemo(),
    ),
    CsDemo(
      title: 'CsRadioButton',
      description: 'Standalone radio buttons for custom single-choice layouts.',
      docPath: 'doc/components/CsRadioButton.md',
      builder: (_) => const _RadioButtonDemo(),
    ),
    CsDemo(
      title: 'CsToggle',
      description: 'Switches that apply at once: tap or drag the handle, with descriptions and states.',
      docPath: 'doc/components/CsToggle.md',
      builder: (_) => const _ToggleDemo(),
    ),
    CsDemo(
      title: 'CsTiles',
      description: 'Single choice as cards, with images, responsive columns, disabled and read-only.',
      docPath: 'doc/components/CsTiles.md',
      builder: (_) => const _TilesDemo(),
    ),
    CsDemo(
      title: 'CsSegmentedControl',
      description: 'Text and icon segments; becomes a select at or below 688px.',
      docPath: 'doc/components/CsSegmentedControl.md',
      builder: (_) => const _SegmentedControlDemo(),
    ),
    CsDemo(
      title: 'CsSlider',
      description: 'Continuous and stepped sliders with tick marks, reference values and validation.',
      docPath: 'doc/components/CsSlider.md',
      builder: (_) => const _SliderDemo(),
    ),
    CsDemo(
      title: 'CsFieldBox',
      description: 'The field chrome and editable core that CsInput and CsTextarea are built from.',
      docPath: 'doc/components/CsFieldBox.md',
      builder: (_) => const _FieldBoxDemo(),
    ),
  ],
);

class _InputDemo extends StatefulWidget {
  const _InputDemo();

  @override
  State<_InputDemo> createState() => _InputDemoState();
}

class _InputDemoState extends State<_InputDemo> {
  String _name = 'example-bucket';
  String _query = '';
  String _password = '';
  String _size = '100';
  String _domain = 'logs';
  String _region = '';
  String _lastKey = 'none';

  @override
  Widget build(BuildContext context) {
    return DemoColumn(
      children: [
        DemoSection(
          title: 'Text',
          caption: 'Press Escape while typing to see onKeyEvent.',
          child: CsSpaceBetween(
            size: CsSpacingSize.xs,
            children: [
              CsInput(
                value: _name,
                placeholder: 'example-bucket',
                ariaLabel: 'Bucket name',
                onChange: (v) => setState(() => _name = v),
                onKeyEvent: (node, event) {
                  if (event is KeyDownEvent) setState(() => _lastKey = event.logicalKey.keyLabel);
                  return KeyEventResult.ignored;
                },
              ),
              CsBox(variant: CsBoxVariant.small, text: 'Value: "$_name". Last key: $_lastKey.'),
            ],
          ),
        ),
        DemoSection(
          title: 'Search, password and number',
          child: CsSpaceBetween(
            size: CsSpacingSize.xs,
            children: [
              CsInput(
                type: CsInputType.search,
                value: _query,
                placeholder: 'Find instances',
                ariaLabel: 'Find instances',
                onChange: (v) => setState(() => _query = v),
              ),
              CsInput(
                type: CsInputType.password,
                value: _password,
                placeholder: 'Database password',
                ariaLabel: 'Database password',
                onChange: (v) => setState(() => _password = v),
              ),
              CsInput(
                type: CsInputType.number,
                value: _size,
                ariaLabel: 'Volume size',
                suffix: const Text('GiB'),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChange: (v) => setState(() => _size = v),
              ),
            ],
          ),
        ),
        DemoSection(
          title: 'Prefix, suffix and inline label',
          child: CsSpaceBetween(
            size: CsSpacingSize.s,
            children: [
              CsInput(
                value: _domain,
                prefix: const Text('https://'),
                suffix: const Text('.example.com'),
                ariaLabel: 'Subdomain',
                onChange: (v) => setState(() => _domain = v),
              ),
              CsInput(
                value: _region,
                inlineLabelText: 'Region',
                placeholder: 'us-east-1',
                onChange: (v) => setState(() => _region = v),
              ),
            ],
          ),
        ),
        DemoSection(
          title: 'States',
          child: CsSpaceBetween(
            size: CsSpacingSize.xs,
            children: [
              CsInput(value: 'Bucket_Name', invalid: true, ariaLabel: 'Invalid', onChange: (_) {}),
              CsInput(value: 'my-bucket', warning: true, ariaLabel: 'Warning', onChange: (_) {}),
              CsInput(value: 'i-0abc123', readOnly: true, mono: true, ariaLabel: 'Instance ID', onChange: (_) {}),
              CsInput(value: '', disabled: true, placeholder: 'Disabled', ariaLabel: 'Disabled', onChange: (_) {}),
            ],
          ),
        ),
      ],
    );
  }
}

class _FormFieldDemo extends StatefulWidget {
  const _FormFieldDemo();

  @override
  State<_FormFieldDemo> createState() => _FormFieldDemoState();
}

class _FormFieldDemoState extends State<_FormFieldDemo> {
  String _name = 'Example_Bucket';
  String _tag = 'production';
  final List<String> _keys = ['team', 'cost-center'];

  String? get _nameError {
    if (_name.isEmpty) return 'Enter a bucket name.';
    if (_name.contains(RegExp('[A-Z_]'))) return 'Use only lowercase letters, numbers, dots and hyphens.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return DemoColumn(
      children: [
        DemoSection(
          title: 'Label, info, description and live validation',
          caption: 'Fix the name to clear the error. The control takes two thirds of the width on wide screens.',
          child: CsFormField(
            label: 'Bucket name',
            info: CsLink(text: 'Info', variant: CsLinkVariant.info, onFollow: () {}),
            description: 'The name must be unique across all accounts.',
            constraintText: 'Use 3 to 63 characters.',
            characterCountText: '${_name.length}/63',
            errorText: _nameError,
            child: CsInput(value: _name, invalid: _nameError != null, onChange: (v) => setState(() => _name = v)),
          ),
        ),
        DemoSection(
          title: 'Warning and stretch',
          child: CsFormField(
            label: 'Tag value',
            stretch: true,
            warningText: _tag == 'production' ? 'Changing production tags can affect cost reports.' : null,
            child: CsInput(value: _tag, warning: _tag == 'production', onChange: (v) => setState(() => _tag = v)),
          ),
        ),
        DemoSection(
          title: 'Secondary control',
          caption: 'Below 688px the Remove button moves under the field.',
          child: CsSpaceBetween(
            size: CsSpacingSize.s,
            children: [
              for (var i = 0; i < _keys.length; i++)
                CsFormField(
                  label: 'Tag key ${i + 1}',
                  secondaryControl: CsButton(text: 'Remove', onPress: () => setState(() => _keys.removeAt(i))),
                  child: CsInput(value: _keys[i], onChange: (v) => setState(() => _keys[i] = v)),
                ),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: CsButton(
                  text: 'Add tag',
                  disabled: _keys.length >= 4,
                  onPress: () => setState(() => _keys.add('')),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TextareaDemo extends StatefulWidget {
  const _TextareaDemo();

  @override
  State<_TextareaDemo> createState() => _TextareaDemoState();
}

class _TextareaDemoState extends State<_TextareaDemo> {
  static const _limit = 200;
  String _description = 'Stores access logs for the d111111abcdef8 distribution.';
  String _notes = '';
  String _policy = '{\n  "Version": "2012-10-17"\n}';

  @override
  Widget build(BuildContext context) {
    final over = _description.length > _limit;
    return DemoColumn(
      children: [
        DemoSection(
          title: 'Character count',
          child: CsFormField(
            label: 'Description',
            constraintText: 'Up to $_limit characters.',
            characterCountText: '${_description.length}/$_limit',
            errorText: over ? 'The description is ${_description.length - _limit} characters too long.' : null,
            child: CsTextarea(value: _description, invalid: over, onChange: (v) => setState(() => _description = v)),
          ),
        ),
        DemoSection(
          title: 'Grows with its content',
          caption: 'Starts at 2 rows and grows to 6, then scrolls.',
          child: CsTextarea(
            value: _notes,
            rows: 2,
            maxRows: 6,
            placeholder: 'Notes for the on-call engineer',
            ariaLabel: 'Notes',
            onChange: (v) => setState(() => _notes = v),
          ),
        ),
        DemoSection(
          title: 'Monospace, read-only and disabled',
          child: CsSpaceBetween(
            size: CsSpacingSize.xs,
            children: [
              CsTextarea(
                value: _policy,
                mono: true,
                rows: 4,
                spellcheck: false,
                ariaLabel: 'Bucket policy',
                onChange: (v) => setState(() => _policy = v),
              ),
              CsTextarea(value: 'Created by the deployment pipeline.', readOnly: true, rows: 2, onChange: (_) {}),
              CsTextarea(value: '', placeholder: 'Disabled', disabled: true, rows: 2, onChange: (_) {}),
            ],
          ),
        ),
      ],
    );
  }
}

class _FormDemo extends StatefulWidget {
  const _FormDemo();

  @override
  State<_FormDemo> createState() => _FormDemoState();
}

class _FormDemoState extends State<_FormDemo> {
  String _name = '';
  String _region = 'us-east-1';
  bool _versioning = true;
  bool _submitted = false;
  bool _saving = false;
  String? _formError;
  String _status = 'Not submitted';

  String? get _nameError => _submitted && _name.isEmpty ? 'Enter a bucket name.' : null;

  Future<void> _submit() async {
    setState(() {
      _submitted = true;
      _formError = null;
    });
    if (_name.isEmpty) return;
    setState(() => _saving = true);
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (_name == 'example-bucket') {
        _formError = 'A bucket named example-bucket already exists in this account. Choose another name.';
      } else {
        _status = 'Created $_name in $_region (sample data).';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DemoColumn(
      children: [
        DemoSection(
          title: 'Create flow',
          caption: 'Submit empty to see field validation; name it example-bucket to see the form error.',
          child: CsForm(
            header: const CsHeader(
              variant: CsHeaderVariant.h1,
              title: 'Create bucket',
              description: 'Buckets are containers for objects stored in the sample account.',
            ),
            errorText: _formError,
            secondaryActions: CsButton(text: 'Save draft', onPress: () => setState(() => _status = 'Draft saved')),
            actions: CsSpaceBetween(
              direction: CsSpaceBetweenDirection.horizontal,
              size: CsSpacingSize.xs,
              children: [
                CsButton(
                  text: 'Cancel',
                  variant: CsButtonVariant.link,
                  onPress: () => setState(() {
                    _name = '';
                    _submitted = false;
                    _formError = null;
                    _status = 'Cancelled';
                  }),
                ),
                CsButton(
                  text: 'Create bucket',
                  variant: CsButtonVariant.primary,
                  loading: _saving,
                  loadingText: 'Creating bucket',
                  onPress: _submit,
                ),
              ],
            ),
            child: CsContainer(
              header: const CsHeader(title: 'General configuration'),
              child: CsSpaceBetween(
                size: CsSpacingSize.l,
                children: [
                  CsFormField(
                    label: 'Bucket name',
                    errorText: _nameError,
                    child: CsInput(
                      value: _name,
                      invalid: _nameError != null,
                      placeholder: 'example-bucket',
                      onChange: (v) => setState(() => _name = v),
                    ),
                  ),
                  CsFormField(
                    label: 'Region',
                    child: CsRadioGroup(
                      value: _region,
                      direction: CsRadioGroupDirection.horizontal,
                      onChange: (v) => setState(() => _region = v),
                      items: const [
                        CsRadioGroupItem(value: 'us-east-1', label: 'us-east-1'),
                        CsRadioGroupItem(value: 'eu-west-1', label: 'eu-west-1'),
                        CsRadioGroupItem(value: 'ap-southeast-1', label: 'ap-southeast-1'),
                      ],
                    ),
                  ),
                  CsCheckbox(
                    checked: _versioning,
                    label: 'Enable versioning',
                    onChange: (v) => setState(() => _versioning = v),
                  ),
                ],
              ),
            ),
          ),
        ),
        DemoSection(
          title: 'Result',
          child: CsBox(text: _status),
        ),
      ],
    );
  }
}

class _CheckboxDemo extends StatefulWidget {
  const _CheckboxDemo();

  @override
  State<_CheckboxDemo> createState() => _CheckboxDemoState();
}

class _CheckboxDemoState extends State<_CheckboxDemo> {
  bool _terms = false;
  final Map<String, bool> _instances = {'i-0abc123': true, 'i-0def456': false, 'i-0aa1122': false};

  @override
  Widget build(BuildContext context) {
    final selected = _instances.values.where((v) => v).length;
    final all = selected == _instances.length;
    return DemoColumn(
      children: [
        DemoSection(
          title: 'Single choice with description',
          child: CsCheckbox(
            checked: _terms,
            label: 'Delete objects permanently',
            description: 'Deleted objects can’t be recovered.',
            onChange: (v) => setState(() => _terms = v),
          ),
        ),
        DemoSection(
          title: 'Select all (indeterminate)',
          child: CsSpaceBetween(
            size: CsSpacingSize.xs,
            children: [
              CsCheckbox(
                checked: all,
                indeterminate: selected > 0 && !all,
                label: 'All instances ($selected of ${_instances.length})',
                onChange: (v) => setState(() => _instances.updateAll((_, _) => v)),
              ),
              for (final id in _instances.keys)
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: CsSpace.l),
                  child: CsCheckbox(
                    checked: _instances[id]!,
                    label: id,
                    onChange: (v) => setState(() => _instances[id] = v),
                  ),
                ),
            ],
          ),
        ),
        DemoSection(
          title: 'Disabled, read-only and no label',
          child: CsSpaceBetween(
            size: CsSpacingSize.xs,
            children: [
              CsCheckbox(checked: true, disabled: true, label: 'Encryption (required)', onChange: (_) {}),
              CsCheckbox(checked: false, disabled: true, label: 'Object lock (unavailable)', onChange: (_) {}),
              CsCheckbox(checked: true, readOnly: true, label: 'Block public access', onChange: (_) {}),
              CsCheckbox(checked: _terms, ariaLabel: 'Select row', onChange: (v) => setState(() => _terms = v)),
            ],
          ),
        ),
      ],
    );
  }
}

class _RadioGroupDemo extends StatefulWidget {
  const _RadioGroupDemo();

  @override
  State<_RadioGroupDemo> createState() => _RadioGroupDemoState();
}

class _RadioGroupDemoState extends State<_RadioGroupDemo> {
  String? _storage = 'standard';
  String? _protocol = 'https';

  @override
  Widget build(BuildContext context) {
    return DemoColumn(
      children: [
        DemoSection(
          title: 'Vertical with descriptions',
          caption: 'Tab into the group, then use the arrow keys. Archive is disabled and skipped.',
          child: CsFormField(
            label: 'Storage class',
            child: CsRadioGroup(
              value: _storage,
              onChange: (v) => setState(() => _storage = v),
              items: const [
                CsRadioGroupItem(value: 'standard', label: 'Standard', description: 'For frequently accessed data.'),
                CsRadioGroupItem(
                  value: 'ia',
                  label: 'Infrequent access',
                  description: 'Lower storage price, with a retrieval fee.',
                ),
                CsRadioGroupItem(
                  value: 'archive',
                  label: 'Archive',
                  description: 'Not available in this sample account.',
                  disabled: true,
                ),
              ],
            ),
          ),
        ),
        DemoSection(
          title: 'Horizontal',
          child: CsRadioGroup(
            value: _protocol,
            direction: CsRadioGroupDirection.horizontal,
            ariaLabel: 'Origin protocol',
            onChange: (v) => setState(() => _protocol = v),
            items: const [
              CsRadioGroupItem(value: 'http', label: 'HTTP only'),
              CsRadioGroupItem(value: 'https', label: 'HTTPS only'),
              CsRadioGroupItem(value: 'match', label: 'Match viewer'),
            ],
          ),
        ),
        DemoSection(
          title: 'Read-only and cleared',
          child: CsSpaceBetween(
            size: CsSpacingSize.s,
            children: [
              CsRadioGroup(
                value: 'https',
                readOnly: true,
                ariaLabel: 'Viewer protocol (read-only)',
                onChange: (_) {},
                items: const [
                  CsRadioGroupItem(value: 'http', label: 'HTTP and HTTPS'),
                  CsRadioGroupItem(value: 'https', label: 'Redirect HTTP to HTTPS'),
                ],
              ),
              CsButton(text: 'Clear storage class', onPress: () => setState(() => _storage = null)),
            ],
          ),
        ),
      ],
    );
  }
}

class _RadioButtonDemo extends StatefulWidget {
  const _RadioButtonDemo();

  @override
  State<_RadioButtonDemo> createState() => _RadioButtonDemoState();
}

class _RadioButtonDemoState extends State<_RadioButtonDemo> {
  String _plan = 'on-demand';

  @override
  Widget build(BuildContext context) {
    Widget option(String value, String label, String price) => Row(
      children: [
        Expanded(
          child: CsRadioButton(checked: _plan == value, label: label, onSelect: () => setState(() => _plan = value)),
        ),
        CsBox(variant: CsBoxVariant.small, color: CsBoxColor.textBodySecondary, text: price),
      ],
    );
    return DemoColumn(
      children: [
        DemoSection(
          title: 'Custom layout',
          caption: 'Standalone radios in a priced list. Prices are sample data.',
          child: CsSpaceBetween(
            size: CsSpacingSize.xs,
            children: [
              option('on-demand', 'On-Demand', r'$0.0416 per hour'),
              option('reserved', 'Reserved, 1 year', r'$0.0262 per hour'),
              option('spot', 'Spot', r'$0.0125 per hour'),
            ],
          ),
        ),
        DemoSection(
          title: 'States',
          child: CsSpaceBetween(
            size: CsSpacingSize.xs,
            children: [
              CsRadioButton(
                checked: true,
                label: 'With description',
                description: 'Description text sits under the label.',
                onSelect: () {},
              ),
              CsRadioButton(checked: true, disabled: true, label: 'Disabled, checked', onSelect: () {}),
              CsRadioButton(checked: false, disabled: true, label: 'Disabled', onSelect: () {}),
              CsRadioButton(checked: true, readOnly: true, label: 'Read-only', onSelect: () {}),
            ],
          ),
        ),
      ],
    );
  }
}

class _ToggleDemo extends StatefulWidget {
  const _ToggleDemo();

  @override
  State<_ToggleDemo> createState() => _ToggleDemoState();
}

class _ToggleDemoState extends State<_ToggleDemo> {
  bool _monitoring = true;
  bool _termination = false;
  bool _ipv6 = false;

  @override
  Widget build(BuildContext context) {
    return DemoColumn(
      children: [
        DemoSection(
          title: 'Settings that apply at once',
          caption: 'Tap the toggle or its label, or drag the handle with a finger.',
          child: CsSpaceBetween(
            size: CsSpacingSize.s,
            children: [
              CsToggle(
                checked: _monitoring,
                label: 'Detailed monitoring',
                description: 'Collects metrics for i-0abc123 every minute.',
                onChange: (v) => setState(() => _monitoring = v),
              ),
              CsToggle(
                checked: _termination,
                label: 'Termination protection',
                onChange: (v) => setState(() => _termination = v),
              ),
              CsToggle(checked: _ipv6, ariaLabel: 'IPv6', onChange: (v) => setState(() => _ipv6 = v)),
            ],
          ),
        ),
        DemoSection(
          title: 'Disabled and read-only',
          child: CsSpaceBetween(
            size: CsSpacingSize.s,
            children: [
              CsToggle(checked: true, disabled: true, label: 'Disabled, on', onChange: (_) {}),
              CsToggle(checked: false, disabled: true, label: 'Disabled, off', onChange: (_) {}),
              CsToggle(checked: true, readOnly: true, label: 'Read-only, on', onChange: (_) {}),
              CsToggle(checked: false, readOnly: true, label: 'Read-only, off', onChange: (_) {}),
            ],
          ),
        ),
      ],
    );
  }
}

class _TilesDemo extends StatefulWidget {
  const _TilesDemo();

  @override
  State<_TilesDemo> createState() => _TilesDemoState();
}

class _TilesDemoState extends State<_TilesDemo> {
  String? _engine = 'postgres';
  String? _size = 'small';
  int _columns = 3;

  Widget _image(CsIconData icon) => Padding(
    padding: const EdgeInsets.only(top: CsSpace.xxs),
    child: CsIcon(icon, size: CsIconSize.big, variant: CsIconVariant.subtle),
  );

  @override
  Widget build(BuildContext context) {
    return DemoColumn(
      children: [
        DemoSection(
          title: 'With descriptions and images',
          caption: 'Columns adapt: one under 465px, two under 688px. Change the wide-screen count below.',
          child: CsSpaceBetween(
            size: CsSpacingSize.s,
            children: [
              CsSegmentedControl(
                label: 'Columns',
                selectedId: '$_columns',
                presentation: CsSegmentedControlPresentation.segments,
                onChange: (id) => setState(() => _columns = int.parse(id)),
                options: const [
                  CsSegmentedControlOption(id: '1', text: '1'),
                  CsSegmentedControlOption(id: '2', text: '2'),
                  CsSegmentedControlOption(id: '3', text: '3'),
                  CsSegmentedControlOption(id: '4', text: '4'),
                ],
              ),
              CsFormField(
                label: 'Engine',
                stretch: true,
                child: CsTiles(
                  value: _engine,
                  columns: _columns,
                  onChange: (v) => setState(() => _engine = v),
                  items: [
                    CsTilesItem(
                      value: 'mysql',
                      label: 'MySQL',
                      description: 'Open-source relational database.',
                      image: _image(CsIcons.script),
                    ),
                    CsTilesItem(
                      value: 'postgres',
                      label: 'PostgreSQL',
                      description: 'Extensible relational database with JSON support.',
                      image: _image(CsIcons.file),
                    ),
                    CsTilesItem(
                      value: 'mariadb',
                      label: 'MariaDB',
                      description: 'Community-developed fork of MySQL.',
                      image: _image(CsIcons.folder),
                    ),
                    CsTilesItem(
                      value: 'oracle',
                      label: 'Oracle',
                      description: 'Not available in this sample account.',
                      image: _image(CsIcons.lockPrivate),
                      disabled: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        DemoSection(
          title: 'Default columns and read-only',
          child: CsSpaceBetween(
            size: CsSpacingSize.s,
            children: [
              CsTiles(
                value: _size,
                ariaLabel: 'Instance size',
                onChange: (v) => setState(() => _size = v),
                items: const [
                  CsTilesItem(value: 'small', label: 'Small', description: '2 vCPU, 4 GiB'),
                  CsTilesItem(value: 'medium', label: 'Medium', description: '4 vCPU, 16 GiB'),
                  CsTilesItem(value: 'large', label: 'Large', description: '8 vCPU, 32 GiB'),
                ],
              ),
              CsTiles(
                value: 'medium',
                readOnly: true,
                ariaLabel: 'Instance size (read-only)',
                onChange: (_) {},
                items: const [
                  CsTilesItem(value: 'small', label: 'Small'),
                  CsTilesItem(value: 'medium', label: 'Medium'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SegmentedControlDemo extends StatefulWidget {
  const _SegmentedControlDemo();

  @override
  State<_SegmentedControlDemo> createState() => _SegmentedControlDemoState();
}

class _SegmentedControlDemoState extends State<_SegmentedControlDemo> {
  String _range = '3h';
  String _view = 'list';

  @override
  Widget build(BuildContext context) {
    return DemoColumn(
      children: [
        DemoSection(
          title: 'Text segments',
          caption: 'At or below 688px this shows a select. 1w needs detailed monitoring and explains why on hover.',
          child: CsSegmentedControl(
            label: 'Time range',
            selectedId: _range,
            onChange: (id) => setState(() => _range = id),
            options: const [
              CsSegmentedControlOption(id: '1h', text: '1h'),
              CsSegmentedControlOption(id: '3h', text: '3h'),
              CsSegmentedControlOption(id: '12h', text: '12h'),
              CsSegmentedControlOption(id: '1d', text: '1d'),
              CsSegmentedControlOption(
                id: '1w',
                text: '1w',
                disabled: true,
                disabledReason: 'Turn on detailed monitoring to see a week of data.',
              ),
            ],
          ),
        ),
        DemoSection(
          title: 'Icons, always segments',
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: CsSegmentedControl(
              label: 'Layout',
              selectedId: _view,
              presentation: CsSegmentedControlPresentation.segments,
              onChange: (id) => setState(() => _view = id),
              options: const [
                CsSegmentedControlOption(id: 'list', icon: CsIcons.listView, iconAlt: 'List'),
                CsSegmentedControlOption(id: 'grid', icon: CsIcons.gridView, iconAlt: 'Grid'),
                CsSegmentedControlOption(id: 'map', icon: CsIcons.map, text: 'Map'),
              ],
            ),
          ),
        ),
        DemoSection(
          title: 'Always a select',
          child: CsSegmentedControl(
            label: 'Layout',
            selectedId: _view,
            presentation: CsSegmentedControlPresentation.select,
            onChange: (id) => setState(() => _view = id),
            options: const [
              CsSegmentedControlOption(id: 'list', icon: CsIcons.listView, text: 'List'),
              CsSegmentedControlOption(id: 'grid', icon: CsIcons.gridView, text: 'Grid'),
              CsSegmentedControlOption(id: 'map', icon: CsIcons.map, text: 'Map'),
            ],
          ),
        ),
      ],
    );
  }
}

class _SliderDemo extends StatefulWidget {
  const _SliderDemo();

  @override
  State<_SliderDemo> createState() => _SliderDemoState();
}

class _SliderDemoState extends State<_SliderDemo> {
  double _opacity = 40;
  double _capacity = 60;
  double _instances = 4;
  double _committed = 4;

  @override
  Widget build(BuildContext context) {
    final overBudget = _capacity > 80;
    return DemoColumn(
      children: [
        DemoSection(
          title: 'Continuous',
          child: CsFormField(
            label: 'Overlay opacity',
            child: CsSlider(
              min: 0,
              max: 100,
              value: _opacity,
              valueFormatter: (v) => '${v.round()}%',
              onChange: (v) => setState(() => _opacity = v),
            ),
          ),
        ),
        DemoSection(
          title: 'Stepped with tick marks and reference values',
          caption: 'Above 80% the slider shows a warning. Haptics fire at each step.',
          child: CsFormField(
            label: 'Target utilization',
            warningText: overBudget ? 'High targets leave little room for traffic spikes.' : null,
            child: CsSlider(
              min: 0,
              max: 100,
              step: 10,
              tickMarks: true,
              referenceValues: const [25, 50, 75],
              value: _capacity,
              warning: overBudget,
              valueFormatter: (v) => '${v.round()}%',
              onChange: (v) => setState(() => _capacity = v),
            ),
          ),
        ),
        DemoSection(
          title: 'Commit on release',
          child: CsFormField(
            label: 'Desired instances',
            description: 'Saved: ${_committed.round()} instances.',
            child: CsSlider(
              min: 1,
              max: 10,
              step: 1,
              tickMarks: true,
              value: _instances,
              onChange: (v) => setState(() => _instances = v),
              onChangeEnd: (v) => setState(() => _committed = v),
            ),
          ),
        ),
        DemoSection(
          title: 'Invalid, read-only and disabled',
          child: CsSpaceBetween(
            size: CsSpacingSize.xs,
            children: [
              CsSlider(min: 0, max: 10, value: 9, invalid: true, ariaLabel: 'Invalid', onChange: (_) {}),
              CsSlider(min: 0, max: 10, value: 4, readOnly: true, ariaLabel: 'Read-only', onChange: (_) {}),
              CsSlider(min: 0, max: 10, value: 4, disabled: true, ariaLabel: 'Disabled', onChange: (_) {}),
              CsSlider(min: 0, max: 10, value: 6, hideFillLine: true, ariaLabel: 'No fill', onChange: (_) {}),
            ],
          ),
        ),
      ],
    );
  }
}

class _FieldBoxDemo extends StatefulWidget {
  const _FieldBoxDemo();

  @override
  State<_FieldBoxDemo> createState() => _FieldBoxDemoState();
}

class _FieldBoxDemoState extends State<_FieldBoxDemo> {
  final _controller = TextEditingController(text: 'arn:aws:s3:::example-bucket');
  final _focus = FocusNode();
  CsFieldStatus _status = CsFieldStatus.none;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DemoColumn(
      children: [
        DemoSection(
          title: 'Custom field from CsFieldBox and CsEditable',
          caption: 'A copyable ARN field: the chrome, focus ring and status come from CsFieldBox.',
          child: CsFieldBox(
            focused: _focus.hasFocus,
            status: _status,
            trailing: CsButton(
              icon: CsIcons.copy,
              variant: CsButtonVariant.inlineIcon,
              semanticLabel: 'Copy ARN',
              onPress: () => Clipboard.setData(ClipboardData(text: _controller.text)),
            ),
            child: CsEditable(controller: _controller, focusNode: _focus, mono: true, semanticLabel: 'Bucket ARN'),
          ),
        ),
        DemoSection(
          title: 'Status',
          child: CsSegmentedControl(
            label: 'Field status',
            selectedId: _status.name,
            presentation: CsSegmentedControlPresentation.segments,
            onChange: (id) => setState(() => _status = CsFieldStatus.values.byName(id)),
            options: const [
              CsSegmentedControlOption(id: 'none', text: 'None'),
              CsSegmentedControlOption(id: 'invalid', text: 'Invalid'),
              CsSegmentedControlOption(id: 'warning', text: 'Warning'),
            ],
          ),
        ),
        const DemoSection(
          title: 'Disabled and read-only chrome',
          child: CsSpaceBetween(
            size: CsSpacingSize.xs,
            children: [
              CsFieldBox(disabled: true, child: Text('Disabled field box')),
              CsFieldBox(readOnly: true, child: Text('Read-only field box')),
            ],
          ),
        ),
      ],
    );
  }
}
