import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';
import '../pages/image_viewer_page.dart';

class ChatBubble extends StatelessWidget {
  final String text;
  final String time;
  final bool isMe;
  final bool showTail;
  final String? attachmentUrl;
  final String? attachmentType;
  final String? attachmentName;

  const ChatBubble({
    super.key,
    required this.text,
    required this.time,
    required this.isMe,
    this.showTail = true,
    this.attachmentUrl,
    this.attachmentType,
    this.attachmentName,
  });

  @override
  Widget build(BuildContext context) {
    bool hasAttachment = attachmentUrl != null && attachmentUrl!.isNotEmpty;
    bool isImage = attachmentType == 'image';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () {
          if (text.isNotEmpty) {
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
          }
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
              if (hasAttachment)
                if (isImage)
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ImageViewerPage(
                            imageUrl: attachmentUrl!,
                            heroTag: attachmentUrl!,
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Hero(
                          tag: attachmentUrl!,
                          child: CachedNetworkImage(
                            imageUrl: attachmentUrl!,
                            width: 200,
                            height: 200,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              width: 200, height: 200, color: Colors.grey[800],
                              child: const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
                            ),
                            errorWidget: (context, url, error) => Container(
                              width: 200, height: 200, color: Colors.grey[800],
                              child: const Icon(Icons.error, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    margin: const EdgeInsets.only(bottom: 8.0),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(50),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.insert_drive_file, color: Colors.white, size: 24),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            attachmentName ?? 'File',
                            style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

              if (text.isNotEmpty)
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
