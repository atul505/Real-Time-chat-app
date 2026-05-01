import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// WhatsApp/Telegram-style chat bubble with timestamp, status icon, and long-press copy
class ChatBubble extends StatelessWidget {
  final String text;
  final String time;
  final bool isMe;
  final bool showTail;

  const ChatBubble({
    super.key,
    required this.text,
    required this.time,
    required this.isMe,
    this.showTail = true,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () {
          Clipboard.setData(ClipboardData(text: text));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Message copied', style: GoogleFonts.inter()),
              backgroundColor: AppTheme.card,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              duration: const Duration(seconds: 1),
            ),
          );
        },
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          margin: EdgeInsets.only(
            top: 2,
            bottom: 2,
            left: isMe ? 60 : 0,
            right: isMe ? 0 : 60,
          ),
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
          decoration: BoxDecoration(
            color: isMe ? AppTheme.sentBubble : AppTheme.receivedBubble,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isMe ? 16 : (showTail ? 4 : 16)),
              bottomRight: Radius.circular(isMe ? (showTail ? 4 : 16) : 16),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Message text
              Text(
                text,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 15,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 3),
              // Time + status row
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    time,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: isMe
                          ? Colors.white.withAlpha(140)
                          : AppTheme.textMuted,
                    ),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 3),
                    Icon(
                      Icons.done_all,
                      size: 14,
                      color: AppTheme.accent.withAlpha(180),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
