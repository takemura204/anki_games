part of '../quiz_screen.dart';

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({required this.question});

  final Question question;

  @override
  Widget build(BuildContext context) {
    const radius = 20.0;
    final cardRadius = BorderRadius.circular(radius);
    final hasImages = question.body.images.isNotEmpty;

    return ClipRRect(
      borderRadius: cardRadius,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: cardRadius,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.15),
          ),
          color: Colors.white.withValues(alpha: 0.08),
        ),
        child: ClipRRect(
          borderRadius: hasImages
              ? const BorderRadius.vertical(top: Radius.circular(radius))
              : cardRadius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                hasImages ? 12 : 20,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: hasImages
                    ? const BorderRadius.vertical(
                        top: Radius.circular(radius),
                      )
                    : cardRadius,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (question.categoryRaw.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        question.major.isNotEmpty
                            ? '${question.system} » ${question.major}'
                            : question.system,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  const Gap(8),
                  Text(
                    question.body.text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),
                  if (question.body.subItems.isNotEmpty) ...[
                    const Gap(10),
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
                  if (hasImages) ...[
                    const Gap(15),
                    ...question.body.images.asMap().entries.map(
                      (e) => _QuizNetworkImage(
                        url: e.value,
                        heroTag: 'img_q${question.no}_body_${e.key}',
                      ),
                    ),
                  ],
                  if (question.examDisplayName.isNotEmpty) ...[
                    const Gap(12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${question.examDisplayName} 問${question.no}',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
