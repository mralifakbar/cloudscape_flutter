import 'dart:async';

import 'package:cloudscape_flutter/cloudscape_flutter.dart';
import 'package:flutter/widgets.dart';

import '../demo.dart';

/// Avatars, chat bubbles, loading bars, support prompts and code view for generative AI experiences. Every name and figure here is sample data.
final CsDemoCategory genaiCategory = CsDemoCategory(
  title: 'Generative AI',
  description: 'Avatars, chat bubbles, loading bars, support prompts and code view for generative AI experiences.',
  icon: CsIcons.genAi,
  demos: [
    CsDemo(
      title: 'CsAvatar',
      description: 'People and AI assistants, with initials, icons, sizes, tooltips and the loading state.',
      docPath: 'doc/components/CsAvatar.md',
      builder: (_) => const _AvatarDemo(),
    ),
    CsDemo(
      title: 'CsChatBubble',
      description: 'A sample conversation: incoming and outgoing messages, actions, a streaming response.',
      docPath: 'doc/components/CsChatBubble.md',
      builder: (_) => const _ChatBubbleDemo(),
    ),
    CsDemo(
      title: 'CsLoadingBar',
      description: 'The gen-AI gradient bar, full and masked, shown only while a process runs.',
      docPath: 'doc/components/CsLoadingBar.md',
      builder: (_) => const _LoadingBarDemo(),
    ),
    CsDemo(
      title: 'CsSupportPromptGroup',
      description: 'Suggested prompts, vertical and horizontal, with icons and arrow-key navigation.',
      docPath: 'doc/components/CsSupportPromptGroup.md',
      builder: (_) => const _SupportPromptDemo(),
    ),
    CsDemo(
      title: 'CsCodeView',
      description: 'Highlighted snippets in six languages, line numbers, wrapping and a copy button.',
      docPath: 'doc/components/CsCodeView.md',
      builder: (_) => const _CodeViewDemo(),
    ),
  ],
);

const _assistant = CsAvatar(
  color: CsAvatarColor.genAi,
  icon: CsIcons.genAi,
  ariaLabel: 'Generative AI assistant',
  tooltipText: 'Generative AI assistant',
);

class _AvatarDemo extends StatefulWidget {
  const _AvatarDemo();

  @override
  State<_AvatarDemo> createState() => _AvatarDemoState();
}

class _AvatarDemoState extends State<_AvatarDemo> {
  bool _loading = true;

  @override
  Widget build(BuildContext context) {
    return DemoColumn(
      children: [
        const DemoSection(
          title: 'People',
          caption: 'Default color with the user-profile icon or initials. Hover or focus for the tooltip.',
          child: Wrap(
            spacing: CsSpace.m,
            runSpacing: CsSpace.m,
            children: [
              CsAvatar(ariaLabel: 'Avatar of a user'),
              CsAvatar(ariaLabel: 'Avatar of the sample user', initials: 'SU', tooltipText: 'Account'),
              CsAvatar(ariaLabel: 'Avatar of Mateo Jackson', initials: 'MJ', tooltipText: 'Mateo Jackson'),
            ],
          ),
        ),
        const DemoSection(
          title: 'Generative AI assistant',
          caption: 'The gen-AI gradient with the gen-ai icon or initials.',
          child: Wrap(
            spacing: CsSpace.m,
            children: [
              _assistant,
              CsAvatar(color: CsAvatarColor.genAi, initials: 'AI', ariaLabel: 'Assistant'),
            ],
          ),
        ),
        DemoSection(
          title: 'Loading',
          caption: 'The dots and gradient move only while loading is on.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: CsSpace.s,
            children: [
              Wrap(
                spacing: CsSpace.m,
                children: [
                  CsAvatar(
                    color: CsAvatarColor.genAi,
                    icon: CsIcons.genAi,
                    loading: _loading,
                    ariaLabel: 'Generative AI assistant, generating',
                  ),
                  CsAvatar(initials: 'SU', loading: _loading, ariaLabel: 'Sample user, typing'),
                ],
              ),
              CsCheckbox(checked: _loading, label: 'Loading', onChange: (v) => setState(() => _loading = v)),
            ],
          ),
        ),
        const DemoSection(
          title: 'Sizes',
          caption: 'width 28 (default and minimum), 36 and 48.',
          child: Wrap(
            spacing: CsSpace.m,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              CsAvatar(ariaLabel: 'Account', initials: 'SU'),
              CsAvatar(ariaLabel: 'Account', initials: 'SU', width: 36),
              CsAvatar(ariaLabel: 'Assistant', color: CsAvatarColor.genAi, icon: CsIcons.genAi, width: 48),
            ],
          ),
        ),
      ],
    );
  }
}

class _Message {
  const _Message(this.outgoing, this.text, this.time);
  final bool outgoing;
  final String text;
  final String time;
}

class _ChatBubbleDemo extends StatefulWidget {
  const _ChatBubbleDemo();

  @override
  State<_ChatBubbleDemo> createState() => _ChatBubbleDemoState();
}

class _ChatBubbleDemoState extends State<_ChatBubbleDemo> {
  final List<_Message> _messages = [
    const _Message(true, 'Is versioning enabled on example-bucket?', '3:41pm'),
    const _Message(false, 'Yes. Versioning has been enabled on example-bucket since it was created.', '3:41pm'),
    const _Message(false, 'It currently keeps 3 noncurrent versions per object.', '3:41pm'),
  ];
  bool _generating = false;
  bool _stretch = false;
  Timer? _timer;
  String? _feedback;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _ask() {
    setState(() {
      _messages.add(const _Message(true, 'How much storage does it use?', '3:42pm'));
      _generating = true;
    });
    _timer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() {
        _generating = false;
        _messages.add(const _Message(false, 'example-bucket stores 1.2 TB across 48,210 objects.', '3:42pm'));
      });
    });
  }

  Widget _bubble(int i) {
    final m = _messages[i];
    final sameAuthor = i > 0 && _messages[i - 1].outgoing == m.outgoing;
    return CsChatBubble(
      type: m.outgoing ? CsChatBubbleType.outgoing : CsChatBubbleType.incoming,
      ariaLabel: '${m.outgoing ? 'Account' : 'Generative AI assistant'} at ${m.time}',
      hideAvatar: sameAuthor,
      stretch: _stretch && !m.outgoing,
      avatar: m.outgoing ? const CsAvatar(ariaLabel: 'Account', initials: 'SU', tooltipText: 'Account') : _assistant,
      actions: m.outgoing || i != _messages.length - 1
          ? null
          : Wrap(
              spacing: CsSpace.xxs,
              children: [
                CsButton(
                  variant: CsButtonVariant.icon,
                  icon: _feedback == 'up' ? CsIcons.thumbsUpFilled : CsIcons.thumbsUp,
                  semanticLabel: 'Helpful',
                  onPress: () => setState(() => _feedback = 'up'),
                ),
                CsButton(
                  variant: CsButtonVariant.icon,
                  icon: _feedback == 'down' ? CsIcons.thumbsDownFilled : CsIcons.thumbsDown,
                  semanticLabel: 'Not helpful',
                  onPress: () => setState(() => _feedback = 'down'),
                ),
                CsButton(variant: CsButtonVariant.icon, icon: CsIcons.copy, semanticLabel: 'Copy', onPress: () {}),
              ],
            ),
      child: Text(m.text),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DemoColumn(
      children: [
        DemoSection(
          title: 'Conversation',
          caption: 'Consecutive messages hide the repeated avatar. Ask a follow-up to see a streaming response.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: CsSpace.m,
            children: [
              for (var i = 0; i < _messages.length; i++) _bubble(i),
              if (_generating)
                const CsChatBubble(
                  type: CsChatBubbleType.incoming,
                  ariaLabel: 'Generative AI assistant, generating a response',
                  showLoadingBar: true,
                  avatar: CsAvatar(
                    color: CsAvatarColor.genAi,
                    icon: CsIcons.genAi,
                    loading: true,
                    ariaLabel: 'Generative AI assistant, generating',
                  ),
                  child: Text('Generating a response'),
                ),
              Wrap(
                spacing: CsSpace.m,
                runSpacing: CsSpace.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  CsButton(text: 'Ask a follow-up', disabled: _generating, onPress: _ask),
                  CsCheckbox(
                    checked: _stretch,
                    label: 'Stretch incoming',
                    onChange: (v) => setState(() => _stretch = v),
                  ),
                ],
              ),
            ],
          ),
        ),
        const DemoSection(
          title: 'Aligned to the end',
          caption: 'align: end puts the bubble first and the avatar after it.',
          child: CsChatBubble(
            type: CsChatBubbleType.outgoing,
            align: CsChatBubbleAlign.end,
            ariaLabel: 'Sample user at 3:45pm',
            avatar: CsAvatar(ariaLabel: 'Account', initials: 'SU'),
            child: Text('Thanks, that is all for now.'),
          ),
        ),
      ],
    );
  }
}

class _LoadingBarDemo extends StatefulWidget {
  const _LoadingBarDemo();

  @override
  State<_LoadingBarDemo> createState() => _LoadingBarDemoState();
}

class _LoadingBarDemoState extends State<_LoadingBarDemo> {
  bool _running = true;

  @override
  Widget build(BuildContext context) {
    return DemoColumn(
      children: [
        DemoSection(
          title: 'Variants',
          caption: 'genAi spans the full width; genAiMasked fades out at both ends for rounded edges.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: CsSpace.m,
            children: [
              if (_running) ...[
                const CsLoadingBar(semanticLabel: 'Generating'),
                const CsLoadingBar(variant: CsLoadingBarVariant.genAiMasked),
              ] else
                const CsBox(color: CsBoxColor.textBodySecondary, text: 'Process finished. The bars are removed.'),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: CsButton(
                  text: _running ? 'Stop process' : 'Start process',
                  onPress: () => setState(() => _running = !_running),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SupportPromptDemo extends StatefulWidget {
  const _SupportPromptDemo();

  @override
  State<_SupportPromptDemo> createState() => _SupportPromptDemoState();
}

class _SupportPromptDemoState extends State<_SupportPromptDemo> {
  String? _sent;

  static const _prompts = [
    CsSupportPrompt(id: 'cost', text: 'Why did my bill go up this month?'),
    CsSupportPrompt(id: 'scale', text: 'How do I scale instance i-0abc123?'),
    CsSupportPrompt(id: 'logs', text: 'Summarize the error logs from the last hour'),
  ];

  static const _iconPrompts = [
    CsSupportPrompt(id: 'summarize', text: 'Summarize alarms', icon: CsIcons.genAi),
    CsSupportPrompt(id: 'explain', text: 'Explain this policy', icon: CsIcons.search),
    CsSupportPrompt(
      id: 'docs',
      text: 'Open the bucket guide',
      icon: CsIcons.external,
      iconPosition: CsSupportPromptIconPosition.right,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return DemoColumn(
      children: [
        DemoSection(
          title: 'Vertical',
          caption: 'One Tab stop; arrow keys move between prompts, Enter sends.',
          child: CsSupportPromptGroup(
            ariaLabel: 'Suggested prompts',
            items: _prompts,
            onItemClick: (id) => setState(() => _sent = id),
          ),
        ),
        DemoSection(
          title: 'Horizontal with icons',
          child: CsSupportPromptGroup(
            ariaLabel: 'Suggested actions',
            alignment: CsSupportPromptAlignment.horizontal,
            items: _iconPrompts,
            onItemClick: (id) => setState(() => _sent = id),
          ),
        ),
        CsBox(color: CsBoxColor.textBodySecondary, text: _sent == null ? 'No prompt sent yet.' : 'Sent prompt: $_sent'),
      ],
    );
  }
}

const _jsonSample = '''{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:GetObject"],
      "Resource": "arn:aws:s3:::example-bucket/*",
      "Condition": { "Bool": { "aws:SecureTransport": true } }
    }
  ]
}''';

const _samples = {
  'json': _jsonSample,
  'typescript': '''import { S3Client, ListObjectsCommand } from "@aws-sdk/client-s3";

const client = new S3Client({ region: "us-east-1" });
export async function count(bucket: string): Promise<number> {
  const result = await client.send(new ListObjectsCommand({ Bucket: bucket }));
  return result.Contents?.length ?? 0; // objects on the first page
}''',
  'python': '''import boto3

def handler(event, context):
    """Stop instance i-0abc123 outside business hours."""
    ec2 = boto3.client("ec2")
    ec2.stop_instances(InstanceIds=["i-0abc123"])
    return {"stopped": True, "count": 1}''',
  'yaml': '''Resources:
  ExampleBucket:
    Type: AWS::S3::Bucket
    Properties:
      BucketName: example-bucket
      VersioningConfiguration:
        Status: Enabled  # keep old versions''',
  'sh': '''#!/bin/bash
export REGION=us-east-1
aws s3 sync ./build "s3://example-bucket/releases/\$VERSION" --delete --exclude "*.map"
aws cloudfront create-invalidation --distribution-id d111111abcdef8 --paths "/*"''',
  'html': '''<!-- Status page -->
<section class="status" aria-label="Distribution status">
  <h2>d111111abcdef8</h2>
  <p>Deployed &amp; serving traffic</p>
</section>''',
};

class _CodeViewDemo extends StatefulWidget {
  const _CodeViewDemo();

  @override
  State<_CodeViewDemo> createState() => _CodeViewDemoState();
}

class _CodeViewDemoState extends State<_CodeViewDemo> {
  String _language = 'json';
  bool _lineNumbers = true;
  bool _wrap = false;

  @override
  Widget build(BuildContext context) {
    final content = _samples[_language]!;
    return DemoColumn(
      children: [
        DemoSection(
          title: 'Syntax highlighting',
          caption: 'Pick a language. Lines scroll sideways unless wrapping is on.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: CsSpace.s,
            children: [
              Wrap(
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
              Wrap(
                spacing: CsSpace.l,
                children: [
                  CsCheckbox(
                    checked: _lineNumbers,
                    label: 'Line numbers',
                    onChange: (v) => setState(() => _lineNumbers = v),
                  ),
                  CsCheckbox(checked: _wrap, label: 'Wrap lines', onChange: (v) => setState(() => _wrap = v)),
                ],
              ),
              CsCodeView(
                content: content,
                lineNumbers: _lineNumbers,
                wrapLines: _wrap,
                highlight: CsCodeViewHighlighter.of(_language),
                ariaLabel: '$_language sample',
                actions: CsCodeViewCopyButton(
                  content: content,
                  i18nStrings: const CsCodeViewCopyButtonI18nStrings(
                    copyButtonAriaLabel: 'Copy code',
                    copySuccessText: 'Code copied',
                  ),
                ),
              ),
            ],
          ),
        ),
        const DemoSection(
          title: 'Plain text',
          caption: 'Without highlight or actions.',
          child: CsCodeView(
            content: 'i-0abc123  running  t3.micro  us-east-1a\ni-0def456  stopped  t3.small  us-east-1b',
          ),
        ),
      ],
    );
  }
}
