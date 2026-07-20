import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import '../data/mock_brokers.dart';
import '../models/asset.dart';
import '../theme/landing_colors.dart';

/// Mock two-way chat between the current user and a broker, scoped to one
/// specific listing. No backend — the broker's replies are canned/simulated
/// so the flow feels alive for the demo.
///
/// TODO: replace with a real `ChatService` (e.g. Supabase Realtime channel
/// keyed by `${brokerId}_${assetId}`) once messaging is backed by the API.
class BrokerChatScreen extends StatefulWidget {
  final Broker broker;
  final Asset asset;

  const BrokerChatScreen({super.key, required this.broker, required this.asset});

  @override
  State<BrokerChatScreen> createState() => _BrokerChatScreenState();
}

class _ChatMessage {
  final String text;
  final bool fromMe;
  final DateTime time;
  _ChatMessage(this.text, this.fromMe, this.time);
}

class _BrokerChatScreenState extends State<BrokerChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _messages = <_ChatMessage>[];
  bool _brokerTyping = false;
  final _rand = Random();

  @override
  void initState() {
    super.initState();
    _messages.add(_ChatMessage(
      "Hi! Thanks for reaching out about \"${widget.asset.title}\". Happy to answer any questions.",
      false,
      DateTime.now().subtract(const Duration(minutes: 2)),
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  String _canned() {
    final options = [
      "Yes, it's still available — I can arrange a viewing whenever works for you.",
      "Good question — let me check the exact details and get back to you shortly.",
      "The price is negotiable for serious buyers. Would you like to schedule a call?",
      "I can send more photos and the full spec sheet if that helps.",
      "Sure, I'm usually around Addis Ababa — happy to meet near the listing.",
    ];
    return options[_rand.nextInt(options.length)];
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(_ChatMessage(text, true, DateTime.now()));
      _controller.clear();
      _brokerTyping = true;
    });
    _scrollToBottom();
    Timer(Duration(milliseconds: 900 + _rand.nextInt(700)), () {
      if (!mounted) return;
      setState(() {
        _brokerTyping = false;
        _messages.add(_ChatMessage(_canned(), false, DateTime.now()));
      });
      _scrollToBottom();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LandingColors.background,
      appBar: AppBar(
        backgroundColor: LandingColors.background,
        elevation: 0,
        foregroundColor: LandingColors.foreground,
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: LandingColors.gold,
              child: Text(widget.broker.initials,
                  style: const TextStyle(fontWeight: FontWeight.w700, color: LandingColors.goldFg, fontSize: 13)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(widget.broker.name,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: LandingColors.foreground),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text('About: ${widget.asset.title}',
                      style: const TextStyle(fontSize: 11.5, color: LandingColors.muted),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _ListingBanner(asset: widget.asset),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                itemCount: _messages.length + (_brokerTyping ? 1 : 0),
                itemBuilder: (context, i) {
                  if (i == _messages.length) {
                    return const _TypingBubble();
                  }
                  return _Bubble(message: _messages[i]);
                },
              ),
            ),
            _Composer(controller: _controller, onSend: _send),
          ],
        ),
      ),
    );
  }
}

class _ListingBanner extends StatelessWidget {
  final Asset asset;
  const _ListingBanner({required this.asset});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: LandingColors.card,
        border: Border.all(color: LandingColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 44,
              height: 44,
              child: asset.imageUrl != null
                  ? Image.network(asset.imageUrl!, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: LandingColors.border))
                  : Container(color: LandingColors.border),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(asset.title,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: LandingColors.foreground),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(asset.formattedPrice, style: const TextStyle(fontSize: 12, color: LandingColors.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final _ChatMessage message;
  const _Bubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final mine = message.fromMe;
    final bg = mine ? LandingColors.foreground : LandingColors.card;
    final fg = mine ? LandingColors.primaryFg : LandingColors.foreground;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        decoration: BoxDecoration(
          color: bg,
          border: mine ? null : Border.all(color: LandingColors.border),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(mine ? 16 : 4),
            bottomRight: Radius.circular(mine ? 4 : 16),
          ),
        ),
        child: Text(message.text, style: TextStyle(fontSize: 14, color: fg, height: 1.3)),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: LandingColors.card,
          border: Border.all(color: LandingColors.border),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
          ),
        ),
        child: const SizedBox(
          width: 28,
          child: Text('· · ·', style: TextStyle(color: LandingColors.muted, fontWeight: FontWeight.w900, letterSpacing: 2)),
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  const _Composer({required this.controller, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: InputDecoration(
                hintText: 'Message about this listing...',
                hintStyle: const TextStyle(color: LandingColors.muted),
                filled: true,
                fillColor: LandingColors.card,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(999), borderSide: const BorderSide(color: LandingColors.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(999), borderSide: const BorderSide(color: LandingColors.border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(999), borderSide: const BorderSide(color: LandingColors.gold, width: 1.5)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: LandingColors.foreground,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onSend,
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(Icons.arrow_upward_rounded, color: LandingColors.primaryFg, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
