import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quote_vault/data/models/quote.dart';

import 'package:quote_vault/data/services/share_service.dart';

class DailyQuoteCard extends StatefulWidget {
  final Quote quote;
  final VoidCallback onTap;

  const DailyQuoteCard({super.key, required this.quote, required this.onTap});

  @override
  State<DailyQuoteCard> createState() => _DailyQuoteCardState();
}

class _DailyQuoteCardState extends State<DailyQuoteCard> {
  final GlobalKey _globalKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: _globalKey,
      child: Card(
        margin: const EdgeInsets.all(16),
        elevation: 4,
        color: Theme.of(context).colorScheme.primaryContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.wb_sunny,
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Quote of the Day',
                          style: GoogleFonts.zillaSlab(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.share,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      onPressed: () {
                        // We shouldn't capture the button itself ideally, but for MVP it's fine.
                        // Or we can invoke external share service that takes a key.
                        // Since we are inside the widget, we can allow parent to handle or handle here.
                        // But ShareService needs the key.
                        ShareService.shareWidgetImage(_globalKey);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  widget.quote.content,
                  style: GoogleFonts.lato(
                    fontSize: 22,
                    fontStyle: FontStyle.italic,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    "- ${widget.quote.author}",
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(
                        context,
                      ).colorScheme.onPrimaryContainer.withOpacity(0.8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
