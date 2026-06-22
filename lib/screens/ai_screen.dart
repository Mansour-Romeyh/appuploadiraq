import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../i18n/strings.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';

class _Message {
  final String id;
  final bool isUser;
  String content;
  final String? imagePath;
  final String? imageBase64;
  final String? mimeType;

  _Message({
    required this.id,
    required this.isUser,
    required this.content,
    this.imagePath,
    this.imageBase64,
    this.mimeType,
  });
}

/// AI legal advisor chat tab (ported from app/(tabs)/ai.tsx).
class AiScreen extends StatefulWidget {
  const AiScreen({super.key});

  @override
  State<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends State<AiScreen> {
  // The welcome bubble's text is resolved at render time (see _buildMessage),
  // not captured here — otherwise it would stay frozen in whatever language the
  // chat was first opened in after the user switches languages.
  final List<_Message> _messages = [
    _Message(id: 'welcome', isUser: false, content: ''),
  ];
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  bool _loading = false;
  XFile? _pickedImage;
  String? _pickedImageBase64;
  String? _pickedImageMime;
  int _nextId = 0;

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  /// Derive a MIME type from a file path's extension so the backend can decode
  /// the attached image. Defaults to image/jpeg.
  String _mimeFromPath(String path) {
    final ext = path.split('.').last.toLowerCase();
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      case 'heic':
        return 'image/heic';
      case 'jpg':
      case 'jpeg':
      default:
        return 'image/jpeg';
    }
  }

  Future<void> _pickImage() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (image == null) return;
    // Read the picked image as base64 so it is actually sent to the backend
    // for analysis (not just shown locally).
    final bytes = await image.readAsBytes();
    if (!mounted) return;
    setState(() {
      _pickedImage = image;
      _pickedImageBase64 = base64Encode(bytes);
      _pickedImageMime = _mimeFromPath(image.path);
    });
    HapticFeedback.lightImpact();
  }

  void _clearPickedImage() {
    setState(() {
      _pickedImage = null;
      _pickedImageBase64 = null;
      _pickedImageMime = null;
    });
  }

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if ((text.isEmpty && _pickedImage == null) || _loading) return;

    HapticFeedback.lightImpact();
    final image = _pickedImage;
    final imageBase64 = _pickedImageBase64;
    final imageMime = _pickedImageMime;
    _inputController.clear();

    final userMessage = _Message(
      id: 'u${_nextId++}',
      isUser: true,
      content: text.isEmpty ? t('ai.imageSentCaption') : text,
      imagePath: image?.path,
      imageBase64: imageBase64,
      mimeType: imageMime,
    );
    final placeholder = _Message(
      id: 'a${_nextId++}',
      isUser: false,
      content: '',
    );

    setState(() {
      _pickedImage = null;
      _pickedImageBase64 = null;
      _pickedImageMime = null;
      _messages.add(userMessage);
      _loading = true;
      _messages.add(placeholder);
    });
    _scrollToBottom();

    // Build the conversation history sent to the backend: every message
    // EXCEPT the initial welcome bubble and the empty assistant placeholder.
    final history = _messages
        .where((m) => m.id != 'welcome' && !identical(m, placeholder))
        .map(
          (m) => AiMessage(
            role: m.isUser ? 'user' : 'assistant',
            content: m.content,
            imageBase64: m.imageBase64,
            mimeType: m.imageBase64 != null ? m.mimeType : null,
          ),
        )
        .toList();

    String replyText;
    try {
      final res = await ApiService.instance.aiChat(history);
      if (res.error == 'not_configured') {
        replyText = t('ai.errorNotConfigured');
      } else {
        replyText = res.reply ?? t('ai.errorNetwork');
      }
    } catch (_) {
      replyText = t('ai.errorNetwork');
    }

    if (!mounted) return;
    setState(() {
      placeholder.content = replyText;
      _loading = false;
    });
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final canSend =
        (_inputController.text.trim().isNotEmpty || _pickedImage != null) &&
        !_loading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Container(
          padding: EdgeInsets.only(
            top: topPadding + 12,
            left: 20,
            right: 20,
            bottom: 14,
          ),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0x14FFFFFF))),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t('ai.headerTitle'),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    t('ai.headerSub'),
                    style: const TextStyle(fontSize: 12, color: AppColors.gold),
                  ),
                ],
              ),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _loading ? AppColors.gold : const Color(0xFF4ADE80),
                ),
              ),
            ],
          ),
        ),

        // Messages
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            itemCount: _messages.length,
            itemBuilder: (context, index) => _buildMessage(_messages[index]),
          ),
        ),

        // Image preview strip
        if (_pickedImage != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0x14FFFFFF))),
            ),
            child: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: _buildLocalImage(_pickedImage!.path, 56, 56),
                    ),
                    PositionedDirectional(
                      top: -6,
                      end: -6,
                      child: GestureDetector(
                        onTap: _clearPickedImage,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE53E3E),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                Text(
                  t('ai.imageAttached'),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0x80FFFFFF),
                  ),
                ),
              ],
            ),
          ),

        // Input row
        Container(
          padding: EdgeInsets.only(
            left: 12,
            right: 12,
            top: 10,
            bottom: MediaQuery.of(context).padding.bottom + 86,
          ),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Color(0x1AFFFFFF))),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: _loading ? null : _pickImage,
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      width: 1.5,
                      color: _pickedImage != null
                          ? AppColors.gold
                          : const Color(0x26FFFFFF),
                    ),
                  ),
                  child: Icon(
                    Icons.image_outlined,
                    size: 18,
                    color: _pickedImage != null
                        ? AppColors.gold
                        : const Color(0x73FFFFFF),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 100),
                  child: TextField(
                    controller: _inputController,
                    enabled: !_loading,
                    maxLines: null,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(fontSize: 14, color: Colors.white),
                    decoration: InputDecoration(
                      hintText: t('ai.inputPlaceholder'),
                      hintStyle: const TextStyle(color: Color(0x59FFFFFF)),
                      filled: true,
                      fillColor: const Color(0x14FFFFFF),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: Color(0x1FFFFFFF)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: AppColors.gold),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: Color(0x1FFFFFFF)),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: t('ai.sendButton'),
                child: GestureDetector(
                  onTap: canSend ? _sendMessage : null,
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: canSend ? AppColors.gold : const Color(0x1AFFFFFF),
                    ),
                    child: _loading
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            Icons.send,
                            size: 18,
                            textDirection: TextDirection.ltr,
                            color: canSend
                                ? const Color(0xFF0D0D0D)
                                : const Color(0x66FFFFFF),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocalImage(String path, double width, double height) {
    if (kIsWeb) {
      return Image.network(
        path,
        width: width,
        height: height,
        fit: BoxFit.cover,
      );
    }
    return Image.file(
      File(path),
      width: width,
      height: height,
      fit: BoxFit.cover,
    );
  }

  Widget _buildMessage(_Message message) {
    final isUser = message.isUser;
    // The welcome bubble is the one message whose text must follow the live
    // language; every other message carries its own immutable content.
    final content =
        message.id == 'welcome' ? t('ai.welcomeMessage') : message.content;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.gold.withAlpha(0x22),
                border: Border.all(color: AppColors.gold.withAlpha(0x44)),
              ),
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/law-logo.jpg',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.78,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? AppColors.gold : const Color(0x12FFFFFF),
                border: isUser
                    ? null
                    : Border.all(color: const Color(0x1AFFFFFF)),
                borderRadius: BorderRadiusDirectional.only(
                  topStart: const Radius.circular(16),
                  topEnd: const Radius.circular(16),
                  bottomStart: Radius.circular(isUser ? 16 : 4),
                  bottomEnd: Radius.circular(isUser ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (message.imagePath != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: _buildLocalImage(message.imagePath!, 200, 140),
                    ),
                    const SizedBox(height: 6),
                  ],
                  if (content.isEmpty && !isUser)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.gold,
                      ),
                    )
                  else if (content.isNotEmpty)
                    Text(
                      content,
                      style: TextStyle(
                        fontSize: 14,
                        height: 22 / 14,
                        fontWeight: isUser ? FontWeight.w500 : FontWeight.w400,
                        color: isUser ? const Color(0xFF0D0D0D) : Colors.white,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
