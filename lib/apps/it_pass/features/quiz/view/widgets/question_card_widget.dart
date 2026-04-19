part of '../quiz_screen.dart';

class _QuestionCardWidget extends StatelessWidget {
  const _QuestionCardWidget({required this.question});

  final Question question;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (question.categoryRaw.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    question.categoryRaw,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 10,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              const SizedBox(height: 12),
              Text(
                'Q${question.no}. ${question.title}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                question.body.text,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
              if (question.body.subItems.isNotEmpty) ...[
                const SizedBox(height: 10),
                ...question.body.subItems.asMap().entries.map(
                      (e) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${String.fromCharCode(97 + e.key)}. ',
                              style: const TextStyle(
                                color: Color(0xFF7C3AED),
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                e.value,
                                style: const TextStyle(
                                  color: Colors.white60,
                                  fontSize: 13,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
              ],
              if (question.body.images.isNotEmpty) ...[
                const SizedBox(height: 12),
                ...question.body.images.map(
                  (url) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _QuizNetworkImage(url: url),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
