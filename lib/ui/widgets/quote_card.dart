import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quote_vault/data/models/quote.dart';

class QuoteCard extends StatelessWidget {
  final Quote quote;
  final VoidCallback? onFavorite;
  final VoidCallback? onShare;
  final VoidCallback? onAddToCollection;

  final VoidCallback? onAuthorTap;
  final VoidCallback? onTap;

  const QuoteCard({
    super.key,
    required this.quote,
    this.onFavorite,
    this.onShare,
    this.onAddToCollection,
    this.onAuthorTap,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.format_quote_rounded,
                color: Theme.of(context).colorScheme.tertiary,
              ),
              const SizedBox(height: 8),
              Text(
                quote.content,
                style: GoogleFonts.merriweather(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: onAuthorTap,
                      child: Text(
                        "- ${quote.author}",
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          decoration: onAuthorTap != null
                              ? TextDecoration.underline
                              : null,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      quote.isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: quote.isFavorite ? Colors.red : null,
                    ),
                    onPressed: onFavorite,
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    icon: const Icon(Icons.bookmark_border),
                    onPressed: onAddToCollection,
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    icon: const Icon(Icons.share_outlined),
                    onPressed: onShare,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
