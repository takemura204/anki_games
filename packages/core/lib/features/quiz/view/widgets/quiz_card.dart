import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../i18n/translations.g.dart';
import '../../view_model/quiz_view_model.dart';
import 'direction_chip.dart';

/// SRS ステージに対応するアクセントカラーを返す。
Color quizStageColor(int stage) => switch (stage) {
      0 => Colors.grey,
      1 => Colors.red.shade400,
      2 => Colors.orange.shade400,
      3 => Colors.blue.shade400,
      _ => Colors.green.shade500,
    };

/// SRS ステージの日本語ラベルを返す。
String quizStageLabel(int stage) => switch (stage) {
      0 => t.quiz.masteryNew,
      1 => t.quiz.masteryHard,
      2 => t.quiz.masteryLearning,
      3 => t.quiz.masteryGood,
      _ => t.quiz.masteryPerfect,
    };

/// 品詞の日本語ラベルを返す。
String quizPosLabel(String pos) => switch (pos) {
      'noun' => '名詞',
      'verb' => '動詞',
      'adjective' => '形容詞',
      'adverb' => '副詞',
      'preposition' => '前置詞',
      'conjunction' => '接続詞',
      'phrase' => '慣用句',
      _ => pos,
    };

Color _stageColor(int stage) => quizStageColor(stage);
String _stageLabel(int stage) => quizStageLabel(stage);
String _posLabel(String pos) => quizPosLabel(pos);

/// スワイプ式・letterTap式・タイピング式のクイズカード本体。
///
/// [QuizQuestion.format] に応じて表示形式を切り替える。
class QuizCard extends StatelessWidget {
  /// [QuizCard] を作成する。
  const QuizCard({
    required this.question,
    required this.activeDirection,
    this.onSpeak,
    this.onTypingSubmit,
    this.onLetterTapSubmit,
    this.typingFocusNode,
    super.key,
  });

  /// 表示する問題データ。
  final QuizQuestion question;

  /// スワイプ中のアクティブ方向（null なら非選択）。タイピング形式では無視。
  final SwipeDirection? activeDirection;

  /// スピーカーアイコンタップ時のコールバック。null の場合はアイコン非表示。
  final VoidCallback? onSpeak;

  /// タイピング形式での回答送信コールバック。
  final void Function(String answer)? onTypingSubmit;

  /// letterTap 形式での回答完了コールバック。
  final void Function({required bool isCorrect})? onLetterTapSubmit;

  /// タイピング用 FocusNode（外部から渡すことでカード切替時にフォーカス制御可能）。
  final FocusNode? typingFocusNode;

  @override
  Widget build(BuildContext context) {
    if (question.format == QuizFormat.jaToEnTyping) {
      return _TypingCard(
        question: question,
        onSpeak: onSpeak,
        onSubmit: onTypingSubmit,
        focusNode: typingFocusNode,
      );
    }
    if (question.format == QuizFormat.letterTap) {
      return _LetterTapCard(
        question: question,
        onSpeak: onSpeak,
        onSubmit: onLetterTapSubmit,
      );
    }
    return _ChoiceCard(
      question: question,
      activeDirection: activeDirection,
      onSpeak: onSpeak,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 4択スワイプカード
// ─────────────────────────────────────────────────────────────────────────────

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.question,
    required this.activeDirection,
    this.onSpeak,
  });

  final QuizQuestion question;
  final SwipeDirection? activeDirection;
  final VoidCallback? onSpeak;

  static const double _sideChipMaxWidth = 76;
  static const double _questionPadding = _sideChipMaxWidth + 4;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;

    final upChoice = _choiceFor(SwipeDirection.up);
    final downChoice = _choiceFor(SwipeDirection.down);
    final leftChoice = _choiceFor(SwipeDirection.left);
    final rightChoice = _choiceFor(SwipeDirection.right);

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = min(constraints.maxWidth, constraints.maxHeight);
        return Center(
          child: SizedBox.square(
            dimension: size,
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: isDark ? 0.4 : 0.12,
                    ),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: DirectionChip(
                          text: upChoice?.text ?? '',
                          direction: SwipeDirection.up,
                          isHighlighted: activeDirection == SwipeDirection.up,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: _questionPadding,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _PosLabel(pos: question.word.pos),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: AutoSizeText(
                                question.displayText,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                  height: 1.2,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                minFontSize: 10,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _StageBadge(stage: question.stage),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: DirectionChip(
                          text: downChoice?.text ?? '',
                          direction: SwipeDirection.down,
                          isHighlighted: activeDirection == SwipeDirection.down,
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    left: 8,
                    top: 0,
                    bottom: 0,
                    child: Align(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: _sideChipMaxWidth,
                        ),
                        child: DirectionChip(
                          text: leftChoice?.text ?? '',
                          direction: SwipeDirection.left,
                          isHighlighted: activeDirection == SwipeDirection.left,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 8,
                    top: 0,
                    bottom: 0,
                    child: Align(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: _sideChipMaxWidth,
                        ),
                        child: DirectionChip(
                          text: rightChoice?.text ?? '',
                          direction: SwipeDirection.right,
                          isHighlighted:
                              activeDirection == SwipeDirection.right,
                        ),
                      ),
                    ),
                  ),
                  if (onSpeak != null)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: GestureDetector(
                        onTap: onSpeak,
                        child: Icon(
                          Icons.volume_up_rounded,
                          size: 18,
                          color: textColor.withValues(alpha: 0.35),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  QuizChoice? _choiceFor(SwipeDirection dir) {
    final matches = question.choices.where((c) => c.direction == dir);
    return matches.isEmpty ? null : matches.first;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// タイピングカード（インライン TextField）
// ─────────────────────────────────────────────────────────────────────────────

class _TypingCard extends StatefulWidget {
  const _TypingCard({
    required this.question,
    this.onSpeak,
    this.onSubmit,
    this.focusNode,
  });

  final QuizQuestion question;
  final VoidCallback? onSpeak;
  final void Function(String)? onSubmit;
  final FocusNode? focusNode;

  @override
  State<_TypingCard> createState() => _TypingCardState();
}

class _TypingCardState extends State<_TypingCard> {
  final _controller = TextEditingController();

  @override
  void didUpdateWidget(_TypingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.question != widget.question) {
      _controller.clear();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      return;
    }
    widget.onSubmit?.call(text);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final subColor = textColor.withValues(alpha: 0.45);

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = min(constraints.maxWidth, constraints.maxHeight);
        return Center(
          child: SizedBox.square(
            dimension: size,
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: isDark ? 0.4 : 0.12,
                    ),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _PosLabel(pos: widget.question.word.pos),
                        const SizedBox(height: 12),
                        AutoSizeText(
                          widget.question.displayText,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                            height: 1.2,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          minFontSize: 10,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        _StageBadge(stage: widget.question.stage),
                        const SizedBox(height: 24),
                        TextField(
                          controller: _controller,
                          focusNode: widget.focusNode,
                          keyboardType: TextInputType.visiblePassword,
                          autocorrect: false,
                          enableSuggestions: false,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 18,
                            color: textColor,
                          ),
                          decoration: InputDecoration(
                            hintText: t.quiz.typeAnswerHint,
                            hintStyle: TextStyle(
                              fontFamily: 'Poppins',
                              color: subColor,
                            ),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: subColor),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: textColor,
                                width: 2,
                              ),
                            ),
                          ),
                          onSubmitted: (_) => _submit(),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: _submit,
                            style: TextButton.styleFrom(
                              backgroundColor:
                                  textColor.withValues(alpha: 0.08),
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              t.quiz.submitAnswer,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.onSpeak != null)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: GestureDetector(
                        onTap: widget.onSpeak,
                        child: Icon(
                          Icons.volume_up_rounded,
                          size: 18,
                          color: textColor.withValues(alpha: 0.35),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// letterTap カード（スペルタップ入力）
// ─────────────────────────────────────────────────────────────────────────────

class _LetterTapCard extends StatefulWidget {
  const _LetterTapCard({
    required this.question,
    this.onSpeak,
    this.onSubmit,
  });

  final QuizQuestion question;
  final VoidCallback? onSpeak;
  final void Function({required bool isCorrect})? onSubmit;

  @override
  State<_LetterTapCard> createState() => _LetterTapCardState();
}

class _LetterTapCardState extends State<_LetterTapCard> {
  var _currentSlot = 0;
  final _filledLetters = <String>[];

  /// 初回誤タップが発生したスロットのインデックス集合。
  final _errorSlots = <int>{};

  /// 現在のスロットで既にタップ済みか（最初のタップが正解かを判定するため）。
  var _firstTapDone = false;

  /// アニメーション用: 直近タップした文字（null = アニメなし）。
  String? _flashLetter;
  var _flashCorrect = false;
  var _completed = false;

  String get _targetWord => widget.question.word.en.toUpperCase();

  void _onTap(String letter) {
    if (_completed || _currentSlot >= _targetWord.length) {
      return;
    }
    final correctLetter = _targetWord[_currentSlot];
    final isCorrect = letter == correctLetter;

    // 初回タップが誤りならエラー記録
    if (!isCorrect && !_firstTapDone) {
      _errorSlots.add(_currentSlot);
    }
    _firstTapDone = true;

    setState(() {
      _flashLetter = letter;
      _flashCorrect = isCorrect;
    });

    if (isCorrect) {
      HapticFeedback.lightImpact();
      Future<void>.delayed(const Duration(milliseconds: 120), () {
        if (!mounted) {
          return;
        }
        setState(() {
          _filledLetters.add(correctLetter);
          _currentSlot++;
          _firstTapDone = false;
          _flashLetter = null;
        });
        if (_currentSlot >= _targetWord.length) {
          setState(() => _completed = true);
          Future<void>.delayed(const Duration(milliseconds: 300), () {
            widget.onSubmit?.call(isCorrect: _errorSlots.isEmpty);
          });
        }
      });
    } else {
      HapticFeedback.mediumImpact();
      Future<void>.delayed(const Duration(milliseconds: 250), () {
        if (mounted) {
          setState(() => _flashLetter = null);
        }
      });
    }
  }

  @override
  void didUpdateWidget(_LetterTapCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.question != widget.question) {
      _currentSlot = 0;
      _filledLetters.clear();
      _errorSlots.clear();
      _firstTapDone = false;
      _flashLetter = null;
      _completed = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final wordLen = _targetWord.length;
    final currentSlots = widget.question.letterSlots;

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = min(constraints.maxWidth, constraints.maxHeight);
        return Center(
          child: SizedBox.square(
            dimension: size,
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: isDark ? 0.4 : 0.12,
                    ),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _PosLabel(pos: widget.question.word.pos),
                        const SizedBox(height: 12),
                        // 日本語意味
                        AutoSizeText(
                          widget.question.displayText,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                            height: 1.2,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          minFontSize:
                              12, // ignore: avoid_redundant_argument_values
                        ),
                        const SizedBox(height: 12),
                        _StageBadge(stage: widget.question.stage),
                        const SizedBox(height: 20),
                        // スペル入力ボックス列
                        _LetterBoxRow(
                          wordLen: wordLen,
                          filledLetters: _filledLetters,
                          currentSlot: _currentSlot,
                          textColor: textColor,
                        ),
                        const SizedBox(height: 20),
                        // 現在スロットの選択肢ボタン
                        if (_currentSlot < currentSlots.length && !_completed)
                          _LetterChoiceRow(
                            choices: currentSlots[_currentSlot],
                            flashLetter: _flashLetter,
                            flashCorrect: _flashCorrect,
                            textColor: textColor,
                            onTap: _onTap,
                          ),
                        if (_completed)
                          Icon(
                            Icons.check_circle_rounded,
                            color: Colors.green.shade400,
                            size: 40,
                          ),
                      ],
                    ),
                  ),
                  if (widget.onSpeak != null)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: GestureDetector(
                        onTap: widget.onSpeak,
                        child: Icon(
                          Icons.volume_up_rounded,
                          size: 18,
                          color: textColor.withValues(alpha: 0.35),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// スペル入力中の文字ボックス列。
class _LetterBoxRow extends StatelessWidget {
  const _LetterBoxRow({
    required this.wordLen,
    required this.filledLetters,
    required this.currentSlot,
    required this.textColor,
  });

  final int wordLen;
  final List<String> filledLetters;
  final int currentSlot;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final boxSize = min(
      36,
      ((MediaQuery.of(context).size.width - 80) / wordLen).toInt(),
    ).toDouble();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < wordLen; i++) ...[
          _LetterBox(
            letter: i < filledLetters.length ? filledLetters[i] : null,
            isActive: i == currentSlot,
            boxSize: boxSize,
            textColor: textColor,
          ),
          if (i < wordLen - 1) SizedBox(width: boxSize * 0.12),
        ],
      ],
    );
  }
}

class _LetterBox extends StatelessWidget {
  const _LetterBox({
    required this.letter,
    required this.isActive,
    required this.boxSize,
    required this.textColor,
  });

  final String? letter;
  final bool isActive;
  final double boxSize;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final filled = letter != null;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: boxSize,
      height: boxSize,
      decoration: BoxDecoration(
        color: filled
            ? Colors.green.shade400.withValues(alpha: 0.15)
            : isActive
                ? textColor.withValues(alpha: 0.08)
                : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: filled
              ? Colors.green.shade400
              : isActive
                  ? textColor.withValues(alpha: 0.6)
                  : textColor.withValues(alpha: 0.25),
          width: isActive ? 2 : 1.5,
        ),
      ),
      child: Center(
        child: Text(
          letter ?? '',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: boxSize * 0.52,
            fontWeight: FontWeight.w700,
            color: filled ? Colors.green.shade600 : textColor,
          ),
        ),
      ),
    );
  }
}

/// 各スロットの 4択文字ボタン行。
class _LetterChoiceRow extends StatelessWidget {
  const _LetterChoiceRow({
    required this.choices,
    required this.flashLetter,
    required this.flashCorrect,
    required this.textColor,
    required this.onTap,
  });

  final List<String> choices;
  final String? flashLetter;
  final bool flashCorrect;
  final Color textColor;
  final void Function(String) onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final letter in choices) ...[
          _LetterButton(
            letter: letter,
            isFlashing: flashLetter == letter,
            flashCorrect: flashCorrect,
            textColor: textColor,
            onTap: () => onTap(letter),
          ),
          if (letter != choices.last) const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class _LetterButton extends StatelessWidget {
  const _LetterButton({
    required this.letter,
    required this.isFlashing,
    required this.flashCorrect,
    required this.textColor,
    required this.onTap,
  });

  final String letter;
  final bool isFlashing;
  final bool flashCorrect;
  final Color textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color borderColor;
    if (isFlashing) {
      bgColor = (flashCorrect ? Colors.green.shade400 : Colors.red.shade400)
          .withValues(alpha: 0.25);
      borderColor = flashCorrect ? Colors.green.shade400 : Colors.red.shade400;
    } else {
      bgColor = textColor.withValues(alpha: 0.06);
      borderColor = textColor.withValues(alpha: 0.2);
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: 62,
        height: 54,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Center(
          child: Text(
            letter,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: isFlashing
                  ? (flashCorrect ? Colors.green.shade600 : Colors.red.shade500)
                  : textColor,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ステージバッジ
// ─────────────────────────────────────────────────────────────────────────────

class _StageBadge extends StatelessWidget {
  const _StageBadge({required this.stage});

  final int stage;

  @override
  Widget build(BuildContext context) {
    final color = _stageColor(stage);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _stageLabel(stage),
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 品詞ラベル
// ─────────────────────────────────────────────────────────────────────────────

class _PosLabel extends StatelessWidget {
  const _PosLabel({required this.pos});

  final String pos;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey, width: 0.5),
      ),
      child: Text(
        _posLabel(pos),
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.grey,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// インライン入力ウィジェット（ブロックパズル用、カードシェルなし）
// ─────────────────────────────────────────────────────────────────────────────

/// カードシェルなしの letterTap 入力ウィジェット（ブロックパズルインライン用）。
class LetterTapInputBody extends StatefulWidget {
  /// [LetterTapInputBody] を作成する。
  const LetterTapInputBody({
    required this.question,
    required this.onComplete,
    super.key,
  });

  /// 出題データ。
  final QuizQuestion question;

  /// 入力完了時に呼ばれるコールバック。
  final void Function({required bool isCorrect}) onComplete;

  @override
  State<LetterTapInputBody> createState() => _LetterTapInputBodyState();
}

class _LetterTapInputBodyState extends State<LetterTapInputBody> {
  var _currentSlot = 0;
  final _filledLetters = <String>[];
  final _errorSlots = <int>{};
  var _firstTapDone = false;
  String? _flashLetter;
  var _flashCorrect = false;
  var _completed = false;

  String get _targetWord => widget.question.word.en.toUpperCase();

  void _onTap(String letter) {
    if (_completed || _currentSlot >= _targetWord.length) {
      return;
    }
    final correctLetter = _targetWord[_currentSlot];
    final isCorrect = letter == correctLetter;
    if (!isCorrect && !_firstTapDone) {
      _errorSlots.add(_currentSlot);
    }
    _firstTapDone = true;
    setState(() {
      _flashLetter = letter;
      _flashCorrect = isCorrect;
    });
    if (isCorrect) {
      HapticFeedback.lightImpact();
      Future<void>.delayed(const Duration(milliseconds: 120), () {
        if (!mounted) {
          return;
        }
        setState(() {
          _filledLetters.add(correctLetter);
          _currentSlot++;
          _firstTapDone = false;
          _flashLetter = null;
        });
        if (_currentSlot >= _targetWord.length) {
          setState(() => _completed = true);
          Future<void>.delayed(const Duration(milliseconds: 300), () {
            widget.onComplete(isCorrect: _errorSlots.isEmpty);
          });
        }
      });
    } else {
      HapticFeedback.mediumImpact();
      Future<void>.delayed(const Duration(milliseconds: 250), () {
        if (mounted) {
          setState(() => _flashLetter = null);
        }
      });
    }
  }

  @override
  void didUpdateWidget(LetterTapInputBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.question != widget.question) {
      _currentSlot = 0;
      _filledLetters.clear();
      _errorSlots.clear();
      _firstTapDone = false;
      _flashLetter = null;
      _completed = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final wordLen = _targetWord.length;
    final currentSlots = widget.question.letterSlots;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _LetterBoxRow(
          wordLen: wordLen,
          filledLetters: _filledLetters,
          currentSlot: _currentSlot,
          textColor: textColor,
        ),
        const SizedBox(height: 12),
        if (_currentSlot < currentSlots.length && !_completed)
          _LetterChoiceRow(
            choices: currentSlots[_currentSlot],
            flashLetter: _flashLetter,
            flashCorrect: _flashCorrect,
            textColor: textColor,
            onTap: _onTap,
          ),
        if (_completed)
          Icon(
            Icons.check_circle_rounded,
            color: Colors.green.shade400,
            size: 32,
          ),
      ],
    );
  }
}

/// カードシェルなしのタイピング入力ウィジェット（ブロックパズルインライン用）。
class TypingInputBody extends StatefulWidget {
  /// [TypingInputBody] を作成する。
  const TypingInputBody({
    required this.question,
    required this.onComplete,
    this.focusNode,
    super.key,
  });

  /// 出題データ。
  final QuizQuestion question;

  /// 回答送信時に呼ばれるコールバック（引数は入力テキスト）。
  final void Function(String text) onComplete;

  /// 外部から渡す FocusNode（省略可）。
  final FocusNode? focusNode;

  @override
  State<TypingInputBody> createState() => _TypingInputBodyState();
}

class _TypingInputBodyState extends State<TypingInputBody> {
  final _controller = TextEditingController();

  @override
  void didUpdateWidget(TypingInputBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.question != widget.question) {
      _controller.clear();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      return;
    }
    widget.onComplete(text);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final subColor = textColor.withValues(alpha: 0.45);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _controller,
          focusNode: widget.focusNode,
          keyboardType: TextInputType.visiblePassword,
          autocorrect: false,
          enableSuggestions: false,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            color: textColor,
          ),
          decoration: InputDecoration(
            hintText: t.quiz.typeAnswerHint,
            hintStyle: TextStyle(fontFamily: 'Poppins', color: subColor),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: subColor),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: textColor, width: 2),
            ),
          ),
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: _submit,
            style: TextButton.styleFrom(
              backgroundColor: textColor.withValues(alpha: 0.08),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              t.quiz.submitAnswer,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
